/// Auteur d'une publication ou d'une story.
class AuteurPublication {
  const AuteurPublication({
    required this.id,
    required this.nomComplet,
    this.avatarUrl,
    this.metier,
  });

  final int id;
  final String nomComplet;
  final String? avatarUrl;
  final String? metier;

  factory AuteurPublication.depuisJson(Map<String, dynamic>? json) => AuteurPublication(
        id: json?['id'] as int? ?? 0,
        nomComplet: (json?['nomComplet'] as String?)?.trim().isNotEmpty == true
            ? json!['nomComplet'] as String
            : 'Artisan Maboko',
        avatarUrl: json?['avatarUrl'] as String?,
        metier: json?['metier'] as String?,
      );
}

/// Publication du fil d'actualité (§5.1.4).
class Publication {
  Publication({
    required this.id,
    required this.auteur,
    required this.medias,
    required this.description,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.publieLe,
  });

  final int id;
  final AuteurPublication auteur;
  final List<String> medias;
  final String description;

  // Mutables : le like et le commentaire se répercutent immédiatement à
  // l'écran, sans recharger tout le fil.
  int likesCount;
  int commentsCount;
  bool isLiked;

  final DateTime? publieLe;

  String? get premierMedia => medias.isEmpty ? null : medias.first;

  factory Publication.depuisJson(Map<String, dynamic> json) => Publication(
        id: json['id'] as int,
        auteur: AuteurPublication.depuisJson(json['auteur'] as Map<String, dynamic>?),
        medias: ((json['medias'] as List?) ?? [])
            .map((m) => m.toString())
            .where((m) => m.isNotEmpty)
            .toList(),
        description: json['description'] as String? ?? '',
        likesCount: json['likesCount'] as int? ?? 0,
        commentsCount: json['commentsCount'] as int? ?? 0,
        isLiked: json['isLiked'] as bool? ?? false,
        publieLe: DateTime.tryParse(json['publieLe'] as String? ?? ''),
      );
}

/// Story : mise en avant d'un travail récent, visible 24 heures.
class StoryItem {
  const StoryItem({
    required this.id,
    required this.auteur,
    required this.mediaUrl,
    this.legende,
  });

  final int id;
  final AuteurPublication auteur;
  final String mediaUrl;
  final String? legende;

  factory StoryItem.depuisJson(Map<String, dynamic> json) => StoryItem(
        id: json['id'] as int,
        auteur: AuteurPublication.depuisJson(json['auteur'] as Map<String, dynamic>?),
        mediaUrl: json['mediaUrl'] as String? ?? '',
        legende: json['legende'] as String?,
      );
}

/// Commentaire sur une publication.
class Commentaire {
  const Commentaire({
    required this.id,
    required this.contenu,
    required this.auteurNom,
    this.auteurAvatar,
    this.publieLe,
  });

  final int id;
  final String contenu;
  final String auteurNom;
  final String? auteurAvatar;
  final DateTime? publieLe;

  factory Commentaire.depuisJson(Map<String, dynamic> json) {
    final auteur = json['auteur'] as Map<String, dynamic>?;

    return Commentaire(
      id: json['id'] as int,
      contenu: json['contenu'] as String? ?? '',
      auteurNom: (auteur?['nomComplet'] as String?)?.trim().isNotEmpty == true
          ? auteur!['nomComplet'] as String
          : 'Utilisateur Maboko',
      auteurAvatar: auteur?['avatarUrl'] as String?,
      publieLe: DateTime.tryParse(json['publieLe'] as String? ?? ''),
    );
  }
}
