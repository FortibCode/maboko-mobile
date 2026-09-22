import 'package:flutter/material.dart';

import '../../../../core/theme/maboko_theme.dart';
import 'artisan_bio_screen.dart';
import 'inscription_artisan_data.dart';

/// Étape 3 du parcours d'inscription artisan : le quartier.
///
/// La liste dépend de la ville choisie à l'étape précédente. Un artisan
/// sans quartier n'apparaît pas dans les recherches de proximité.
class ArtisanQuartierScreen extends StatefulWidget {
  const ArtisanQuartierScreen({super.key, required this.nomComplet});

  final String nomComplet;

  @override
  State<ArtisanQuartierScreen> createState() => _ArtisanQuartierScreenState();
}

class _ArtisanQuartierScreenState extends State<ArtisanQuartierScreen> {
  String? _ville;
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
      _ville = data?.ville;
      _choix = data?.quartier;
      _chargement = false;
    });
  }

  Future<void> _continuer() async {
    if (_choix == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez votre quartier pour continuer.'),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );
      return;
    }

    final data = (await InscriptionArtisanData.charger()) ??
        const InscriptionArtisanData();
    await data.copierAvec(quartier: _choix).sauvegarder();

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanBioScreen(nomComplet: widget.nomComplet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Votre quartier'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _chargement
          ? const Center(
              child: CircularProgressIndicator(color: MabokoCouleurs.secondaire),
            )
          : _ville == null
              ? _erreurVilleManquante()
              : Column(
                  children: [
                    Expanded(child: _corps()),
                    _piedDePage(),
                  ],
                ),
    );
  }

  Widget _corps() {
    final quartiers = quartiersParVille[_ville] ?? const <String>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        _titre(),
        const SizedBox(height: 16),
        ...quartiers.map(_carte),
      ],
    );
  }

  Widget _titre() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dans quel quartier de $_ville ?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: context.texteFortMaboko,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Le quartier aide les clients proches à vous trouver plus vite.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: context.texteSecondaireMaboko,
          ),
        ),
      ],
    );
  }

  Widget _carte(String quartier) {
    final actif = _choix == quartier;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _choix = quartier),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                Icon(
                  Icons.place_outlined,
                  size: 20,
                  color: actif
                      ? MabokoCouleurs.secondaire
                      : context.texteSecondaireMaboko,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    quartier,
                    style: TextStyle(
                      fontSize: 14.5,
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

  Widget _erreurVilleManquante() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 60),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: MabokoCouleurs.danger.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MabokoCouleurs.danger.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: MabokoCouleurs.danger, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Ville manquante',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Impossible de déterminer votre ville. Revenez à l’étape '
                'précédente pour la choisir.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: context.texteSecondaireMaboko,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: MabokoCouleurs.secondaire,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retour'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}