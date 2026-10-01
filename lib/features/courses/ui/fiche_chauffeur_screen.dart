import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../data/course_repository.dart';

/// Dépôt de la fiche véhicule du chauffeur (§5.3.1).
///
/// L'inscription crée le compte, jamais la fiche. Sans elle, tout l'espace
/// chauffeur répond 404 et aucune course ne peut être proposée.
///
/// Le chauffeur renseigne :
/// - ses types de permis (catégories A, B, C...)
/// - le numéro unique de son permis
/// - sa pièce d'identité (upload)
/// - son type de véhicule
/// - sa plaque d'immatriculation
class FicheChauffeurScreen extends StatefulWidget {
  const FicheChauffeurScreen({super.key, this.premiereFois = false});

  /// Passage juste après la création du compte : pas de retour en arrière,
  /// et l'écran ouvre l'espace chauffeur au lieu de se refermer.
  final bool premiereFois;

  @override
  State<FicheChauffeurScreen> createState() => _FicheChauffeurScreenState();
}

class _FicheChauffeurScreenState extends State<FicheChauffeurScreen> {
  static const _depot = CourseRepository();

  /// Types de permis disponibles (codes officiels).
  static const _permisDisponibles = <({String code, String libelle})>[
    (code: 'A', libelle: 'Moto (A)'),
    (code: 'B', libelle: 'Voiture (B)'),
    (code: 'C', libelle: 'Camion (C)'),
    (code: 'D', libelle: 'Bus (D)'),
    (code: 'E', libelle: 'Remorque (E)'),
  ];

  /// Types de véhicule disponibles.
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

  /// Numéro unique du document de permis (ex: AB123456).
  ///
  /// C'est ce numéro qui est unique par personne, contrairement aux
  /// catégories (plusieurs chauffeurs ont la catégorie B).
  final _permisNumero = TextEditingController();

  final Set<String> _permisChoisis = {};
  String _vehicule = 'taxi';
  String? _photoPiece;
  bool _envoi = false;
  bool _envoiPhoto = false;

  @override
  void initState() {
    super.initState();
    // Par défaut : permis B (voiture), le plus courant.
    _permisChoisis.add('B');
  }

  @override
  void dispose() {
    _plaque.dispose();
    _permisNumero.dispose();
    super.dispose();
  }

  Future<void> _choisirPhoto() async {
    setState(() => _envoiPhoto = true);

    try {
      final fichier = await ImagePicker().pickImage(
        source: ImageSource.camera,
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
        _photoPiece = encode;
        _envoiPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _envoiPhoto = false);
      _informer('Impossible de prendre la photo sur cet appareil.',
          MabokoCouleurs.danger);
    }
  }

