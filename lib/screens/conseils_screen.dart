import 'package:flutter/material.dart';

import '../core/theme/maboko_theme.dart';

/// Conseils et assistances (§5.1.7).
///
/// Un client qui ne sait pas comment demander un devis, négocier un prix,
/// ou vérifier un artisan trouve ici des réponses courtes, classées par
/// thème. Aucune donnée n'est stockée : le contenu est embarqué dans
/// l'application pour rester lisible hors ligne.
class ConseilsScreen extends StatelessWidget {
  const ConseilsScreen({super.key});

  static const _themes = <_Theme>[
    _Theme(
      titre: 'Avant de contacter un artisan',
      icone: Icons.search_rounded,
      couleur: MabokoCouleurs.secondaire,
      conseils: [
        _Conseil(
          titre: 'Vérifiez le badge « Profil vérifié »',
          texte: 'Il garantit que la pièce d’identité de l’artisan a été '
              'contrôlée par l’équipe Maboko. C’est un premier filtre avant '
              'd’ouvrir votre porte à quelqu’un.',
        ),
        _Conseil(
          titre: 'Lisez les avis récents',
          texte: 'Un artisan avec vingt avis à 4,8 est plus rassurant qu’un '
              'artisan sans historique. Regardez surtout les commentaires, '
              'pas seulement la note.',
        ),
        _Conseil(
          titre: 'Regardez son portfolio',
          texte: 'Les photos de ses réalisations passées disent mieux son '
              'savoir-faire que n’importe quelle description. Demandez à voir '
              'un chantier similaire au vôtre.',
        ),
      ],
    ),
    _Theme(
      titre: 'Bien formuler sa demande',
      icone: Icons.edit_note_rounded,
      couleur: MabokoCouleurs.accent,
      conseils: [
        _Conseil(
          titre: 'Décrivez le problème, pas la solution',
          texte: '« Mon robinet fuit sous l’évier » vaut mieux que « venez '
              'changer le joint ». L’artisan choisira lui-même la meilleure '
              'méthode, parfois moins chère.',
        ),
        _Conseil(
          titre: 'Ajoutez une photo',
          texte: 'Une photo nette du problème évite trois allers-retours. '
              'Prenez-la en pleine lumière, avec un objet pour l’échelle.',
        ),
        _Conseil(
          titre: 'Précisez votre localisation',
          texte: 'Le quartier et un point de repère suffisent. Un artisan '
              'qui met une heure à vous trouver facturera ce temps.',
        ),
      ],
    ),
    _Theme(
      titre: 'Prix et paiement',
      icone: Icons.payments_outlined,
      couleur: MabokoCouleurs.succes,
      conseils: [
        _Conseil(
          titre: 'Demandez toujours un devis écrit',
          texte: 'Le devis reçu dans l’application fait foi. Refusez les '
              'arrangements uniquement à l’oral : en cas de litige, vous '
              'n’aurez aucune preuve.',
        ),
        _Conseil(
          titre: 'Méfiez-vous des acomptes trop élevés',
          texte: 'Un acompte de 30 % à la commande est courant. Au-delà de '
              '50 %, demandez pourquoi et faites préciser le calendrier.',
        ),
        _Conseil(
          titre: 'Payez par Mobile Money',
          texte: 'Le paiement via l’application laisse une trace. Évitez les '
              'espèces pour les montants importants : en cas de problème, '
              'vous n’avez aucun recours.',
        ),
      ],
    ),
    _Theme(
      titre: 'En cas de problème',
      icone: Icons.report_problem_outlined,
      couleur: MabokoCouleurs.danger,
      conseils: [
        _Conseil(
          titre: 'Signalez dans l’application',
          texte: 'Chaque demande a un bouton « Signaler ». L’équipe Maboko '
              'regarde le dossier sous 48 heures et peut suspendre l’artisan '
              'le temps de l’enquête.',
        ),
        _Conseil(
          titre: 'Gardez les échanges',
          texte: 'Ne supprimez pas la conversation avec l’artisan : elle '
              'sert de preuve en cas de désaccord sur ce qui a été promis.',
        ),
        _Conseil(
          titre: 'Ne réglez jamais un litige en privé',
          texte: 'Un artisan qui vous propose d’annuler la demande dans '
              'l’application pour régler « entre vous » vous prive de toute '
              'protection. Refusez systématiquement.',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Conseils et assistances'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _encadre(context),
          const SizedBox(height: 20),
          ..._themes.map((t) => _bloc(context, t)),
        ],
      ),
    );
  }

  Widget _encadre(BuildContext context) {
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
          const Icon(Icons.lightbulb_outline_rounded, size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Des réponses courtes aux questions les plus fréquentes. '
              'Disponibles hors ligne, sans consommer de données.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: context.texteSecondaireMaboko),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloc(BuildContext context, _Theme theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Theme(
        // Les ExpansionTile héritent d'un fond gris par défaut : on le rend
        // transparent pour rester cohérent avec la carte.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(theme.icone, color: theme.couleur, size: 20),
          ),
          title: Text(
            theme.titre,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          children: theme.conseils
              .map((c) => Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: theme.couleur,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.titre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            c.texte,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: context.texteSecondaireMaboko,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Données
// ---------------------------------------------------------------------------

class _Theme {
  const _Theme({
    required this.titre,
    required this.icone,
    required this.couleur,
    required this.conseils,
  });

  final String titre;
  final IconData icone;
  final Color couleur;
  final List<_Conseil> conseils;
}

class _Conseil {
  const _Conseil({required this.titre, required this.texte});

  final String titre;
  final String texte;
}