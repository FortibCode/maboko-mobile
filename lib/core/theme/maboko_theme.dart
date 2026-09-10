import 'package:flutter/material.dart';

/// Charte graphique Maboko (§VIII du cahier de charges).
class MabokoCouleurs {
  const MabokoCouleurs._();

  /// Marron foncé — couleur principale.
  static const Color principale = Color(0xFF4A2A18);

  /// Terre de Sienne / cuivré — couleur secondaire.
  static const Color secondaire = Color(0xFFB35B28);

  /// Jaune safran / doré — accent.
  static const Color accent = Color(0xFFEAA023);

  /// Crème / beige clair — fond.
  static const Color fond = Color(0xFFFAF4E7);

  static const Color surface = Colors.white;
  static const Color texteSecondaire = Color(0xFF7A6A5C);
  static const Color bordure = Color(0xFFE8DCC8);
  static const Color succes = Color(0xFF5F7548);
  static const Color danger = Color(0xFF9E2B22);

  /// Couleur associée à un statut de demande de devis.
  static Color statut(String statut) => switch (statut) {
        'en_attente' => accent,
        'acceptee' => secondaire,
        'en_cours' => principale,
        'terminee' => succes,
        'refusee' || 'annulee' => danger,
        _ => texteSecondaire,
      };

  /// Libellé lisible d'un statut.
  static String libelleStatut(String statut) => switch (statut) {
        'en_attente' => 'En attente',
        'acceptee' => 'Acceptée',
        'en_cours' => 'En cours',
        'terminee' => 'Terminée',
        'refusee' => 'Refusée',
        'annulee' => 'Annulée',
        _ => statut,
      };
}

/// Formate un montant en francs CFA : 195000 → « 195 000 FCFA ».
String formaterFcfa(num? montant) {
  if (montant == null) return '—';

  final entier = montant.round().toString();
  final tampon = StringBuffer();

  for (var i = 0; i < entier.length; i++) {
    if (i > 0 && (entier.length - i) % 3 == 0) tampon.write(' ');
    tampon.write(entier[i]);
  }

  return '${tampon.toString()} FCFA';
}

/// Couleurs qui dépendent du thème actif.
///
/// La charte ci-dessus est figée en clair : « fond » est un crème, « bordure »
/// un beige, « surface » du blanc. Posées telles quelles en mode sombre, elles
/// repeignent des cartes en blanc sur un écran noir. Ces raccourcis renvoient
/// l'équivalent du mode courant, et gardent la même intention visuelle.
extension MabokoContexte on BuildContext {
  bool get sombre => Theme.of(this).brightness == Brightness.dark;

  /// Fond d'écran général.
  Color get fondMaboko => Theme.of(this).scaffoldBackgroundColor;

  /// Fond d'une carte posée sur ce fond.
  Color get surfaceMaboko => Theme.of(this).cardColor;

  /// Trait de séparation ou contour de carte.
  Color get bordureMaboko => Theme.of(this).dividerColor;

  /// Texte d'appoint : légendes, métadonnées, libellés de champs.
  Color get texteSecondaireMaboko =>
      sombre ? const Color(0xFFB3A499) : MabokoCouleurs.texteSecondaire;

  /// Texte affirmé : titre de pastille, libellé de badge, corps d'un
  /// commentaire. En clair c'est le marron de la charte ; en sombre ce
  /// marron disparaît dans le fond, il faut son inverse.
  Color get texteFortMaboko =>
      sombre ? const Color(0xFFF0E4D8) : MabokoCouleurs.principale;

  /// Aplat discret *à l'intérieur* d'une carte : pastille, tuile d'icône,
  /// champ de saisie. En clair c'est le crème de la charte ; en sombre, un
  /// cran au-dessus de la carte plutôt qu'un cran en dessous.
  Color get teinteMaboko =>
      sombre ? const Color(0xFF2E251F) : MabokoCouleurs.fond;
}
