import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/maboko_theme.dart';
import 'artisan_termine_screen.dart';
import 'inscription_artisan_data.dart';

/// Étape 4 du parcours d'inscription artisan : RCCM ou pièce d'identité.
///
/// L'artisan a deux voies pour prouver son sérieux :
/// - S'il a un RCCM (Registre du Commerce), il peut obtenir le badge
///   « Artisan Reconnu » en 48 h après vérification par l'équipe Maboko.
/// - Sinon, il vérifie son identité avec une CNI ou un passeport.
/// Dans les deux cas, le badge rassure les clients avant la première mission.
class ArtisanRccmScreen extends StatefulWidget {
  const ArtisanRccmScreen({super.key, required this.nomComplet});

  final String nomComplet;

  @override
  State<ArtisanRccmScreen> createState() => _ArtisanRccmScreenState();
}

class _ArtisanRccmScreenState extends State<ArtisanRccmScreen> {
  bool? _aRccm;

  // === Si RCCM ===
  final _numeroRccm = TextEditingController();
  String? _photoRccm;

  // === Si pièce d'identité ===
  String _typePiece = 'cni'; // 'cni' ou 'passeport'
  final _nomPrenom = TextEditingController();
  final _numeroCarte = TextEditingController();
  final _adresse = TextEditingController();
  String? _photoPiece;

  bool _chargement = true;
  bool _envoiPhoto = false;

