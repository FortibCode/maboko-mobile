import 'package:flutter/material.dart';

import '../../../core/theme/maboko_theme.dart';

/// Suivi graphique des revenus mensuels (§5.2.4).
///
/// Dessiné à la main plutôt qu'avec une bibliothèque : douze barres ne
/// justifient pas une dépendance supplémentaire à télécharger sur une
/// connexion lente.
class GraphiqueRevenus extends StatelessWidget {
  const GraphiqueRevenus({super.key, required this.serie});

  final List<({String mois, double total})> serie;

  static const _moisCourts = [
    'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
    'juil', 'août', 'sep', 'oct', 'nov', 'déc',
  ];

  String _libelle(String mois) {
    final morceaux = mois.split('-');
    if (morceaux.length != 2) return mois;

    final numero = int.tryParse(morceaux[1]) ?? 0;

    return numero >= 1 && numero <= 12 ? _moisCourts[numero - 1] : mois;
  }

  @override
  Widget build(BuildContext context) {
    if (serie.isEmpty) return const SizedBox.shrink();

    final maximum = serie.map((m) => m.total).fold<double>(0, (a, b) => a > b ? a : b);
    final sombre = Theme.of(context).brightness == Brightness.dark;

    // Aucun mois facturé : une rangée de barres à zéro ne dit rien, on
    // explique plutôt ce qui remplira ce graphique.
    if (maximum <= 0) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          'Vos revenus des douze derniers mois apparaîtront ici,\n'
          'au fur et à mesure des missions terminées.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, height: 1.5, color: context.texteSecondaireMaboko),
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < serie.length; i++)
            Expanded(
              child: _barre(
                context: context,
                mois: serie[i],
                maximum: maximum,
                dernier: i == serie.length - 1,
                sombre: sombre,
              ),
            ),
        ],
      ),
    );
  }

  Widget _barre({
    required BuildContext context,
    required ({String mois, double total}) mois,
    required double maximum,
    required bool dernier,
    required bool sombre,
  }) {
    final ratio = (mois.total / maximum).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Le mois courant se distingue : c'est celui qu'on regarde.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (contexte, valeur, _) => Container(
              height: (110 * valeur).clamp(mois.total > 0 ? 4 : 2, 110),
              decoration: BoxDecoration(
                color: dernier
                    ? MabokoCouleurs.secondaire
                    : MabokoCouleurs.secondaire.withValues(alpha: sombre ? 0.45 : 0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _libelle(mois.mois),
            maxLines: 1,
            overflow: TextOverflow.clip,
            style: TextStyle(
              fontSize: 9,
              fontWeight: dernier ? FontWeight.bold : FontWeight.normal,
              color: dernier ? MabokoCouleurs.secondaire : context.texteSecondaireMaboko,
            ),
          ),
        ],
      ),
    );
  }
}
