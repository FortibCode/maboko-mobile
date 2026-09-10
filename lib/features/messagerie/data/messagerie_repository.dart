import '../../../core/network/api.dart';
import '../models/conversation.dart';

class MessagerieRepository {
  const MessagerieRepository();

  Future<List<Conversation>> conversations() async {
    final reponse = await api.get('/conversations');

    return ((reponse['data'] as List?) ?? [])
        .map((c) => Conversation.depuisJson(c as Map<String, dynamic>))
        .toList();
  }

  /// Ouvre le fil avec un interlocuteur, ou récupère l'existant.
  Future<Conversation> ouvrir({int? interlocuteurId, int? demandeId}) async {
    final reponse = await api.post('/conversations', corps: {
      if (interlocuteurId != null) 'interlocuteur_id': interlocuteurId,
      if (demandeId != null) 'demande_id': demandeId,
    });

    return Conversation.depuisJson(reponse['conversation'] as Map<String, dynamic>);
  }

  Future<Conversation> support() async {
    final reponse = await api.get('/conversations/support');

    return Conversation.depuisJson(reponse['conversation'] as Map<String, dynamic>);
  }

  /// Messages du plus récent au plus ancien, comme les renvoie l'API.
  Future<List<MessageChat>> messages(int conversationId) async {
    final reponse = await api.get('/conversations/$conversationId/messages');

    return ((reponse['data'] as List?) ?? [])
        .map((m) => MessageChat.depuisJson(m as Map<String, dynamic>))
        .toList();
  }

  /// Envoi d'un message : du texte, une photo, ou les deux.
  ///
  /// L'API acceptait un media depuis le debut ; la conversation savait
  /// l'afficher mais pas en envoyer un.
  Future<MessageChat> envoyer(
    int conversationId,
    String contenu, {
    String? media,
  }) async {
    final reponse = await api.post(
      '/conversations/$conversationId/messages',
      corps: {
        if (contenu.isNotEmpty) 'contenu': contenu,
        if (media != null) 'media': media,
      },
    );

    return MessageChat.depuisJson(reponse['donnees'] as Map<String, dynamic>);
  }

  Future<void> marquerLu(int conversationId) async {
    await api.post('/conversations/$conversationId/lu');
  }
}
