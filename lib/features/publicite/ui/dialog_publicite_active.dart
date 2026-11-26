import 'package:flutter/material.dart';

import '../../../core/theme/maboko_theme.dart';
import '../../../services/storage_service.dart';
import '../../artisans/ui/artisan_profile_screen.dart';
import '../data/publicite_repository.dart';
import '../models/publicite.dart';

/// Boîte de dialogue affichée au lancement de l'application (§5.1.7).
/// Met en avant un artisan ayant souscrit à une campagne publicitaire active.
class DialogPubliciteActive extends StatelessWidget {
  const DialogPubliciteActive({super.key, required this.publicite});

  final Publicite publicite;

  static const _depot = PubliciteRepository();

  /// Vérifie si une publicité active est disponible et l'affiche une fois par jour.
  static Future<void> verifierEtAfficher(BuildContext context) async {
    try {
      final dejaAffichee = await StorageService.pubAfficheeAujourdhui();
      if (dejaAffichee) return;

      final pub = await _depot.active();
      if (pub == null || !context.mounted) return;

      await StorageService.marquerPubAfficheeAujourdhui();

      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (_) => DialogPubliciteActive(publicite: pub),
      );
    } catch (_) {
      // Les publicités ne doivent jamais bloquer le démarrage de l'appli.
    }
  }

  void _ouvrirProfil(BuildContext context) {
    _depot.enregistrerClic(publicite.id);
    Navigator.pop(context);

    if (publicite.artisanId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArtisanProfileScreen(artisanId: publicite.artisanId!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      backgroundColor: context.surfaceMaboko,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Affiche / Image
          if (publicite.imageUrl != null && publicite.imageUrl!.isNotEmpty)
            Stack(
              children: [
                Image.network(
                  publicite.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: MabokoCouleurs.secondaire.withValues(alpha: 0.1),
                    child: const Center(
                      child: Icon(Icons.handyman_rounded, size: 40, color: MabokoCouleurs.secondaire),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 18),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade700,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded, size: 12, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'EN VEDETTE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: .5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre
                Text(
                  publicite.titre,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                if (publicite.description != null && publicite.description!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    publicite.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: context.texteSecondaireMaboko, height: 1.3),
                  ),
                ],
                const SizedBox(height: 14),

                // Informations de l'artisan
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.fondMaboko,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: MabokoCouleurs.secondaire.withValues(alpha: 0.1),
                        backgroundImage: publicite.avatarUrl != null && publicite.avatarUrl!.isNotEmpty
                            ? NetworkImage(publicite.avatarUrl!)
                            : null,
                        child: publicite.avatarUrl == null || publicite.avatarUrl!.isEmpty
                            ? const Icon(Icons.person, color: MabokoCouleurs.secondaire, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              publicite.nomComplet ?? 'Artisan partenaire',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              publicite.specialite ?? publicite.quartier ?? 'Artisan Maboko',
                              style: TextStyle(fontSize: 11.5, color: context.texteSecondaireMaboko),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (publicite.noteMoyenne > 0)
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text(
                              publicite.noteMoyenne.toStringAsFixed(1),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Plus tard',
                          style: TextStyle(color: context.texteSecondaireMaboko),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () => _ouvrirProfil(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MabokoCouleurs.secondaire,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text(
                          'Voir le profil',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
