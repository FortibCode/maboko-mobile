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
