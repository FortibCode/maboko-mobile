import 'package:flutter/material.dart';

import '../../../../core/theme/maboko_theme.dart';
import 'artisan_ville_quartier_screen.dart';
import 'inscription_artisan_data.dart';

/// Étape 1 du parcours d'inscription artisan : l'expérience.
///
/// Cinq tranches, une seule à choisir. L'expérience pèse dans le classement
/// de recherche et rassure le client avant la première mission.
class ArtisanExperienceScreen extends StatefulWidget {
  const ArtisanExperienceScreen({super.key, required this.nomComplet});

  /// Nom de l'artisan, transmis de l'inscription pour l'accueillir.
  final String nomComplet;

  @override
  State<ArtisanExperienceScreen> createState() =>
      _ArtisanExperienceScreenState();
}

class _ArtisanExperienceScreenState extends State<ArtisanExperienceScreen> {
  String? _choix;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final data = await InscriptionArtisanData.charger();

    if (!mounted) return;
    setState(() {
      _choix = data?.experience;
      _chargement = false;
    });
  }

  Future<void> _continuer() async {
    if (_choix == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez votre expérience pour continuer.'),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );
      return;
    }

    final data = (await InscriptionArtisanData.charger()) ??
        const InscriptionArtisanData();
    await data.copierAvec(experience: _choix).sauvegarder();

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanVilleQuartierScreen(nomComplet: widget.nomComplet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Votre expérience'),
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
        const SizedBox(height: 22),
        _titre(),
        const SizedBox(height: 14),
        ...tranchesExperience.map(_carte),
      ],
    );
  }

  Widget _titre() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Depuis combien de temps exercez-vous ?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: context.texteFortMaboko,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Cette information apparaît sur votre fiche. Elle pèse dans le '
          'classement de recherche.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: context.texteSecondaireMaboko,
          ),
        ),
      ],
    );
  }

  Widget _carte(({String code, String libelle}) tranche) {
    final actif = _choix == tranche.code;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _choix = tranche.code),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko,
                width: actif ? 1.6 : 1,
              ),
              color: actif
                  ? MabokoCouleurs.secondaire.withValues(alpha: 0.06)
                  : null,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    tranche.libelle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: actif ? FontWeight.bold : FontWeight.w500,
                      color: actif
                          ? MabokoCouleurs.secondaire
                          : context.texteFortMaboko,
                    ),
                  ),
                ),
                Icon(
                  actif
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: actif
                      ? MabokoCouleurs.secondaire
                      : context.bordureMaboko,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
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
            onPressed: _choix == null ? null : _continuer,
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
          const Icon(Icons.workspace_premium_outlined,
              size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Bienvenue ${widget.nomComplet} ! Nous allons préparer votre '
              'profil en quelques étapes. Cela prend moins de 2 minutes.',
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
}