import 'package:flutter/material.dart';

import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../models/artisan.dart';
import 'artisan_profile_screen.dart';
import '../../../core/widgets/carte_pressable.dart';

/// Ligne de résultat de recherche : ce qu'un client voit avant d'ouvrir
/// la fiche complète.
class CarteArtisan extends StatelessWidget {
  const CarteArtisan({super.key, required this.artisan});

  final Artisan artisan;

  @override
  Widget build(BuildContext context) {
    return CartePressable(
      echelle: 0.985,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ArtisanProfileScreen(artisanId: artisan.id)),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ArtisanProfileScreen(artisanId: artisan.id)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 27,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  backgroundImage: artisan.avatarUrl != null && artisan.avatarUrl!.isNotEmpty
                      ? NetworkImage(artisan.avatarUrl!)
                      : null,
                  child: artisan.avatarUrl == null || artisan.avatarUrl!.isEmpty
                      ? const Icon(Icons.handyman_rounded, color: MabokoCouleurs.secondaire)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              artisan.nomComplet,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                            ),
                          ),
                          if (artisan.estMisEnAvant)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: MabokoCouleurs.accent.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                artisan.plan!.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF9A6A0F),
                                  letterSpacing: .5,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artisan.metiers.isNotEmpty ? artisan.metiers.join(' · ') : artisan.specialite,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12.5, color: MabokoCouleurs.secondaire),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Etoiles(note: artisan.noteMoyenne, taille: 14),
                          const SizedBox(width: 6),
                          Text(
                            artisan.nbAvis == 0
                                ? 'Pas encore d’avis'
                                : '${artisan.noteMoyenne.toStringAsFixed(1)} (${artisan.nbAvis})',
                            style: TextStyle(fontSize: 11.5, color: context.texteSecondaireMaboko),
                          ),
                          if (artisan.distanceKm != null) ...[
                            const SizedBox(width: 10),
                            Icon(Icons.place_outlined, size: 13, color: context.texteSecondaireMaboko),
                            Text(
                              ' ${artisan.distanceKm!.toStringAsFixed(1)} km',
                              style: TextStyle(fontSize: 11.5, color: context.texteSecondaireMaboko),
                            ),
                          ],
                        ],
                      ),
                      if (artisan.badges.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: artisan.badges
                              .take(3)
                              .map((b) => _PuceBadge(libelle: b.nom))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _PuceBadge extends StatelessWidget {
  const _PuceBadge({required this.libelle});

  final String libelle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: context.teinteMaboko,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_rounded, size: 11, color: MabokoCouleurs.secondaire),
          const SizedBox(width: 4),
          Text(
            libelle,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: context.texteFortMaboko),
          ),
        ],
      ),
    );
  }
}