  Future<void> _enregistrer() async {
    if (!_cleFormulaire.currentState!.validate()) return;

    if (_permisChoisis.isEmpty) {
      _informer('Choisissez au moins un type de permis.', MabokoCouleurs.danger);
      return;
    }

    if (_photoPiece == null) {
      _informer('Ajoutez la photo de votre pièce d’identité.',
          MabokoCouleurs.danger);
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
      );

      if (!mounted) return;
      setState(() => _envoi = false);

      _informer(
        'Fiche enregistrée. En cours de vérification.',
        MabokoCouleurs.succes,
      );

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
        title: Text(widget.premiereFois
            ? 'Vos informations chauffeur'
            : 'Ma fiche véhicule'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.premiereFois,
      ),
      body: Form(
        key: _cleFormulaire,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            // === TYPES DE PERMIS ===
            _labelObligatoire('Type(s) de permis'),
            const SizedBox(height: 4),
            Text(
              'Sélection multiple possible',
              style: TextStyle(
                fontSize: 12,
                color: context.texteSecondaireMaboko,
              ),
            ),
            const SizedBox(height: 12),
            _chipsPermis(),

            const SizedBox(height: 20),

            // === NUMÉRO DE PERMIS ===
            _labelObligatoire('Numéro de permis de conduire'),
            const SizedBox(height: 4),
            Text(
              'Il figure sur votre permis (ex. : AB123456).',
              style: TextStyle(
                fontSize: 12,
                color: context.texteSecondaireMaboko,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _permisNumero,
              textCapitalization: TextCapitalization.characters,
              decoration: _decoration(
                'Ex. : AB123456',
                Icons.credit_card_outlined,
              ),
              validator: (valeur) {
                final propre = (valeur ?? '').trim();

                if (propre.length < 6) {
                  return 'Entrez le numéro complet du permis.';
                }

                return null;
              },
            ),

            const SizedBox(height: 24),

            // === PIÈCE D'IDENTITÉ ===
            _labelObligatoire('Pièce d’identité (CNI ou passeport)'),
            const SizedBox(height: 12),
            _zoneUploadPiece(),

            const SizedBox(height: 24),

            // === TYPE DE VÉHICULE ===
            _labelObligatoire('Type de véhicule'),
            const SizedBox(height: 12),
            _grilleVehicules(),

            const SizedBox(height: 24),

            // === IMMATRICULATION ===
            _labelObligatoire('Immatriculation du véhicule'),
            const SizedBox(height: 4),
            Text(
              'La plaque physique de votre véhicule.',
              style: TextStyle(
                fontSize: 12,
                color: context.texteSecondaireMaboko,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _plaque,
              textCapitalization: TextCapitalization.characters,
              decoration: _decoration('Ex. : BZV 4582', Icons.badge_outlined),
              validator: (valeur) => (valeur ?? '').trim().length < 4
                  ? 'La plaque est obligatoire.'
                  : null,
            ),

            const SizedBox(height: 20),

            // === MENTION VÉRIFICATION ===
            _mentionVerification(),

            const SizedBox(height: 24),

            // === BOUTON ===
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _envoi ? null : _enregistrer,
                style: FilledButton.styleFrom(
                  backgroundColor: MabokoCouleurs.secondaire,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _envoi
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      )
                    : Text(
                        widget.premiereFois
                            ? 'Créer mon profil chauffeur'
                            : 'Enregistrer',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chips multi-sélection pour les catégories de permis.
  Widget _chipsPermis() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _permisDisponibles.map((permis) {
        final actif = _permisChoisis.contains(permis.code);

        return GestureDetector(
          onTap: () => setState(() {
            if (actif) {
              // On empêche de tout décocher : au moins une catégorie reste.
              if (_permisChoisis.length > 1) {
                _permisChoisis.remove(permis.code);
              }
            } else {
              _permisChoisis.add(permis.code);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: actif
                  ? MabokoCouleurs.secondaire.withValues(alpha: 0.12)
                  : context.surfaceMaboko,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: actif
                    ? MabokoCouleurs.secondaire
                    : context.bordureMaboko,
                width: actif ? 1.5 : 1,
              ),
            ),
            child: Text(
              permis.libelle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: actif ? FontWeight.bold : FontWeight.w500,
                color: actif
                    ? MabokoCouleurs.secondaire
                    : context.texteFortMaboko,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Zone d'upload de la pièce d'identité.
  Widget _zoneUploadPiece() {
    final aPhoto = _photoPiece != null;

    return GestureDetector(
      onTap: _envoiPhoto ? null : _choisirPhoto,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: context.surfaceMaboko,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: aPhoto ? MabokoCouleurs.succes : context.bordureMaboko,
            width: aPhoto ? 1.6 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: _envoiPhoto
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: MabokoCouleurs.secondaire,
                ),
              )
            : aPhoto
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: MabokoCouleurs.succes, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Pièce ajoutée',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: context.texteFortMaboko,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _choisirPhoto,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: MabokoCouleurs.secondaire,
                        ),
                        child: const Text('Reprendre',
                            style: TextStyle(fontSize: 12.5)),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload_file_outlined,
                          size: 20, color: MabokoCouleurs.secondaire),
                      const SizedBox(width: 8),
                      Text(
                        'Téléverser et vérifier ma pièce',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: context.texteFortMaboko,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  /// Grille de choix du type de véhicule.
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
              color: actif
                  ? MabokoCouleurs.secondaire.withValues(alpha: 0.12)
                  : context.surfaceMaboko,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: actif
                    ? MabokoCouleurs.secondaire
                    : context.bordureMaboko,
                width: actif ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  v.icone,
                  size: 16,
                  color: actif
                      ? MabokoCouleurs.secondaire
                      : context.texteSecondaireMaboko,
                ),
                const SizedBox(width: 6),
                Text(
                  v.libelle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: actif ? FontWeight.bold : FontWeight.w500,
                    color: actif
                        ? MabokoCouleurs.secondaire
                        : context.texteFortMaboko,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Mention "vérification sous 48h".
  Widget _mentionVerification() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MabokoCouleurs.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MabokoCouleurs.accent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: MabokoCouleurs.accent),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  color: context.texteSecondaireMaboko,
                ),
                children: const [
                  TextSpan(
                    text: 'La vérification officielle de vos documents sera '
                        'faite par l’équipe Maboko. ',
                  ),
                  TextSpan(
                    text: 'Vous pourrez stocker vos papiers en sécurité dans '
                        'votre « coffre à documents ».',
                  ),
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
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: context.texteFortMaboko,
          ),
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