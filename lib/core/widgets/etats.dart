import 'package:flutter/material.dart';

import '../theme/maboko_theme.dart';

/// Indicateur de chargement aux couleurs de la plateforme.
class ChargementEnCours extends StatelessWidget {
  const ChargementEnCours({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: MabokoCouleurs.secondaire),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: const TextStyle(color: MabokoCouleurs.texteSecondaire)),
          ],
        ],
      ),
    );
  }
}

/// Écran vide : dit ce qu'il n'y a pas, et ce que l'utilisateur peut faire.
class EtatVide extends StatelessWidget {
  const EtatVide({
    super.key,
    required this.icone,
    required this.titre,
    this.message,
    this.action,
  });

  final IconData icone;
  final String titre;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icone, size: 56, color: MabokoCouleurs.bordure),
            const SizedBox(height: 16),
            Text(
              titre,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: MabokoCouleurs.texteSecondaire, height: 1.4),
              ),
            ],
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Erreur récupérable : explique ce qui s'est passé et propose de réessayer.
class EtatErreur extends StatelessWidget {
  const EtatErreur({super.key, required this.message, this.onReessayer});

  final String message;
  final VoidCallback? onReessayer;

  @override
  Widget build(BuildContext context) {
    return EtatVide(
      icone: Icons.cloud_off_rounded,
      titre: 'Chargement impossible',
      message: message,
      action: onReessayer == null
          ? null
          : OutlinedButton.icon(
              onPressed: onReessayer,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: MabokoCouleurs.secondaire,
                side: const BorderSide(color: MabokoCouleurs.secondaire),
              ),
            ),
    );
  }
}

/// Pastille de statut.
class PastilleStatut extends StatelessWidget {
  const PastilleStatut({super.key, required this.statut});

  final String statut;

  @override
  Widget build(BuildContext context) {
    final couleur = MabokoCouleurs.statut(statut);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: couleur.withValues(alpha: 0.4)),
      ),
      child: Text(
        MabokoCouleurs.libelleStatut(statut),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: couleur),
      ),
    );
  }
}

/// Étoiles de notation, lecture seule.
class Etoiles extends StatelessWidget {
  const Etoiles({super.key, required this.note, this.taille = 16});

  final double note;
  final double taille;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final rempli = note >= i + 1;
        final demi = !rempli && note > i;
        return Icon(
          demi ? Icons.star_half_rounded : (rempli ? Icons.star_rounded : Icons.star_outline_rounded),
          size: taille,
          color: MabokoCouleurs.accent,
        );
      }),
    );
  }
}
