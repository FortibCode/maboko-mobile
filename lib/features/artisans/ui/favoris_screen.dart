import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/artisan_repository.dart';
import '../models/artisan.dart';
import 'artisan_profile_screen.dart';
import 'carte_artisan.dart';

/// Artisans de confiance du client (§5.1.7).
///
/// L'entrée « Mes artisans de confiance » du menu existait depuis le début,
/// mais n'ouvrait rien : elle était déclarée sans action. L'API des favoris,
/// elle, était déjà en place.
class FavorisScreen extends StatefulWidget {
  const FavorisScreen({super.key});

  @override
  State<FavorisScreen> createState() => _FavorisScreenState();
}

class _FavorisScreenState extends State<FavorisScreen> {
  static const _depot = ArtisanRepository();

  List<Artisan>? _artisans;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      final liste = await _depot.favoris();
      if (!mounted) return;
      setState(() => _artisans = liste);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    }
  }

  Future<void> _retirer(Artisan artisan) async {
    try {
      await _depot.basculerFavori(artisan.id);
      if (!mounted) return;

      setState(() => _artisans = _artisans?.where((a) => a.id != artisan.id).toList());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${artisan.nomComplet} retiré de vos artisans de confiance.'),
          backgroundColor: MabokoCouleurs.principale,
          action: SnackBarAction(
            label: 'Annuler',
            textColor: MabokoCouleurs.accent,
            onPressed: () async {
              await _depot.basculerFavori(artisan.id);
              await _charger();
            },
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mes artisans de confiance'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: MabokoCouleurs.secondaire,
        onRefresh: _charger,
        child: _corps(),
      ),
    );
  }

  Widget _corps() {
    if (_erreur != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          EtatErreur(message: _erreur!, onReessayer: _charger),
        ],
      );
    }

    if (_artisans == null) return const ChargementEnCours();

    if (_artisans!.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 60),
          EtatVide(
            icone: Icons.favorite_border_rounded,
            titre: 'Aucun artisan de confiance',
            message: 'Ajoutez un artisan à vos favoris depuis sa fiche pour le retrouver ici.',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _artisans!.length,
      itemBuilder: (contexte, i) {
        final artisan = _artisans![i];

        return Dismissible(
          key: ValueKey(artisan.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24, bottom: 12),
            decoration: BoxDecoration(
              color: MabokoCouleurs.danger,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.heart_broken_rounded, color: Colors.white),
          ),
          onDismissed: (_) => _retirer(artisan),
          child: GestureDetector(
            onTap: () => Navigator.push(
              contexte,
              MaterialPageRoute(builder: (_) => ArtisanProfileScreen(artisanId: artisan.id)),
            ),
            child: CarteArtisan(artisan: artisan),
          ),
        );
      },
    );
  }
}
