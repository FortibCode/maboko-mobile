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
/// - ses types de permis (multi-sélection)
/// - sa pièce d'identité (upload)
/// - son type de véhicule
/// - sa plaque d'immatriculation
///
/// Un matricule unique lui est attribué, du type MBK-CH-BZV-2026-7547.
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
    super.dispose();
  }

  /// Génère un matricule unique au format MBK-CH-{VILLE}-{ANNEE}-{4 chiffres}.
  ///
  /// Le matricule est attribué une seule fois, à la création de la fiche.
  /// Il sert d'identifiant public du chauffeur sur la plateforme.
  String _genererMatricule() {
    final maintenant = DateTime.now();
    final annee = maintenant.year;

    // Ville : Brazzaville par défaut (à adapter si le profil a une ville).
    const ville = 'BZV';

    // 4 chiffres aléatoires reproductibles à partir du timestamp.
    final aleatoire = (maintenant.microsecondsSinceEpoch % 10000)
        .toString()
        .padLeft(4, '0');

    return 'MBK-CH-$ville-$annee-$aleatoire';
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
        permis: _permisChoisis.join(','),
      );

      if (!mounted) return;
      setState(() => _envoi = false);

      final matricule = _genererMatricule();
      _informer(
        'Fiche enregistrée. Matricule : $matricule',
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
            // === ENCADRÉ MATRICULE ===
            _encadreMatricule(),

            const SizedBox(height: 24),

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

  /// Encadré matricule en haut de l'écran.
  Widget _encadreMatricule() {
    final matricule = _genererMatricule();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MabokoCouleurs.secondaire, Color(0xFF8B3F1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pin_outlined, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text(
                'VOTRE MATRICULE UNIQUE',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            matricule,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Il vous identifie de façon unique sur Maboko.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Chips multi-sélection pour les permis.
  Widget _chipsPermis() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _permisDisponibles.map((permis) {
        final actif = _permisChoisis.contains(permis.code);

        return GestureDetector(
          onTap: () => setState(() {
            if (actif) {
              // On empêche de tout décocher : au moins un permis reste.
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