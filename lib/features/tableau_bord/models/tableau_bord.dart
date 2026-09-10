import '../../artisans/models/artisan.dart';
import '../../demandes/models/demande.dart';

/// Compteurs d'un parcours : demandes côté client, missions côté artisan.
class Compteurs {
  const Compteurs({
    this.total = 0,
    this.enAttente = 0,
    this.enCours = 0,
    this.terminees = 0,
  });

  final int total;
  final int enAttente;
  final int enCours;
  final int terminees;

  factory Compteurs.depuisJson(Map<String, dynamic>? json) => Compteurs(
        total: json?['total'] as int? ?? 0,
        enAttente: json?['enAttente'] as int? ?? 0,
        enCours: json?['enCours'] as int? ?? 0,
        terminees: json?['terminees'] as int? ?? 0,
      );
}

/// Tableau de bord du compte connecté (§5.1.10 et §5.2.1).
///
/// Un seul modèle pour les deux rôles : l'API renvoie la forme adaptée,
/// les champs sans objet restent à leur valeur par défaut.
class TableauBord {
  const TableauBord({
    required this.role,
    required this.compteurs,
    this.ficheManquante = false,
    this.favoris = 0,
    this.avisDeposes = 0,
    this.montantEngage = 0,
    this.revenusTotal = 0,
    this.revenusMois = 0,
    this.revenusParMois = const [],
    this.noteMoyenne = 0,
    this.nbAvis = 0,
    this.badges = const [],
    this.plan,
    this.planFinLe,
    this.dernieresDemandes = const [],
  });

  final String role;
  final Compteurs compteurs;
  final bool ficheManquante;

  // Client
  final int favoris;
  final int avisDeposes;
  final double montantEngage;

  // Artisan
  final double revenusTotal;
  final double revenusMois;

  /// Douze mois glissants, pour le suivi graphique (§5.2.4).
  final List<({String mois, double total})> revenusParMois;
  final double noteMoyenne;
  final int nbAvis;
  final List<BadgeConfiance> badges;
  final String? plan;
  final String? planFinLe;

  final List<Demande> dernieresDemandes;

  bool get estArtisan => role == 'artisan';

  factory TableauBord.depuisJson(Map<String, dynamic> json) {
    final revenus = json['revenus'] as Map<String, dynamic>?;
    final abonnement = json['abonnement'] as Map<String, dynamic>?;

    return TableauBord(
      role: json['role'] as String? ?? 'client',
      ficheManquante: json['ficheManquante'] as bool? ?? false,
      compteurs: Compteurs.depuisJson(
        (json['missions'] ?? json['demandes']) as Map<String, dynamic>?,
      ),
      favoris: json['favoris'] as int? ?? 0,
      avisDeposes: json['avisDeposes'] as int? ?? 0,
      montantEngage: (json['montantEngage'] as num?)?.toDouble() ?? 0,
      revenusTotal: (revenus?['total'] as num?)?.toDouble() ?? 0,
      revenusParMois: ((revenus?['parMois'] as List?) ?? []).map((m) {
        final entree = m as Map<String, dynamic>;

        return (
          mois: entree['mois'] as String? ?? '',
          total: (entree['total'] as num?)?.toDouble() ?? 0,
        );
      }).toList(),
      revenusMois: (revenus?['moisCourant'] as num?)?.toDouble() ?? 0,
      noteMoyenne: (json['noteMoyenne'] as num?)?.toDouble() ?? 0,
      nbAvis: json['nbAvis'] as int? ?? 0,
      badges: ((json['badges'] as List?) ?? [])
          .map((b) => BadgeConfiance.depuisJson(b as Map<String, dynamic>))
          .toList(),
      plan: abonnement?['plan'] as String?,
      planFinLe: abonnement?['finLe'] as String?,
      dernieresDemandes: ((json['dernieresDemandes'] as List?) ?? [])
          .map((d) => Demande.depuisJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
