/// Badge de confiance obtenu par un artisan (§4.5).
///
/// Nommé « BadgeConfiance » et non « Badge » : Material expose déjà un
/// widget de ce nom, et la collision rendait les imports ambigus.
class BadgeConfiance {
  const BadgeConfiance({required this.slug, required this.nom, this.description});

  final String slug;
  final String nom;
  final String? description;

  factory BadgeConfiance.depuisJson(Map<String, dynamic> json) => BadgeConfiance(
        slug: json['slug'] as String? ?? '',
        nom: json['nom'] as String? ?? '',
        description: json['description'] as String?,
      );
}

/// Avis laissé par un client.
class Avis {
  const Avis({
    required this.id,
    required this.note,
    this.commentaire,
    this.auteur,
    this.publieLe,
  });

  final int id;
  final int note;
  final String? commentaire;
  final String? auteur;
  final DateTime? publieLe;

  factory Avis.depuisJson(Map<String, dynamic> json) {
    final auteur = json['auteur'] as Map<String, dynamic>?;

    return Avis(
      id: json['id'] as int,
      note: json['note'] as int,
      commentaire: json['commentaire'] as String?,
      auteur: auteur?['nomComplet'] as String?,
      publieLe: DateTime.tryParse(json['publieLe'] as String? ?? ''),
    );
  }
}

/// Fiche artisan telle que la consulte un client (§5.1.6).
class Artisan {
  const Artisan({
    required this.id,
    required this.utilisateurId,
    required this.nomComplet,
    required this.specialite,
    this.bio,
    this.avatarUrl,
    this.adresse,
    this.zoneIntervention,
    this.quartier,
    this.noteMoyenne = 0,
    this.nbAvis = 0,
    this.nbMissionsTerminees = 0,
    this.metiers = const [],
    this.badges = const [],
    this.avis = const [],
    this.plan,
    this.distanceKm,
  });

  /// Identifiant de la fiche artisan.
  final int id;

  /// Identifiant du compte utilisateur derrière la fiche.
  /// La messagerie s'adresse à un utilisateur, pas à une fiche.
  final int utilisateurId;

  final String nomComplet;
  final String specialite;
  final String? bio;
  final String? avatarUrl;
  final String? adresse;
  final String? zoneIntervention;
  final String? quartier;
  final double noteMoyenne;
  final int nbAvis;
  final int nbMissionsTerminees;
  final List<String> metiers;
  final List<BadgeConfiance> badges;
  final List<Avis> avis;
  final String? plan;
  final double? distanceKm;

  bool get estMisEnAvant => plan != null && plan != 'gratuit';

  factory Artisan.depuisJson(Map<String, dynamic> json) {
    final utilisateur = json['utilisateur'] as Map<String, dynamic>?;

    return Artisan(
      id: json['id'] as int,
      utilisateurId: utilisateur?['id'] as int? ?? 0,
      nomComplet: (utilisateur?['nomComplet'] as String?)?.trim().isNotEmpty == true
          ? utilisateur!['nomComplet'] as String
          : 'Artisan Maboko',
      specialite: json['specialite'] as String? ?? '',
      bio: json['bio'] as String?,
      avatarUrl: utilisateur?['avatarUrl'] as String?,
      adresse: json['adresse'] as String?,
      zoneIntervention: json['zoneIntervention'] as String?,
      quartier: utilisateur?['quartier'] as String?,
      noteMoyenne: (json['noteMoyenne'] as num?)?.toDouble() ?? 0,
      nbAvis: json['nbAvis'] as int? ?? 0,
      nbMissionsTerminees: json['nbMissionsTerminees'] as int? ?? 0,
      metiers: ((json['metiers'] as List?) ?? [])
          .map((m) => (m as Map<String, dynamic>)['nom'] as String)
          .toList(),
      badges: ((json['badges'] as List?) ?? [])
          .map((b) => BadgeConfiance.depuisJson(b as Map<String, dynamic>))
          .toList(),
      avis: ((json['avis'] as List?) ?? [])
          .map((a) => Avis.depuisJson(a as Map<String, dynamic>))
          .toList(),
      plan: json['plan'] as String?,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }
}
