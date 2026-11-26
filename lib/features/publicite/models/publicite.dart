/// Modèle d'une publicité (§5.1.7).
class Publicite {
  const Publicite({
    required this.id,
    required this.titre,
    this.description,
    this.imageUrl,
    this.artisanId,
    this.nomComplet,
    this.avatarUrl,
    this.ville,
    this.quartier,
    this.specialite,
    this.noteMoyenne = 0,
    this.nbMissionsTerminees = 0,
    this.statut = 'desactivee',
    this.joursRestants = 0,
    this.actif = false,
    this.nbAffichages = 0,
    this.nbClics = 0,
    this.creeLe,
  });

  final int id;
  final String titre;
  final String? description;
  final String? imageUrl;
  final int? artisanId;
  final String? nomComplet;
  final String? avatarUrl;
  final String? ville;
  final String? quartier;
  final String? specialite;
  final double noteMoyenne;
  final int nbMissionsTerminees;
  final String statut;
  final int joursRestants;
  final bool actif;
  final int nbAffichages;
  final int nbClics;
  final DateTime? creeLe;

  bool get estEnLigne => statut == 'active' && actif;
  bool get estEnAttente => statut == 'en_attente' || (!actif && statut != 'terminee');

  factory Publicite.depuisJson(Map<String, dynamic> json) {
    return Publicite(
      id: json['id'] as int? ?? 0,
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      artisanId: json['artisanId'] as int?,
      nomComplet: json['nomComplet'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      ville: json['ville'] as String?,
      quartier: json['quartier'] as String?,
      specialite: json['specialite'] as String?,
      noteMoyenne: (json['noteMoyenne'] as num?)?.toDouble() ?? 0,
      nbMissionsTerminees: json['nbMissionsTerminees'] as int? ?? 0,
      statut: json['statut'] as String? ?? 'desactivee',
      joursRestants: json['joursRestants'] as int? ?? 0,
      actif: json['actif'] as bool? ?? false,
      nbAffichages: json['nbAffichages'] as int? ?? 0,
      nbClics: json['nbClics'] as int? ?? 0,
      creeLe: DateTime.tryParse(json['creeLe'] as String? ?? ''),
    );
  }
}
