import 'package:flutter/material.dart';

import '../../../../core/theme/maboko_theme.dart';
import 'artisan_quartier_screen.dart';
import 'inscription_artisan_data.dart';

/// Étape 2 du parcours d'inscription artisan : la ville.
///
/// Six villes principales du Congo. Une fois choisie, on passe au quartier
/// dans cette ville. Le couple ville + quartier sert à situer l'artisan
/// dans les recherches.
class ArtisanVilleScreen extends StatefulWidget {
  const ArtisanVilleScreen({super.key, required this.nomComplet});

  final String nomComplet;

  @override
  State<ArtisanVilleScreen> createState() => _ArtisanVilleScreenState();
}

class _ArtisanVilleScreenState extends State<ArtisanVilleScreen> {
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
      _choix = data?.ville;
      _chargement = false;
    });
  }

  Future<void> _continuer() async {
    if (_choix == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez votre ville pour continuer.'),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );
      return;
    }

    final data = (await InscriptionArtisanData.charger()) ??
        const InscriptionArtisanData();
    await data.copierAvec(ville: _choix).sauvegarder();

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanQuartierScreen(nomComplet: widget.nomComplet),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Votre ville'),
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
        _titre(),
        const SizedBox(height: 16),
        ...villesDisponibles.map(_carte),
      ],
    );
  }

  Widget _titre() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Où exercez-vous ?',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: context.texteFortMaboko,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choisissez la ville où vous travaillez principalement. Vous pourrez '
          'élargir votre zone plus tard.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: context.texteSecondaireMaboko,
          ),
        ),
      ],
    );
  }

  Widget _carte(String ville) {
    final actif = _choix == ville;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _choix = ville),
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
                Icon(
                  Icons.location_city_rounded,
                  size: 22,
                  color: actif
                      ? MabokoCouleurs.secondaire
                      : context.texteSecondaireMaboko,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    ville,
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
}