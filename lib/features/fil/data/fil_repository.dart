import '../../../core/network/api.dart';
import '../models/publication.dart';

class FilRepository {
  const FilRepository();

  /// Fil d'actualité. `abonnements` restreint aux artisans suivis ; sans
  /// abonnement, l'API bascule d'elle-même sur toute la plateforme.
  Future<List<Publication>> publications({bool abonnements = false}) async {
    final reponse = await api.get(
      '/posts',
      parametres: {if (abonnements) 'abonnements': '1'},
    );

    return ((reponse['data'] as List?) ?? [])
        .map((p) => Publication.depuisJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<List<StoryItem>> stories() async {
    final reponse = await api.get('/stories');

    return ((reponse['data'] as List?) ?? [])
        .map((s) => StoryItem.depuisJson(s as Map<String, dynamic>))
        .toList();
  }

  /// Bascule le like. Retourne l'état et le compteur mis à jour par le serveur.
  Future<({bool aime, int likesCount})> basculerLike(int postId) async {
    final reponse = await api.post('/posts/$postId/like');

    return (
      aime: reponse['aime'] as bool? ?? false,
      likesCount: reponse['likesCount'] as int? ?? 0,
    );
  }

  Future<List<Commentaire>> commentaires(int postId) async {
    final reponse = await api.get('/posts/$postId/commentaires');

    return ((reponse['data'] as List?) ?? [])
        .map((c) => Commentaire.depuisJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<Commentaire> commenter(int postId, String contenu) async {
    final reponse = await api.post('/posts/$postId/commentaires', corps: {'contenu': contenu});

    return Commentaire.depuisJson(reponse['commentaire'] as Map<String, dynamic>);
  }

  Future<void> publier({
    required String metier,
    required String description,
    required List<String> medias,
  }) async {
    await api.post('/posts', corps: {
      'artisan_category': metier,
      'description': description,
      'medias': medias,
    });
  }

  Future<void> publierStory({required String media, String? legende}) async {
    await api.post('/stories', corps: {
      'media_url': media,
      if (legende != null && legende.isNotEmpty) 'legende': legende,
    });
  }
}