  static const _pieces = [
    (valeur: 'cni', libelle: 'Carte d’identité', icone: Icons.badge_outlined),
    (valeur: 'passeport', libelle: 'Passeport', icone: Icons.menu_book_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _numeroRccm.dispose();
    _nomPrenom.dispose();
    _numeroCarte.dispose();
    _adresse.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final data = await InscriptionArtisanData.charger();

    if (!mounted) return;
    setState(() {
      _aRccm = data?.aRccm;
      _photoRccm = data?.photoRccm;
      _photoPiece = data?.photoPiece;
      _chargement = false;
    });
  }

  Future<void> _choisirPhoto({required bool rccm}) async {
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
        if (rccm) {
          _photoRccm = encode;
        } else {
          _photoPiece = encode;
        }
        _envoiPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _envoiPhoto = false);
      _informer('Impossible de prendre la photo sur cet appareil.',
          MabokoCouleurs.danger);
    }
  }

  Future<void> _terminer() async {
    if (_aRccm == null) {
      _informer('Indiquez si vous avez un RCCM.', MabokoCouleurs.danger);
      return;
    }

    if (_aRccm == true) {
      if (_numeroRccm.text.trim().isEmpty) {
        _informer('Saisissez le numéro de votre RCCM.', MabokoCouleurs.danger);
        return;
      }
      if (_photoRccm == null) {
        _informer('Ajoutez la photo de votre RCCM.', MabokoCouleurs.danger);
        return;
      }
    } else {
      if (_nomPrenom.text.trim().isEmpty) {
        _informer('Saisissez votre nom et prénom.', MabokoCouleurs.danger);
        return;
      }
      if (_numeroCarte.text.trim().isEmpty) {
        _informer('Saisissez le numéro de votre pièce.', MabokoCouleurs.danger);
        return;
      }
      if (_adresse.text.trim().isEmpty) {
        _informer('Saisissez votre adresse.', MabokoCouleurs.danger);
        return;
      }
      if (_photoPiece == null) {
        _informer('Ajoutez la photo de votre pièce d’identité.',
            MabokoCouleurs.danger);
        return;
      }
    }

    final data = (await InscriptionArtisanData.charger()) ??
        const InscriptionArtisanData();
    await data
        .copierAvec(
          aRccm: _aRccm,
          photoRccm: _photoRccm,
          photoPiece: _photoPiece,
        )
        .sauvegarder();

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanTermineScreen(nomComplet: widget.nomComplet),
      ),
    );
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
        title: const Text('Enregistrement'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _chargement
          ? const Center(
              child: CircularProgressIndicator(color: MabokoCouleurs.secondaire),
            )
          : Column(
              children: [
                Expanded(child: _corps()),
                _piedDePage(),
              ],
            ),
    );
  }

  Widget _corps() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        _titreSection(),
        const SizedBox(height: 14),
        _carteOui(),
        const SizedBox(height: 10),
        _carteNon(),
        if (_aRccm == true) ...[
          const SizedBox(height: 24),
          _blocRccm(),
        ],
        if (_aRccm == false) ...[
          const SizedBox(height: 24),
          _blocIdentite(),
        ],
        const SizedBox(height: 20),
        _encadreBonASavoir(),
      ],
    );
  }

  Widget _titreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pour obtenir le badge Artisan Reconnu (optionnel)',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: context.texteFortMaboko,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Le badge rassure les clients : il prouve que votre activité est '
          'vérifiée par Maboko.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.45,
            color: context.texteSecondaireMaboko,
          ),
        ),
      ],
    );
  }

  Widget _carteOui() {
    final actif = _aRccm == true;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _aRccm = true),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: actif ? MabokoCouleurs.succes : context.bordureMaboko,
              width: actif ? 1.6 : 1,
            ),
            color: actif
                ? MabokoCouleurs.succes.withValues(alpha: 0.06)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.verified_rounded,
                size: 24,
                color: actif
                    ? MabokoCouleurs.succes
                    : context.texteSecondaireMaboko,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oui, j’ai un RCCM',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: actif
                            ? MabokoCouleurs.succes
                            : context.texteFortMaboko,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Mon entreprise est officiellement enregistrée. '
                      'Je vais télécharger mes documents pour obtenir le badge.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: context.texteSecondaireMaboko,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                actif
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: actif ? MabokoCouleurs.succes : context.bordureMaboko,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carteNon() {
    final actif = _aRccm == false;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _aRccm = false),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: actif ? MabokoCouleurs.accent : context.bordureMaboko,
              width: actif ? 1.6 : 1,
            ),
            color: actif
                ? MabokoCouleurs.accent.withValues(alpha: 0.06)
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.emoji_people_rounded,
                size: 24,
                color: actif
                    ? MabokoCouleurs.accent
                    : context.texteSecondaireMaboko,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pas encore',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: actif
                            ? MabokoCouleurs.accent
                            : context.texteFortMaboko,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Je travaille en tant qu’artisan indépendant. Pas de '
                      'souci, vous pouvez devenir Recommandé par la communauté '
                      'grâce à vos avis clients.',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: context.texteSecondaireMaboko,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                actif
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: actif
                    ? MabokoCouleurs.accent
                    : context.bordureMaboko,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // BLOC RCCM
  // =========================================================================

  Widget _blocRccm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titreBloc(
          icone: Icons.business_center_outlined,
          titre: 'Vos informations d’entreprise',
        ),
        const SizedBox(height: 14),
        _labelObligatoire('NUMÉRO RCCM'),
        const SizedBox(height: 8),
        TextField(
          controller: _numeroRccm,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Ex. : CG-BZV-01-2025-B13-00738',
            filled: true,
            fillColor: context.surfaceMaboko,
            contentPadding: const EdgeInsets.all(14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.bordureMaboko),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.bordureMaboko),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _zoneUpload(
          photo: _photoRccm,
          libelle: 'Télécharger le document RCCM',
          onTap: () => _choisirPhoto(rccm: true),
        ),
        const SizedBox(height: 10),
        _mentionVerification(
          'Votre RCCM sera vérifié sous 48h pour activer le badge '
          'Artisan Reconnu.',
        ),
      ],
    );
  }

  // =========================================================================
  // BLOC PIÈCE D'IDENTITÉ
  // =========================================================================

  Widget _blocIdentite() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _titreBloc(
          icone: Icons.shield_outlined,
          titre: 'Vérification d’identité',
          sous: 'Pour la confiance et la sécurité, nous vérifions '
              'l’identité de chaque artisan.',
        ),
        const SizedBox(height: 16),
        _labelObligatoire('TYPE DE PIÈCE'),
        const SizedBox(height: 8),
        _choixPieces(),
        const SizedBox(height: 16),
        _labelObligatoire('NOM ET PRÉNOM (COMME SUR LA PIÈCE)'),
        const SizedBox(height: 8),
        _champTexte(
          controller: _nomPrenom,
          hint: 'Ex. : NTOLANY Glade',
        ),
        const SizedBox(height: 14),
        _labelObligatoire('NUMÉRO DE LA CARTE'),
        const SizedBox(height: 8),
        _champTexte(
          controller: _numeroCarte,
          hint: 'Ex. : 1234567890',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]')),
          ],
        ),
        const SizedBox(height: 14),
        _labelObligatoire('ADRESSE (QUARTIER, VILLE)'),
        const SizedBox(height: 8),
        _champTexte(
          controller: _adresse,
          hint: 'Ex. : Bacongo, Brazzaville',
        ),
        const SizedBox(height: 14),
        _zoneUpload(
          photo: _photoPiece,
          libelle: 'Photo de la pièce d’identité',
          onTap: () => _choisirPhoto(rccm: false),
        ),
        const SizedBox(height: 10),
        _mentionVerification(
          'Vos documents sont chiffrés et ne servent qu’à la vérification. '
          'Jamais partagés.',
        ),
      ],
    );
  }

  Widget _choixPieces() {
    return Row(
      children: _pieces.map((piece) {
        final actif = _typePiece == piece.valeur;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: piece == _pieces.first ? 8 : 0,
            ),
            child: Material(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => setState(() => _typePiece = piece.valeur),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: actif
                          ? MabokoCouleurs.secondaire
                          : context.bordureMaboko,
                      width: actif ? 1.6 : 1,
                    ),
                    color: actif
                        ? MabokoCouleurs.secondaire.withValues(alpha: 0.06)
                        : null,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        piece.icone,
                        size: 22,
                        color: actif
                            ? MabokoCouleurs.secondaire
                            : context.texteSecondaireMaboko,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        piece.libelle,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight:
                              actif ? FontWeight.bold : FontWeight.w500,
                          color: actif
                              ? MabokoCouleurs.secondaire
                              : context.texteFortMaboko,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // =========================================================================
  // COMPOSANTS PARTAGÉS
  // =========================================================================

  Widget _titreBloc({
    required IconData icone,
    required String titre,
    String? sous,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 20, color: MabokoCouleurs.secondaire),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.bold,
                  color: context.texteFortMaboko,
                ),
              ),
              if (sous != null) ...[
                const SizedBox(height: 3),
                Text(
                  sous,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: context.texteSecondaireMaboko,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _labelObligatoire(String texte) {
    return Row(
      children: [
        Text(
          texte,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: context.texteSecondaireMaboko,
          ),
        ),
        const SizedBox(width: 4),
        const Text('*', style: TextStyle(color: MabokoCouleurs.danger)),
      ],
    );
  }

  Widget _champTexte({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: context.surfaceMaboko,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.bordureMaboko),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.bordureMaboko),
        ),
      ),
    );
  }

  Widget _zoneUpload({
    required String? photo,
    required String libelle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _envoiPhoto ? null : onTap,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: context.surfaceMaboko,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: photo != null ? MabokoCouleurs.succes : context.bordureMaboko,
            style: BorderStyle.solid,
            width: photo != null ? 1.5 : 1,
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
            : photo != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: MabokoCouleurs.succes, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Document ajouté',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: context.texteFortMaboko,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: onTap,
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
                      const Icon(Icons.file_upload_outlined,
                          size: 20, color: MabokoCouleurs.secondaire),
                      const SizedBox(width: 8),
                      Text(
                        libelle,
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

  Widget _mentionVerification(String texte) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined,
            size: 14, color: context.texteSecondaireMaboko),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texte,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.4,
              color: context.texteSecondaireMaboko,
            ),
          ),
        ),
      ],
    );
  }

  Widget _encadreBonASavoir() {
    return Container(
      padding: const EdgeInsets.all(14),
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
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: context.texteSecondaireMaboko,
                ),
                children: const [
                  TextSpan(
                    text: 'Bon à savoir : ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: 'sur maboko.com, les artisans formels et informels '
                        'ont les mêmes chances de réussir. Ce qui compte, '
                        'c’est la qualité de votre travail !',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _piedDePage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton(
            onPressed: _aRccm == null ? null : _terminer,
            style: FilledButton.styleFrom(
              backgroundColor: MabokoCouleurs.secondaire,
              foregroundColor: Colors.white,
              disabledBackgroundColor: context.bordureMaboko,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Terminer mon profil',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
            ),
          ),
        ),
      ),
    );
  }
}