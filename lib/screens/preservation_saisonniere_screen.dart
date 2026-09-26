import 'package:flutter/material.dart';

import '../core/theme/maboko_theme.dart';

/// Préservation saisonnière (§5.1.7).
///
/// Conseils pour protéger sa maison, ses meubles, ses outils et son
/// artisanat selon la saison. À Brazzaville et Pointe-Noire, la saison
/// des pluies abîme plus de choses que n'importe quel chantier — ce guide
/// dit quoi faire, quand, et pourquoi.
class PreservationSaisonniereScreen extends StatefulWidget {
  const PreservationSaisonniereScreen({super.key});

  @override
  State<PreservationSaisonniereScreen> createState() =>
      _PreservationSaisonniereScreenState();
}

class _PreservationSaisonniereScreenState
    extends State<PreservationSaisonniereScreen> {
  /// Saison active. Le widget la calcule une fois au démarrage ; l'utilisateur
  /// peut ensuite la changer pour consulter une autre saison.
  late Saison _saison = _saisonActuelle();

  /// Détermine la saison selon le mois.
  ///
  /// Au Congo, deux saisons bien marquées : la saison des pluies (octobre à
  /// mai) et la saison sèche (juin à septembre), entrecoupée d'une petite
  /// saison sèche en janvier-février.
  Saison _saisonActuelle() {
    final mois = DateTime.now().month;

    if (mois >= 10 || mois <= 5) return Saison.pluies;

    return Saison.seche;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Préservation saisonnière'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _selecteurSaison(context),
          const SizedBox(height: 18),
          _encadreSaison(context),
          const SizedBox(height: 20),
          _section(context, 'À protéger en priorité'),
          ..._blocs(),
        ],
      ),
    );
  }

  Widget _selecteurSaison(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.surfaceMaboko,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Row(
        children: Saison.values.map((s) {
          final actif = _saison == s;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _saison = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: actif ? s.couleur : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      s.icone,
                      size: 17,
                      color: actif ? Colors.white : context.texteSecondaireMaboko,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.libelle,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: actif ? Colors.white : context.texteSecondaireMaboko,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _encadreSaison(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _saison.couleur.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _saison.couleur.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_saison.icone, size: 22, color: _saison.couleur),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _saison.titre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: _saison.couleur,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _saison.description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: context.texteSecondaireMaboko,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        titre,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.texteSecondaireMaboko,
          letterSpacing: .3,
        ),
      ),
    );
  }

  List<Widget> _blocs() {
    return _saison.conseils
        .map<Widget>((c) => _carteConseil(c))
        .toList();
  }

  Widget _carteConseil(ConseilSaison conseil) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _saison.couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Icon(conseil.icone, color: _saison.couleur, size: 21),
          ),
          title: Text(
            conseil.titre,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              conseil.resume,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                conseil.details,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: context.texteSecondaireMaboko,
                ),
              ),
            ),
            if (conseil.frequence != null) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: _saison.couleur),
                  const SizedBox(width: 6),
                  Text(
                    conseil.frequence!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _saison.couleur,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saisons et conseils
// ---------------------------------------------------------------------------

enum Saison {
  pluies(
    libelle: 'Saison des pluies',
    titre: 'Octobre → Mai : l’eau s’infiltre partout',
    description:
        'Les averses sont violentes et rapprochées. L’humidité remonte du sol, '
        'les toits fatiguent, les meubles en bois gonflent. C’est la saison '
        'où les petits dégâts deviennent des gros si on attend.',
    icone: Icons.water_drop_rounded,
    couleur: Color(0xFF2A6FB0),
  ),
  seche(
    libelle: 'Saison sèche',
    titre: 'Juin → Septembre : la chaleur et la poussière',
    description:
        'Air sec, poussière fine, soleil direct. Le bois se fend, les joints '
        'craquent, la peinture pèle. L’entretien se fait maintenant pour '
        'éviter les grosses réparations en saison des pluies.',
    icone: Icons.wb_sunny_rounded,
    couleur: Color(0xFFE08B14),
  );

  const Saison({
    required this.libelle,
    required this.titre,
    required this.description,
    required this.icone,
    required this.couleur,
  });

  final String libelle;
  final String titre;
  final String description;
  final IconData icone;
  final Color couleur;

  List<ConseilSaison> get conseils => switch (this) {
        Saison.pluies => _conseilsPluies,
        Saison.seche => _conseilsSeche,
      };
}

const _conseilsPluies = <ConseilSaison>[
  ConseilSaison(
    icone: Icons.roofing_rounded,
    titre: 'Toiture et gouttières',
    resume: 'Vérifier avant que la première grosse pluie ne tombe.',
    details:
        'Montez vérifier les tôles : une vis manquante, une tôle soulevée, et '
        'l’eau entre. Nettoyez les gouttières : feuilles et sable les bouchent '
        'en quelques semaines, et l’eau déborde sur les murs. Vérifiez aussi '
        'les solins autour de la cheminée ou des évacuations.',
    frequence: 'Une fois par mois pendant la saison',
  ),
  ConseilSaison(
    icone: Icons.water_damage_rounded,
    titre: 'Murs et infiltrations',
    resume: 'Repérer les traces d’humidité avant que le plâtre ne tombe.',
    details:
        'Regardez les coins, le bas des murs, derrière les meubles lourds. '
        'Une tache sombre, une odeur de moisi, une peinture qui cloque : '
        'c’est de l’eau qui entre. Faites traiter rapidement — un mur '
        'atteint coûte dix fois plus cher à réparer qu’un mur surveillé.',
    frequence: 'Inspection toutes les deux semaines',
  ),
  ConseilSaison(
    icone: Icons.chair_rounded,
    titre: 'Meubles en bois',
    resume: 'Le bois gonfle, les tiroirs coincent, les pieds pourrissent.',
    details:
        'Éloignez les meubles des murs extérieurs (au moins 5 cm) pour laisser '
        'circuler l’air. Surélevez-les si le sol est carrelé et froid. Passez '
        'un chiffon légèrement huilé (huile de lin) sur les surfaces en bois '
        'brut tous les deux mois.',
    frequence: 'Tous les deux mois',
  ),
  ConseilSaison(
    icone: Icons.electrical_services_rounded,
    titre: 'Installations électriques',
    resume: 'L’eau et l’électricité ne font pas bon ménage.',
    details:
        'Vérifiez que les prises extérieures ont bien leur cache. Si une '
        'prise intérieure est proche d’une fenêtre, surveillez-la pendant les '
        'grosses averses. Un disjoncteur qui saute sans raison en saison des '
        'pluies signale souvent une infiltration dans un câble.',
    frequence: 'Avant chaque grosse pluie annoncée',
  ),
  ConseilSaison(
    icone: Icons.kitchen_rounded,
    titre: 'Outils et artisanat',
    resume: 'La rouille s’installe en quelques jours sur l’acier.',
    details:
        'Après chaque usage, essuyez les outils en acier et passez un chiffon '
        'huilé. Rangez-les suspendus plutôt qu’au sol. Pour l’artisanat '
        '(sculptures, instruments, paniers), gardez-le dans une pièce aérée, '
        'jamais dans un sac fermé.',
    frequence: 'Après chaque utilisation',
  ),
];

const _conseilsSeche = <ConseilSaison>[
  ConseilSaison(
    icone: Icons.forest_rounded,
    titre: 'Bois et menuiseries',
    resume: 'Le bois se fend et travaille à cause de la sécheresse.',
    details:
        'Nourrissez les meubles en bois avec une huile ou une cire tous les '
        'deux mois. Les portes et fenêtres en bois se rétractent : un léger '
        'jeu apparaît, c’est normal. Ne serrez pas les vis trop fort, vous '
        'fendriez le bois. Vérifiez les joints autour des vitres.',
    frequence: 'Tous les deux mois',
  ),
  ConseilSaison(
    icone: Icons.format_paint_rounded,
    titre: 'Peintures et enduits',
    resume: 'C’est la saison idéale pour repeindre.',
    details:
        'L’air sec fait sécher la peinture uniformément et évite les coulures. '
        'C’est le moment de refaire les murs intérieurs, de traiter les '
        'boiseries, de vérifier les crépis extérieurs. Évitez juste les heures '
        'les plus chaudes (12h–15h) : la peinture sèche trop vite et marque.',
    frequence: 'Une fois dans la saison',
  ),
  ConseilSaison(
    icone: Icons.cleaning_services_rounded,
    titre: 'Poussière et aération',
    resume: 'La poussière fine s’infiltre partout, surtout en fin de saison.',
    details:
        'Aérez tôt le matin (6h–9h), quand l’air est plus frais et moins '
        'chargé. Fermez les fenêtres l’après-midi. Passez un chiffon humide '
        'plutôt qu’un plumeau : ça fixe la poussière au lieu de la remettre '
        'en suspension. Pensez aux climatiseurs : nettoyez les filtres.',
    frequence: 'Aération quotidienne, nettoyage hebdomadaire',
  ),
  ConseilSaison(
    icone: Icons.local_florist_rounded,
    titre: 'Plantes et extérieurs',
    resume: 'Arroser tôt ou tard, jamais en plein soleil.',
    details:
        'Arrosez avant 8h ou après 18h : l’eau s’évapore moins. Paillez le '
        'pied des plantes pour garder l’humidité. Si vous avez une cour, '
        'nettoyez les caniveaux et les regards d’évacuation maintenant — '
        'ils seront prêts pour la première pluie.',
    frequence: 'Arrosage quotidien, curage une fois',
  ),
  ConseilSaison(
    icone: Icons.electrical_services_rounded,
    titre: 'Ventilation et climatisation',
    resume: 'Les appareils forcent plus quand il fait chaud.',
    details:
        'Nettoyez les filtres de climatisation : un filtre sale consomme plus '
        'et refroidit moins. Vérifiez que les ventilateurs sont bien fixés '
        '(les vibrations finissent par desserrer). Ne laissez pas un '
        'ventilateur tourner dans une pièce vide : c’est du gaspillage.',
    frequence: 'Nettoyage des filtres toutes les 2 semaines',
  ),
];

/// Conseil de préservation affiché dans un onglet de saison.
///
/// Classe **publique** : elle est utilisée comme type de retour par l'enum
/// `Saison`, qui est public. La rendre privée provoquait un avertissement
/// `library_private_types_in_public_api`.
class ConseilSaison {
  const ConseilSaison({
    required this.icone,
    required this.titre,
    required this.resume,
    required this.details,
    this.frequence,
  });

  final IconData icone;
  final String titre;
  final String resume;
  final String details;
  final String? frequence;
}