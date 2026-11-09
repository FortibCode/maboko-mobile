import 'dart:convert';

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
    // Les seuls types que l'API accepte, et qui ont un tarif et des courses.
    (code: 'voiture', libelle: 'Voiture', icone: Icons.directions_car_rounded),
    (code: 'moto', libelle: 'Moto', icone: Icons.two_wheeler_rounded),
  ];

  final _cleFormulaire = GlobalKey<FormState>();
  final _plaque = TextEditingController();
  final _permisNumero = TextEditingController();

  final Set<String> _permisChoisis = {};
  String _vehicule = 'voiture';
  bool _estClimatise = false;

  String? _photoRecto; // Photo AVANT
  String? _photoVerso; // Photo ARRIÈRE

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

  // ── CAPTURE D'UNE PHOTO (Recto ou Verso) ──────────────────────────────
  Future<void> _prendrePhoto({required String cible}) async {
    // 1. Demander la source (Caméra ou Galerie)
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.surfaceMaboko,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: context.bordureMaboko, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            Text(
              cible == 'recto' ? 'Photo AVANT (Recto)' : 'Photo ARRIÈRE (Verso)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.texteFortMaboko),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: MabokoCouleurs.secondaire),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: MabokoCouleurs.secondaire),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    setState(() => _envoiPhoto = true);

    try {
      final fichier = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1800,
        imageQuality: 80,
      );

      if (fichier == null) {
        setState(() => _envoiPhoto = false);
        return;
      }

      final octets = await fichier.readAsBytes();
      if (!mounted) return;

      final encode = 'data:image/jpeg;base64,${base64Encode(octets)}';

      setState(() {
        if (cible == 'recto') {
          _photoRecto = encode;
        } else {
          _photoVerso = encode;
        }
        _envoiPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _envoiPhoto = false);
      _informer('Impossible d\'ouvrir la source de photo.', MabokoCouleurs.danger);
    }
  }

  Future<void> _enregistrer() async {
    if (!_cleFormulaire.currentState!.validate()) return;

    if (_permisChoisis.isEmpty) {
      _informer('Choisissez au moins un type de permis.', MabokoCouleurs.danger);
      return;
    }

    // 👇 VÉRIFICATION OBLIGATOIRE DES DEUX PHOTOS 👇
    if (_photoRecto == null) {
      _informer('Vous devez prendre la photo AVANT (Recto) de votre carte d\'identité.', MabokoCouleurs.danger);
      return;
    }
    if (_photoVerso == null) {
      _informer('Vous devez prendre la photo ARRIÈRE (Verso) de votre carte d\'identité.', MabokoCouleurs.danger);
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
        photoRecto: _photoRecto,
        photoVerso: _photoVerso,
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
        content: const Text(
          'Votre compte existe déjà, mais sans fiche vous ne pourrez pas recevoir de courses. Vous pourrez reprendre plus tard depuis votre profil.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Rester')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: MabokoCouleurs.danger, foregroundColor: Colors.white),
            child: const Text('Quitter et se déconnecter'),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;
    await StorageService.deconnecter();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _informer(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: couleur),
    );
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
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: _envoi ? null : _quitter,
            icon: const Icon(Icons.logout_rounded),
          ),
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
              validator: (valeur) {
                final propre = (valeur ?? '').trim();
                if (propre.length < 6) return 'Entrez le numéro complet du permis.';
                return null;
              },
            ),

            const SizedBox(height: 24),

            // 👇 NOUVELLE INTERFACE POUR LES DEUX PHOTOS 👇
            _labelObligatoire('Carte d\'identité (Recto & Verso)'),
            const SizedBox(height: 4),
            Text(
              'Vous devez obligatoirement prendre les DEUX photos.',
              style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko),
            ),
            const SizedBox(height: 12),
            
            // Photo AVANT (Recto)
            _cartePhoto(
              titre: 'Photo AVANT (Recto)',
              sousTitre: 'Face avant de votre carte',
              base64Image: _photoRecto,
              onTap: _envoiPhoto ? null : () => _prendrePhoto(cible: 'recto'),
              estObligatoire: true,
            ),
            
            const SizedBox(height: 12),
            
            // Photo ARRIÈRE (Verso)
            _cartePhoto(
              titre: 'Photo ARRIÈRE (Verso)',
              sousTitre: 'Face arrière de votre carte',
              base64Image: _photoVerso,
              onTap: _envoiPhoto ? null : () => _prendrePhoto(cible: 'verso'),
              estObligatoire: true,
            ),
            // 👆 FIN NOUVELLE INTERFACE 👆

            const SizedBox(height: 24),

            _labelObligatoire('Type de véhicule'),
            const SizedBox(height: 12),
            _grilleVehicules(),

            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: context.surfaceMaboko,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.bordureMaboko),
              ),
              child: Row(
                children: [
                  const Icon(Icons.ac_unit_rounded, color: Colors.blue),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text('Véhicule climatisé', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  ),
                  Switch(
                    value: _estClimatise,
                    activeColor: MabokoCouleurs.secondaire,
                    onChanged: (val) => setState(() => _estClimatise = val),
                  ),
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
                style: FilledButton.styleFrom(
                  backgroundColor: MabokoCouleurs.secondaire,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _envoi
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4))
                    : Text(
                        widget.premiereFois ? 'Créer mon profil chauffeur' : 'Enregistrer',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 👇 WIDGET RÉUTILISABLE POUR CHAQUE PHOTO 👇
  Widget _cartePhoto({
    required String titre,
    required String sousTitre,
    required String? base64Image,
    required VoidCallback? onTap,
    required bool estObligatoire,
  }) {
    final aUnePhoto = base64Image != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: aUnePhoto ? MabokoCouleurs.succes.withValues(alpha: 0.05) : context.surfaceMaboko,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: aUnePhoto ? MabokoCouleurs.succes : context.bordureMaboko,
            width: aUnePhoto ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            // Zone d'aperçu
            Container(
              width: 80, height: 60,
              decoration: BoxDecoration(
                color: context.fondMaboko,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.bordureMaboko),
              ),
              clipBehavior: Clip.hardEdge,
              child: aUnePhoto
                  ? Image.memory(
                      base64Decode(base64Image.split(',').last),
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.add_a_photo_outlined, color: context.texteSecondaireMaboko),
            ),
            const SizedBox(width: 14),
            // Texte et statut
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        titre,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: aUnePhoto ? MabokoCouleurs.succes : context.texteFortMaboko,
                        ),
                      ),
                      if (estObligatoire) ...[
                        const SizedBox(width: 4),
                        const Text('*', style: TextStyle(color: MabokoCouleurs.danger)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sousTitre,
                    style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        aUnePhoto ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 14,
                        color: aUnePhoto ? MabokoCouleurs.succes : context.texteSecondaireMaboko,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        aUnePhoto ? 'Photo ajoutée' : 'Appuyez pour prendre la photo',
                        style: TextStyle(
                          fontSize: 11,
                          color: aUnePhoto ? MabokoCouleurs.succes : context.texteSecondaireMaboko,
                          fontWeight: aUnePhoto ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (_envoiPhoto)
              const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ],
        ),
      ),
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
              border: Border.all(
                color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko,
                width: actif ? 1.5 : 1,
              ),
            ),
            child: Text(
              permis.libelle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: actif ? FontWeight.bold : FontWeight.w500,
                color: actif ? MabokoCouleurs.secondaire : context.texteFortMaboko,
              ),
            ),
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
              border: Border.all(
                color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko,
                width: actif ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(v.icone, size: 16, color: actif ? MabokoCouleurs.secondaire : context.texteSecondaireMaboko),
                const SizedBox(width: 6),
                Text(
                  v.libelle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: actif ? FontWeight.bold : FontWeight.w500,
                    color: actif ? MabokoCouleurs.secondaire : context.texteFortMaboko,
                  ),
                ),
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
      decoration: BoxDecoration(
        color: MabokoCouleurs.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.4)),
      ),
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
                  TextSpan(text: 'La vérification officielle de vos documents sera faite par l\'équipe Maboko. '),
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
        Text(
          texte,
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: context.texteFortMaboko),
        ),
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.bordureMaboko),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.bordureMaboko),
      ),
    );
  }
}