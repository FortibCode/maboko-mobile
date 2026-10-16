import 'package:flutter/material.dart';

import '../../../core/theme/maboko_theme.dart';
import '../models/metier.dart';
import 'icones_metiers.dart';

/// Visuel d'un métier.
///
/// Trois sources possibles, dans l'ordre de priorité :
///
/// 1. **Image locale** : `assets/images/metiers/{slug}.jpeg` — embarquée
///    avec l'application, disponible même hors ligne. C'est le visuel
///    par défaut livré avec l'app.
///
/// 2. **Image distante** : `metier.imageUrl` — déposée par l'administration
///    depuis le back-office. Prioritaire dès qu'elle existe, pour que
///    l'admin puisse mettre à jour le visuel sans reconstruire l'app.
///
/// 3. **Icône Material** : `iconeMetier(slug)` — solution de repli si
///    ni l'image locale ni l'image distante ne sont disponibles. Le
///    rendu reste présentable, jamais une case vide.
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

  /// Chemin local de l'image du métier, en `.jpeg`.
  String get _cheminLocal => 'assets/images/metiers/${metier.slug}.jpeg';

  /// Vrai si le back-office a déposé une image distante pour ce métier.
  bool get _aImageDistante =>
      metier.imageUrl != null && metier.imageUrl!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final sombre = context.sombre;

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
      child: _contenu(sombre),
    );
  }

  Widget _contenu(bool sombre) {
    // 1. Image distante — priorité si elle existe.
    if (_aImageDistante) {
      return Image.network(
        metier.imageUrl!,
        fit: BoxFit.cover,
        width: taille,
        height: taille,
        errorBuilder: (contexte, erreur, trace) => _fallbackLocal(sombre),
        loadingBuilder: (contexte, enfant, progression) =>
            progression == null ? enfant : _fallbackLocal(sombre),
      );
    }

    // 2. Image locale — fallback si pas d'image distante.
    return _fallbackLocal(sombre);
  }

  /// Charge l'image locale, ou l'icône si le fichier n'existe pas.
  Widget _fallbackLocal(bool sombre) {
    return Image.asset(
      _cheminLocal,
      fit: BoxFit.cover,
      width: taille,
      height: taille,
      errorBuilder: (contexte, erreur, trace) => _icone(sombre),
    );
  }

  /// Solution de repli ultime : une icône Material.
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