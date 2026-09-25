import 'package:flutter/material.dart';

import '../../../../core/theme/maboko_theme.dart';
import 'artisan_bio_screen.dart';
import 'inscription_artisan_data.dart';

/// Étape 2 du parcours d'inscription artisan : ville + quartier.
///
/// Fusion des deux anciens écrans : on choisit sa ville, et les quartiers
/// de cette ville apparaissent immédiatement en dessous. Plus rapide, plus
/// clair, et conforme à la maquette Maboko.
class ArtisanVilleQuartierScreen extends StatefulWidget {
  const ArtisanVilleQuartierScreen({super.key, required this.nomComplet});

  final String nomComplet;

  @override
  State<ArtisanVilleQuartierScreen> createState() =>
      _ArtisanVilleQuartierScreenState();
}

class _ArtisanVilleQuartierScreenState
    extends State<ArtisanVilleQuartierScreen> {
  String? _ville;
  String? _quartier;
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
      _quartier = data?.quartier;
      _chargement = false;
    });
  }

  Future<void> _continuer() async {
    if (_ville == null) {
      _informer('Choisissez votre ville pour continuer.');
      return;
    }

    if (_quartier == null) {
      _informer('Choisissez votre quartier pour continuer.');
      return;
    }

    final data = (await InscriptionArtisanData.charger()) ??
        const InscriptionArtisanData();
    await data
        .copierAvec(ville: _ville, quartier: _quartier)
        .sauvegarder();

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanBioScreen(nomComplet: widget.nomComplet),
      ),
    );
  }

  void _informer(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MabokoCouleurs.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Votre localisation'),
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
    final quartiers = _ville == null
        ? const <String>[]
        : (quartiersParVille[_ville] ?? const <String>[]);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        _titre(),
        const SizedBox(height: 20),
        _section('VOTRE VILLE'),
        const SizedBox(height: 10),
        _grilleVilles(),
        if (_ville != null) ...[
          const SizedBox(height: 26),
          _section('VOTRE QUARTIER'),
          const SizedBox(height: 10),
          _chipsQuartiers(quartiers),
        ],
      ],
    );
  }

  Widget _section(String titre) {
    return Text(
      titre,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: context.texteSecondaireMaboko,
      ),
    );
  }

  Widget _titre() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Où êtes-vous basé ?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.texteFortMaboko,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Les clients vous trouveront près de chez eux.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            color: context.texteSecondaireMaboko,
          ),
        ),
      ],
    );
  }

  Widget _grilleVilles() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.2,
      children: villesDisponibles.map(_carteVille).toList(),
    );
  }

  Widget _carteVille(String ville) {
    final actif = _ville == ville;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() {
          _ville = ville;
          // On garde le quartier seulement s'il est dans la nouvelle ville.
          final quartiers = quartiersParVille[ville] ?? const <String>[];
          if (_quartier != null && !quartiers.contains(_quartier)) {
            _quartier = null;
          }
        }),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko,
              width: actif ? 1.6 : 1,
            ),
            color: actif
                ? MabokoCouleurs.secondaire.withValues(alpha: 0.08)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 22,
                color: actif
                    ? MabokoCouleurs.secondaire
                    : context.texteSecondaireMaboko,
              ),
              const SizedBox(height: 6),
              Text(
                ville,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: actif ? FontWeight.bold : FontWeight.w600,
                  color: actif
                      ? MabokoCouleurs.secondaire
                      : context.texteFortMaboko,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipsQuartiers(List<String> quartiers) {
    if (quartiers.isEmpty) {
      return Text(
        'Aucun quartier disponible pour cette ville.',
        style: TextStyle(
          fontSize: 13,
          color: context.texteSecondaireMaboko,
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quartiers.map(_chipQuartier).toList(),
    );
  }

  Widget _chipQuartier(String quartier) {
    final actif = _quartier == quartier;

    return GestureDetector(
      onTap: () => setState(() => _quartier = quartier),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: actif
              ? MabokoCouleurs.secondaire.withValues(alpha: 0.12)
              : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko,
            width: actif ? 1.5 : 1,
          ),
        ),
        child: Text(
          quartier,
          style: TextStyle(
            fontSize: 13,
            fontWeight: actif ? FontWeight.bold : FontWeight.w500,
            color:
                actif ? MabokoCouleurs.secondaire : context.texteFortMaboko,
          ),
        ),
      ),
    );
  }

  Widget _piedDePage() {
    final peutContinuer = _ville != null && _quartier != null;

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