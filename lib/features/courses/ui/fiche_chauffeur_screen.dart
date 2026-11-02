import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../services/storage_service.dart';
import '../data/course_repository.dart';

class FicheChauffeurScreen extends StatefulWidget {
  const FicheChauffeurScreen({super.key, this.premiereFois = false});

  final bool premiereFois;

  @override
  State<FicheChauffeurScreen> createState() => _FicheChauffeurScreenState();
}

class _FicheChauffeurScreenState extends State<FicheChauffeurScreen> {
  static const _depot = CourseRepository();

  static const _permisDisponibles = <({String code, String libelle})>[
    (code: 'A', libelle: 'Moto (A)'),
    (code: 'B', libelle: 'Voiture (B)'),
    (code: 'C', libelle: 'Camion (C)'),
    (code: 'D', libelle: 'Bus (D)'),
    (code: 'E', libelle: 'Remorque (E)'),
  ];

  static const _vehicules = <({String code, String libelle, IconData icone})>[
    (code: 'taxi', libelle: 'Taxi', icone: Icons.local_taxi_rounded),
    (code: 'voiture', libelle: 'Voiture', icone: Icons.directions_car_rounded),
    (code: 'utilitaire', libelle: 'Utilitaire', icone: Icons.airport_shuttle_rounded),
    (code: 'camion', libelle: 'Camion', icone: Icons.local_shipping_rounded),
    (code: 'bus', libelle: 'Bus', icone: Icons.directions_bus_rounded),
    (code: 'moto', libelle: 'Moto', icone: Icons.two_wheeler_rounded),
  ];

  final _cleFormulaire = GlobalKey<FormState>();
  final _plaque = TextEditingController();
  final _permisNumero = TextEditingController();

  final Set<String> _permisChoisis = {};
  String _vehicule = 'taxi';
  bool _estClimatise = false;

  String? _photoRecto; // 👈 AJOUT
  String? _photoVerso; // 👈 AJOUT

  bool _envoi = false;
  bool _envoiPhoto = false;

  @override
  void initState() {
    super.initState();
    _permisChoisis.add('B');
  }

  @override
  void dispose() {
    _plaque.dispose();
    _permisNumero.dispose();
    super.dispose();
  }

