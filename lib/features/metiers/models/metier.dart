/// Un métier du référentiel Maboko (§4.1).
class Metier {
  const Metier({
    required this.id,
    required this.nom,
    required this.slug,
    this.icone,
    this.imageUrl,
    this.description,
    this.nbArtisans = 0,
  });

  final int id;
  final String nom;
  final String slug;
  final String? icone;

  /// Photo réelle du métier, déposée depuis le back-office. Nulle tant qu'il
  /// n'y en a pas : l'affichage retombe alors sur l'icône.
  final String? imageUrl;

  final String? description;
  final int nbArtisans;

  factory Metier.depuisJson(Map<String, dynamic> json) {
    return Metier(
      id: json['id'] as int,
      nom: json['nom'] as String,
      slug: json['slug'] as String,
      icone: json['icone'] as String?,
      imageUrl: (json['imageUrl'] as String?)?.trim(),
      description: json['description'] as String?,
      nbArtisans: json['nbArtisans'] as int? ?? 0,
    );
  }
}
