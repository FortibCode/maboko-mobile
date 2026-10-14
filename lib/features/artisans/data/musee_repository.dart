import '../../../core/network/api.dart';
import '../../../core/network/api_exception.dart';

/// Entrée du musée du savoir-faire (§5.1.7).
///
/// Le musée met en avant les meilleurs artisans, sélectionnés
/// automatiquement (note élevée, missions nombreuses) puis validés par
/// l'administration. Il ne contient que des entrées actives.
class ArtisanMusee {
  const ArtisanMusee({
    required this.id,
    required this.artisanId,
    required this.nomComplet,
    this.avatarUrl,
    this.ville,
    this.quartier,
    this.specialite,
    this.bio,
    this.zoneIntervention,
    this.noteMoyenne = 0,
    this.nbMissionsTerminees = 0,
    this.metiers = const [],
    this.ordre = 0,
  });

  /// Identifiant de l'entrée musée (pas celui de l'artisan).
  final int id;

  /// Identifiant de l'utilisateur artisan — pour ouvrir sa fiche.
  final int artisanId;

  final String nomComplet;
  final String? avatarUrl;
  final String? ville;
  final String? quartier;

  final String? specialite;
  final String? bio;
  final String? zoneIntervention;
  final double noteMoyenne;
  final int nbMissionsTerminees;

  /// Noms des métiers exercés (ex. : « Ébéniste », « Menuisier »).
  final List<String> metiers;

  final int ordre;

  factory ArtisanMusee.depuisJson(Map<String, dynamic> json) {
    final metiers = (json['metiers'] as List? ?? [])
        .map((m) => (m is Map ? m['nom'] as String? : m as String?) ?? '')
        .where((nom) => nom.isNotEmpty)
        .toList();

    return ArtisanMusee(
      id: json['id'] as int? ?? 0,
      artisanId: json['artisanId'] as int? ?? 0,
      nomComplet: (json['nomComplet'] as String?)?.trim() ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      ville: json['ville'] as String?,
      quartier: json['quartier'] as String?,
      specialite: json['specialite'] as String?,
      bio: json['bio'] as String?,
      zoneIntervention: json['zoneIntervention'] as String?,
      noteMoyenne: (json['noteMoyenne'] as num?)?.toDouble() ?? 0,
      nbMissionsTerminees: json['nbMissionsTerminees'] as int? ?? 0,
      metiers: metiers,
      ordre: json['ordre'] as int? ?? 0,
    );
  }
}

/// Accès à l'API du musée du savoir-faire.
class MuseeRepository {
  const MuseeRepository();

  /// Liste publique des artisans mis en avant.
  ///
  /// Renvoie une liste vide si le musée est vide — ce n'est pas une
  /// erreur, simplement l'absence de mise en avant.
  Future<List<ArtisanMusee>> artisans() async {
    try {
      final reponse = await api.get('/musee');

      final donnees = (reponse['data'] as List?) ?? [];

      return donnees
          .map((json) => ArtisanMusee.depuisJson(json as Map<String, dynamic>))
          .toList();
    } on ApiException {
      // On préfère une liste vide à une exception : l'écran du musée
      // affichera « musée vide » plutôt qu'un message d'erreur
      // anxiogène sur un contenu secondaire.
      return const [];
    }
  }
}