  // 👇 LOGIQUE DE CAPTURE SEQUENTIELLE (Copiée de l'artisan) 👇
  Future<void> _gererCapturePiece() async {
    if (_photoRecto == null) {
      // Étape 1 : Demander le Recto
      final succes = await _demanderPhoto(cible: 'recto');
      if (succes && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recto enregistré. Prenez maintenant la face arrière (Verso).'),
            backgroundColor: MabokoCouleurs.succes,
            duration: Duration(seconds: 2),
          ),
        );
        if (mounted) await _demanderPhoto(cible: 'verso');
      }
    } else if (_photoVerso == null) {
      // Étape 2 : Demander le Verso
      await _demanderPhoto(cible: 'verso');
    } else {
      // Étape 3 : Déjà complet, on propose de recommencer
      final recommencer = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Modifier les photos ?'),
          content: const Text('Voulez-vous reprendre les photos de votre pièce d\'identité ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Recommencer')),
          ],
        ),
      );

      if (recommencer == true) {
        setState(() {
          _photoRecto = null;
          _photoVerso = null;
        });
        await _gererCapturePiece();
      }
    }
  }

  Future<bool> _demanderPhoto({required String cible}) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.surfaceMaboko,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.bordureMaboko, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text(cible == 'recto' ? 'Photo AVANT (Recto)' : 'Photo ARRIÈRE (Verso)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.texteFortMaboko)),
            const SizedBox(height: 16),
            ListTile(leading: const Icon(Icons.photo_camera_outlined, color: MabokoCouleurs.secondaire), title: const Text('Prendre une photo'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
            const Divider(height: 1),
            ListTile(leading: const Icon(Icons.photo_library_outlined, color: MabokoCouleurs.secondaire), title: const Text('Choisir dans la galerie'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return false;
    return await _choisirPhoto(cible: cible, source: source);
  }

  Future<bool> _choisirPhoto({required String cible, required ImageSource source}) async {
    setState(() => _envoiPhoto = true);
    try {
      final fichier = await ImagePicker().pickImage(source: source, maxWidth: 1800, imageQuality: 80);
      if (fichier == null) {
        setState(() => _envoiPhoto = false);
        return false;
      }
      final octets = await fichier.readAsBytes();
      if (!mounted) return false;
      final encode = 'data:image/jpeg;base64,${base64Encode(octets)}';
      setState(() {
        if (cible == 'recto') {
          _photoRecto = encode;
        } else if (cible == 'verso') {
          _photoVerso = encode;
        }
        _envoiPhoto = false;
      });
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() => _envoiPhoto = false);
      _informer('Impossible d\'ouvrir $source.', MabokoCouleurs.danger);
      return false;
    }
  }
  // 👆 FIN LOGIQUE DE CAPTURE 👆

  Future<void> _enregistrer() async {
    if (!_cleFormulaire.currentState!.validate()) return;

    if (_permisChoisis.isEmpty) {
      _informer('Choisissez au moins un type de permis.', MabokoCouleurs.danger);
      return;
    }

    if (_photoRecto == null || _photoVerso == null) {
      _informer('Ajoutez la photo Recto ET Verso de votre pièce.', MabokoCouleurs.danger);
      return;
    }

    setState(() => _envoi = true);

    try {
      await _depot.enregistrerFiche(
        typeVehicule: _vehicule,
        modele: _vehicule,
        plaque: _plaque.text.trim().toUpperCase(),
        permisCategories: _permisChoisis.join(','),
        permisNumero: _permisNumero.text.trim().toUpperCase(),
        estClimatise: _estClimatise,
        photoRecto: _photoRecto, // 👈 AJOUT
        photoVerso: _photoVerso, // 👈 AJOUT
      );

      if (!mounted) return;
      setState(() => _envoi = false);

      _informer('Fiche enregistrée. En cours de vérification.', MabokoCouleurs.succes);

      if (widget.premiereFois) {
        Navigator.pushNamedAndRemoveUntil(context, '/chauffeur', (route) => false);
        return;
      }

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _envoi = false);
      _informer(e.message, MabokoCouleurs.danger);
    }
  }

  Future<void> _quitter() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Quitter la création de la fiche ?'),
        content: const Text('Votre compte existe déjà, mais sans fiche vous ne pourrez pas recevoir de courses. Vous pourrez reprendre plus tard depuis votre profil.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Rester')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: MabokoCouleurs.danger, foregroundColor: Colors.white), child: const Text('Quitter et se déconnecter')),
        ],
      ),
    );

    if (confirme != true || !mounted) return;
    await StorageService.deconnecter();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _informer(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: couleur));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: Text(widget.premiereFois ? 'Vos informations chauffeur' : 'Ma fiche véhicule'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.premiereFois,
        actions: [
          IconButton(tooltip: 'Se déconnecter', onPressed: _envoi ? null : _quitter, icon: const Icon(Icons.logout_rounded)),
        ],
      ),
      body: Form(
        key: _cleFormulaire,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _labelObligatoire('Type(s) de permis'),
            const SizedBox(height: 4),
            Text('Sélection multiple possible', style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko)),
            const SizedBox(height: 12),
            _chipsPermis(),

            const SizedBox(height: 20),

            _labelObligatoire('Numéro de permis de conduire'),
            const SizedBox(height: 4),
            Text('Il figure sur votre permis (ex. : AB123456).', style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _permisNumero,
              textCapitalization: TextCapitalization.characters,
              decoration: _decoration('Ex. : AB123456', Icons.credit_card_outlined),
              validator: (valeur) => (valeur ?? '').trim().length < 6 ? 'Entrez le numéro complet du permis.' : null,
            ),

            const SizedBox(height: 24),

            _labelObligatoire('Pièce d’identité (Recto & Verso)'),
            const SizedBox(height: 12),
            _zoneUploadPiece(), // 👈 NOUVEAU WIDGET

            const SizedBox(height: 24),

            _labelObligatoire('Type de véhicule'),
            const SizedBox(height: 12),
            _grilleVehicules(),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: context.surfaceMaboko, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.bordureMaboko)),
              child: Row(
                children: [
                  const Icon(Icons.ac_unit_rounded, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Véhicule climatisé', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                  Switch(value: _estClimatise, activeColor: MabokoCouleurs.secondaire, onChanged: (val) => setState(() => _estClimatise = val)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            _labelObligatoire('Immatriculation du véhicule'),
            const SizedBox(height: 4),
            Text('La plaque physique de votre véhicule.', style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _plaque,
              textCapitalization: TextCapitalization.characters,
              decoration: _decoration('Ex. : BZV 4582', Icons.badge_outlined),
              validator: (valeur) => (valeur ?? '').trim().length < 4 ? 'La plaque est obligatoire.' : null,
            ),

            const SizedBox(height: 20),
            _mentionVerification(),
            const SizedBox(height: 24),

            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _envoi ? null : _enregistrer,
                style: FilledButton.styleFrom(backgroundColor: MabokoCouleurs.secondaire, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _envoi
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                    : Text(widget.premiereFois ? 'Créer mon profil chauffeur' : 'Enregistrer', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 👇 WIDGET POUR AFFICHER LES MINIATURES 👇
  Widget _zoneUploadPiece() {
    final aRecto = _photoRecto != null;
    final aVerso = _photoVerso != null;
    final estComplet = aRecto && aVerso;

    return GestureDetector(
      onTap: _envoiPhoto ? null : _gererCapturePiece,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: estComplet ? MabokoCouleurs.succes.withValues(alpha: 0.05) : context.surfaceMaboko,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: estComplet ? MabokoCouleurs.succes : context.bordureMaboko, width: estComplet ? 1.6 : 1),
        ),
        child: _envoiPhoto
            ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4, color: MabokoCouleurs.secondaire)))
            : Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(estComplet ? Icons.check_circle_rounded : Icons.add_photo_alternate_outlined, color: estComplet ? MabokoCouleurs.succes : MabokoCouleurs.secondaire, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          estComplet ? 'Pièce d\'identité complète' : aRecto ? 'Prendre la face arrière (Verso)' : 'Ajouter la pièce d\'identité (Recto & Verso)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: estComplet ? MabokoCouleurs.succes : context.texteFortMaboko),
                        ),
                      ),
                      if (estComplet) TextButton(onPressed: _gererCapturePiece, child: const Text('Modifier', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                  if (aRecto || aVerso) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _vignettePhoto('Recto', _photoRecto),
                        _vignettePhoto('Verso', _photoVerso),
                      ],
                    )
                  ]
                ],
              ),
      ),
    );
  }

  Widget _vignettePhoto(String label, String? base64Image) {
    final bool fait = base64Image != null;
    return Column(
      children: [
        Container(
          width: 100, height: 70,
          decoration: BoxDecoration(
            color: context.fondMaboko,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: fait ? MabokoCouleurs.succes : context.bordureMaboko, style: fait ? BorderStyle.solid : BorderStyle.none),
          ),
          clipBehavior: Clip.hardEdge,
          child: fait
              ? Image.memory(base64Decode(base64Image.split(',').last), fit: BoxFit.cover)
              : Icon(Icons.image_outlined, color: context.texteSecondaireMaboko),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(fait ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: fait ? MabokoCouleurs.succes : context.texteSecondaireMaboko),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: fait ? MabokoCouleurs.succes : context.texteSecondaireMaboko, fontWeight: fait ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ],
    );
  }
  // 👆 FIN WIDGET 👆

  Widget _chipsPermis() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _permisDisponibles.map((permis) {
        final actif = _permisChoisis.contains(permis.code);
        return GestureDetector(
          onTap: () => setState(() {
            if (actif) {
              if (_permisChoisis.length > 1) _permisChoisis.remove(permis.code);
            } else {
              _permisChoisis.add(permis.code);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: actif ? MabokoCouleurs.secondaire.withValues(alpha: 0.12) : context.surfaceMaboko,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko, width: actif ? 1.5 : 1),
            ),
            child: Text(permis.libelle, style: TextStyle(fontSize: 13, fontWeight: actif ? FontWeight.bold : FontWeight.w500, color: actif ? MabokoCouleurs.secondaire : context.texteFortMaboko)),
          ),
        );
      }).toList(),
    );
  }

  Widget _grilleVehicules() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _vehicules.map((v) {
        final actif = _vehicule == v.code;
        return GestureDetector(
          onTap: () => setState(() => _vehicule = v.code),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: actif ? MabokoCouleurs.secondaire.withValues(alpha: 0.12) : context.surfaceMaboko,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko, width: actif ? 1.5 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(v.icone, size: 16, color: actif ? MabokoCouleurs.secondaire : context.texteSecondaireMaboko),
                const SizedBox(width: 6),
                Text(v.libelle, style: TextStyle(fontSize: 13, fontWeight: actif ? FontWeight.bold : FontWeight.w500, color: actif ? MabokoCouleurs.secondaire : context.texteFortMaboko)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _mentionVerification() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: MabokoCouleurs.accent.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12), border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.4))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 18, color: MabokoCouleurs.accent),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 12, height: 1.45, color: context.texteSecondaireMaboko),
                children: const [
                  TextSpan(text: 'La vérification officielle de vos documents sera faite par l’équipe Maboko. '),
                  TextSpan(text: 'Vous pourrez stocker vos papiers en sécurité dans votre « coffre à documents ».'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _labelObligatoire(String texte) {
    return Row(
      children: [
        Text(texte, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: context.texteFortMaboko)),
        const SizedBox(width: 4),
        const Text('*', style: TextStyle(color: MabokoCouleurs.danger)),
      ],
    );
  }

  InputDecoration _decoration(String indice, IconData icone) {
    return InputDecoration(
      hintText: indice,
      prefixIcon: Icon(icone, size: 20, color: MabokoCouleurs.secondaire),
      filled: true,
      fillColor: context.surfaceMaboko,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.bordureMaboko)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.bordureMaboko)),
    );
  }
}