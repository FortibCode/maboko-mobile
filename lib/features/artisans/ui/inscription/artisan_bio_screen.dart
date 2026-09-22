import 'package:flutter/material.dart';

import '../../../../core/theme/maboko_theme.dart';
import 'artisan_rccm_screen.dart';
import 'inscription_artisan_data.dart';

/// Étape 4 du parcours d'inscription artisan : la bio.
///
/// Présentation libre, limitée à 100 mots. Un compteur en direct évite la
/// mauvaise surprise au moment de valider. Cette bio apparaît sur la fiche
/// publique de l'artisan.
class ArtisanBioScreen extends StatefulWidget {
  const ArtisanBioScreen({super.key, required this.nomComplet});

  final String nomComplet;

  @override
  State<ArtisanBioScreen> createState() => _ArtisanBioScreenState();
}

class _ArtisanBioScreenState extends State<ArtisanBioScreen> {
  static const _limiteMots = 100;

  final _controleur = TextEditingController();

  int _nbMots = 0;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _controleur.addListener(_compterMots);
    _charger();
  }

  @override
  void dispose() {
    _controleur.removeListener(_compterMots);
    _controleur.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final data = await InscriptionArtisanData.charger();

    if (!mounted) return;
    setState(() {
      _controleur.text = data?.bio ?? '';
      _nbMots = _compter(_controleur.text);
      _chargement = false;
    });
  }

  void _compterMots() {
    setState(() => _nbMots = _compter(_controleur.text));
  }

  int _compter(String texte) {
    final propre = texte.trim();
    if (propre.isEmpty) return 0;

    return propre.split(RegExp(r'\s+')).length;
  }

  Future<void> _continuer() async {
    final texte = _controleur.text.trim();

    if (texte.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Écrivez quelques mots pour vous présenter.'),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );
      return;
    }

    if (_nbMots > _limiteMots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trop long : $_nbMots mots sur $_limiteMots.'),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );
      return;
    }

    final data = (await InscriptionArtisanData.charger()) ??
        const InscriptionArtisanData();
    await data.copierAvec(bio: texte).sauvegarder();

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanRccmScreen(nomComplet: widget.nomComplet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Présentez-vous'),
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
        _encadre(),
        const SizedBox(height: 20),
        _titre(),
        const SizedBox(height: 10),
        _champBio(),
        const SizedBox(height: 12),
        _compteur(),
      ],
    );
  }

  Widget _titre() {
    return Text(
      'Quelques mots sur votre savoir-faire',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: context.texteFortMaboko,
      ),
    );
  }

  Widget _encadre() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.teinteMaboko,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_outlined,
              size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Évitez les généralités. Un client préfère lire « je répare '
              'les fuites depuis 8 ans à Bacongo » plutôt que « je suis un '
              'bon artisan ».',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: context.texteSecondaireMaboko,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _champBio() {
    final tropLong = _nbMots > _limiteMots;

    return TextField(
      controller: _controleur,
      maxLines: 10,
      minLines: 6,
      textCapitalization: TextCapitalization.sentences,
      style: const TextStyle(fontSize: 14.5, height: 1.5),
      decoration: InputDecoration(
        hintText:
            'Ex. : Menuisier depuis 12 ans, je travaille le bois massif et '
            'le contreplaqué. Spécialisé dans les meubles sur mesure et la '
            'réparation de portes. J’intervins à Bacongo et alentours.',
        hintStyle: TextStyle(
          fontSize: 13.5,
          height: 1.5,
          color: context.texteSecondaireMaboko.withValues(alpha: 0.7),
        ),
        filled: true,
        fillColor: context.surfaceMaboko,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: tropLong ? MabokoCouleurs.danger : context.bordureMaboko,
            width: tropLong ? 1.6 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: tropLong ? MabokoCouleurs.danger : context.bordureMaboko,
            width: tropLong ? 1.6 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: tropLong ? MabokoCouleurs.danger : MabokoCouleurs.secondaire,
            width: 1.6,
          ),
        ),
      ),
    );
  }

  Widget _compteur() {
    final tropLong = _nbMots > _limiteMots;
    final presque = _nbMots > (_limiteMots * 0.85) && !tropLong;

    final couleur = tropLong
        ? MabokoCouleurs.danger
        : presque
            ? MabokoCouleurs.accent
            : context.texteSecondaireMaboko;

    return Row(
      children: [
        Icon(
          tropLong
              ? Icons.error_outline_rounded
              : Icons.info_outline_rounded,
          size: 16,
          color: couleur,
        ),
        const SizedBox(width: 6),
        Text(
          '$_nbMots / $_limiteMots mots',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: couleur,
          ),
        ),
        if (tropLong) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Retirez quelques mots pour continuer.',
              style: TextStyle(
                fontSize: 12.5,
                color: MabokoCouleurs.danger,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _piedDePage() {
    final peutContinuer =
        _controleur.text.trim().isNotEmpty && _nbMots <= _limiteMots;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton(
            onPressed: peutContinuer ? _continuer : null,
            style: FilledButton.styleFrom(
              backgroundColor: MabokoCouleurs.secondaire,
              foregroundColor: Colors.white,
              disabledBackgroundColor: context.bordureMaboko,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Continuer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
            ),
          ),
        ),
      ),
    );
  }
}