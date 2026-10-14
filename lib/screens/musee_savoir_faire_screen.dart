import 'package:flutter/material.dart';

import '../core/theme/maboko_theme.dart';
import '../core/widgets/etats.dart';
import '../features/artisans/data/musee_repository.dart';
import '../features/artisans/ui/artisan_profile_screen.dart';

/// Musée du savoir-faire (§5.1.7).
///
/// Galerie des artisans que l'équipe Maboko a choisi de mettre en avant :
/// note élevée, missions terminées, fiche validée. Le musée est alimenté
/// automatiquement côté serveur, sans intervention de l'utilisateur.
///
/// La sélection est prestigieuse : une dizaine d'artisans au maximum, triés
/// par ordre manuel puis par note. Le but est d'inspirer avant de
/// contacter, pas de remplacer l'onglet Découvrir.
class MuseeSavoirFaireScreen extends StatefulWidget {
  const MuseeSavoirFaireScreen({super.key});

  @override
  State<MuseeSavoirFaireScreen> createState() => _MuseeSavoirFaireScreenState();
}

class _MuseeSavoirFaireScreenState extends State<MuseeSavoirFaireScreen> {
  static const _depot = MuseeRepository();

  List<ArtisanMusee>? _artisans;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      final artisans = await _depot.artisans();
      if (!mounted) return;
      setState(() => _artisans = artisans);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erreur = 'Impossible de charger le musée.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Musée du savoir-faire'),
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
            icone: Icons.museum_outlined,
            titre: 'Le musée est encore vide',
            message: 'L\'équipe Maboko prépare la sélection des meilleurs '
                'artisans. Revenez bientôt pour découvrir leurs plus belles '
                'réalisations.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _encadre(),
        const SizedBox(height: 18),
        ..._artisans!.map((a) => _carte(a)),
      ],
    );
  }

  /// Bandeau d'introduction en haut de la page.
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
          const Icon(Icons.museum_outlined,
              size: 22, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Les artisans les mieux notés de Maboko, mis en avant pour la '
              'qualité de leur travail. Touchez une carte pour voir la fiche '
              'complète et contacter l\'artisan.',
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

  /// Carte d'un artisan du musée.
  Widget _carte(ArtisanMusee artisan) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: context.surfaceMaboko,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _ouvrirFiche(artisan),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: context.bordureMaboko,
                      backgroundImage: artisan.avatarUrl?.isNotEmpty == true
                          ? NetworkImage(artisan.avatarUrl!)
                          : null,
                      child: artisan.avatarUrl?.isNotEmpty == true
                          ? null
                          : const Icon(Icons.person,
                              color: MabokoCouleurs.secondaire, size: 26),
                    ),
                    const SizedBox(width: 12),

                    // Nom + spécialité + note
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artisan.nomComplet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (artisan.specialite != null)
                            Text(
                              artisan.specialite!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: context.texteSecondaireMaboko,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded,
                                  size: 15, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                artisan.noteMoyenne.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${artisan.nbMissionsTerminees} missions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.texteSecondaireMaboko,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Flèche
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Colors.grey),
                  ],
                ),

                // Métiers (chips)
                if (artisan.metiers.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: artisan.metiers.take(3).map((m) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: MabokoCouleurs.secondaire
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          m,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: MabokoCouleurs.secondaire,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],

                // Localisation
                if (artisan.ville != null || artisan.quartier != null) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 14, color: context.texteSecondaireMaboko),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [
                            artisan.quartier,
                            artisan.ville,
                          ].where((s) => s != null && s.isNotEmpty).join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: context.texteSecondaireMaboko,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ouvre la fiche complète de l'artisan.
  void _ouvrirFiche(ArtisanMusee artisan) {
    if (artisan.artisanId <= 0) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanProfileScreen(artisanId: artisan.artisanId),
      ),
    );
  }
}