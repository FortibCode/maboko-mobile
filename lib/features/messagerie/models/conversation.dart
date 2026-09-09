/// Interlocuteur d'une conversation.
class Interlocuteur {
  const Interlocuteur({required this.nomComplet, this.id, this.avatarUrl, this.role});

  final int? id;
  final String nomComplet;
  final String? avatarUrl;
  final String? role;

  factory Interlocuteur.depuisJson(Map<String, dynamic>? json) => Interlocuteur(
        id: json?['id'] as int?,
        nomComplet: (json?['nomComplet'] as String?)?.trim().isNotEmpty == true
            ? json!['nomComplet'] as String
            : 'Support Maboko',
        avatarUrl: json?['avatarUrl'] as String?,
        role: json?['role'] as String?,
      );
}

/// Conversation de la messagerie (§5.1.9).
class Conversation {
  Conversation({
    required this.id,
    required this.interlocuteur,
    this.estSupport = false,
    this.dernierMessage,
    this.dernierMessageLe,
    this.nonLus = 0,
    this.demandeId,
  });

  final int id;
  final Interlocuteur interlocuteur;
  final bool estSupport;
  final String? dernierMessage;
  final DateTime? dernierMessageLe;
  final int? demandeId;

  /// Mutable : passe à zéro dès l'ouverture du fil, sans recharger la liste.
  int nonLus;

  factory Conversation.depuisJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as int,
        interlocuteur: Interlocuteur.depuisJson(json['interlocuteur'] as Map<String, dynamic>?),
        estSupport: json['estSupport'] as bool? ?? false,
        dernierMessage: json['dernierMessage'] as String?,
        dernierMessageLe: DateTime.tryParse(json['dernierMessageLe'] as String? ?? ''),
        nonLus: json['nonLus'] as int? ?? 0,
        demandeId: json['demandeId'] as int?,
      );
}

/// Message d'une conversation.
class MessageChat {
  const MessageChat({
    required this.id,
    required this.expediteurId,
    required this.deMoi,
    this.contenu,
    this.mediaUrl,
    this.envoyeLe,
  });

  final int id;
  final int expediteurId;
  final bool deMoi;
  final String? contenu;
  final String? mediaUrl;
  final DateTime? envoyeLe;

  factory MessageChat.depuisJson(Map<String, dynamic> json, {int? moiId}) {
    final expediteur = json['expediteur'] as Map<String, dynamic>?;
    final expediteurId = expediteur?['id'] as int? ?? 0;

    return MessageChat(
      id: json['id'] as int,
      expediteurId: expediteurId,
      // « deMoi » n'est pas fourni par la diffusion temps réel, qui ne connaît
      // pas son destinataire : on le déduit alors de l'expéditeur.
      deMoi: json['deMoi'] as bool? ?? (moiId != null && moiId == expediteurId),
      contenu: json['contenu'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      envoyeLe: DateTime.tryParse(json['envoyeLe'] as String? ?? ''),
    );
  }
}
