import 'package:flutter/material.dart';

import '../../../core/theme/maboko_theme.dart';
import '../models/metier.dart';
import 'icones_metiers.dart';

/// Visuel d'un métier : sa photo quand l'administration en a déposé une,
/// son icône sinon.
///
/// Les écrans montraient toujours un pictogramme. Une photo de chantier ou
/// d'atelier dit bien mieux ce qu'un métier recouvre, mais elle n'existe pas
/// forcément pour chaque métier — et le référentiel s'enrichit depuis le
/// back-office. Le repli doit donc rester présentable, jamais une case vide
/// ni une image cassée.
class VisuelMetier extends StatelessWidget {
  const VisuelMetier({
    super.key,
    required this.metier,
    required this.taille,
    this.rayon = 20,
    this.tailleIcone,
  });

  final Metier metier;
  final double taille;
  final double rayon;
  final double? tailleIcone;

  @override
  Widget build(BuildContext context) {
    final sombre = context.sombre;
    final aUnePhoto = metier.imageUrl != null && metier.imageUrl!.isNotEmpty;

    return Container(
      width: taille,
      height: taille,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.surfaceMaboko,
        borderRadius: BorderRadius.circular(rayon),
        border: Border.all(
          color: MabokoCouleurs.secondaire.withValues(alpha: sombre ? 0.35 : 0.18),
        ),
      ),
      child: aUnePhoto
          ? Image.network(
              metier.imageUrl!,
              fit: BoxFit.cover,
              width: taille,
              height: taille,
              errorBuilder: (contexte, erreur, trace) => _icone(sombre),
              loadingBuilder: (contexte, enfant, progression) =>
                  progression == null ? enfant : _icone(sombre),
            )
          : _icone(sombre),
    );
  }

  Widget _icone(bool sombre) {
    return Center(
      child: Icon(
        iconeMetier(metier.slug),
        color: sombre ? MabokoCouleurs.accent : MabokoCouleurs.secondaire,
        size: tailleIcone ?? taille * 0.44,
      ),
    );
  }
}
