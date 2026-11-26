import '../../../core/network/api.dart';
import '../models/publicite.dart';

class PubliciteRepository {
  const PubliciteRepository();

  /// Récupère la publicité actuellement en cours de diffusion pour les utilisateurs.
  Future<Publicite?> active() async {
    final reponse = await api.get('/publicite/active');
    final donnees = reponse['publicite'] as Map<String, dynamic>?;
    if (donnees == null) return null;
    return Publicite.depuisJson(donnees);
  }

  /// Enregistre un clic sur une publicité.
  Future<void> enregistrerClic(int publiciteId) async {
    try {
      await api.post('/publicite/$publiciteId/clic');
    } catch (_) {}
  }

  /// Liste des publicités créées par l'artisan connecté.
  Future<List<Publicite>> mesPublicites() async {
    final reponse = await api.get('/artisan/publicites');
    final liste = reponse['publicites'] as List? ?? [];
    return liste.map((j) => Publicite.depuisJson(j as Map<String, dynamic>)).toList();
  }

  /// Crée et paie une nouvelle campagne publicitaire pour l'artisan.
  Future<({Publicite publicite, String message})> creerCampagne({
    required String titre,
    String? description,
    required String imageBase64,
    required int dureeJours,
    required String operateur,
    required String telephone,
  }) async {
    final reponse = await api.post('/artisan/publicites', corps: {
      'titre': titre,
      if (description != null && description.isNotEmpty) 'description': description,
      'image': imageBase64,
      'duree_jours': dureeJours,
      'operateur': operateur,
      'telephone': telephone,
    });

    final pubJson = reponse['publicite'] as Map<String, dynamic>;
    final message = reponse['message'] as String? ?? 'Campagne soumise avec succès.';

    return (
      publicite: Publicite.depuisJson(pubJson),
      message: message,
    );
  }
}
