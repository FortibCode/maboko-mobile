import 'package:flutter/material.dart';

import '../../../../core/theme/maboko_theme.dart';
import '../fiche_artisan_screen.dart';
import 'inscription_artisan_data.dart';

/// Étape 5 du parcours d'inscription artisan : récapitulatif.
///
/// Montre à l'artisan ce qu'il a renseigné avant la dernière étape (métiers,
/// adresse, rayon). Le bouton finalise et ouvre la fiche artisan, dernière
/// pièce à compléter pour être visible dans les recherches.
class ArtisanTermineScreen extends StatefulWidget {
  const ArtisanTermineScreen({super.key, required this.nomComplet});

  final String nomComplet;

  @override
  State<ArtisanTermineScreen> createState() => _ArtisanTermineScreenState();
}

class _ArtisanTermineScreenState extends State<ArtisanTermineScreen> {
  InscriptionArtisanData? _data;
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
      _data = data;
      _chargement = false;
    });
  }

  Future<void> _finaliser() async {
    if (!mounted) return;

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FicheArtisanScreen(
          nomComplet: widget.nomComplet,
          premiereFois: true,
          villeConnue: _data?.ville,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Profil terminé'),
        backgroundColor: MabokoCouleurs.succes,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
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
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      children: [
        _enTete(),
        const SizedBox(height: 28),
        _titreRecap(),
        const SizedBox(height: 14),
        _carte(
          icone: Icons.workspace_premium_outlined,
          titre: 'Expérience',
          valeur: _libelleExperience(data.experience),
        ),
        _carte(
          icone: Icons.location_city_rounded,
          titre: 'Ville',
          valeur: data.ville ?? '—',
        ),
        _carte(
          icone: Icons.place_outlined,
          titre: 'Quartier',
          valeur: data.quartier ?? '—',
        ),
        _carte(
          icone: Icons.notes_outlined,
          titre: 'Présentation',
          valeur: data.bio ?? '—',
          multiligne: true,
        ),
        _carte(
          icone: data.aRccm == true
              ? Icons.verified_rounded
              : Icons.badge_outlined,
          titre: 'Enregistrement',
          valeur: data.aRccm == true
              ? 'RCCM déposé'
              : 'Pièce d’identité déposée',
        ),
        const SizedBox(height: 24),
        _encadreFinal(),
      ],
    );
  }

  Widget _enTete() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFE8F5E9),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle_rounded,
            size: 64,
            color: MabokoCouleurs.succes,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Votre profil est prêt !',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Dernière étape : dites-nous vos métiers et votre rayon d’intervention.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: context.texteSecondaireMaboko,
          ),
        ),
      ],
    );
  }

  Widget _titreRecap() {
    return Text(
      'Récapitulatif',
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.texteSecondaireMaboko,
        letterSpacing: .3,
      ),
    );
  }

  Widget _carte({
    required IconData icone,
    required String titre,
    required String valeur,
    bool multiligne = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Row(
        crossAxisAlignment:
            multiligne ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: MabokoCouleurs.secondaire.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icone, size: 20, color: MabokoCouleurs.secondaire),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.texteSecondaireMaboko,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  valeur,
                  maxLines: multiligne ? 4 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _encadreFinal() {
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
          const Icon(Icons.info_outline_rounded,
              size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'À l’étape suivante, choisissez vos métiers (jusqu’à 5), '
              'votre adresse d’atelier et votre rayon d’intervention. '
              'C’est ce que les clients verront en vous cherchant.',
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

  Widget _piedDePage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _finaliser,
            style: FilledButton.styleFrom(
              backgroundColor: MabokoCouleurs.secondaire,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text(
              'Choisir mes métiers',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
            ),
          ),
        ),
      ),
    );
  }

  String _libelleExperience(String? code) {
    if (code == null) return '—';
    for (final t in tranchesExperience) {
      if (t.code == code) return t.libelle;
    }
    return code;
  }
}