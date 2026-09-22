import '../../../core/network/api.dart';
import '../models/artisan.dart';

/// Avis reçus par l'artisan connecté (§5.2).
///
/// L'API n'expose qu'une route publique (`/artisans/{id}/avis`). On
/// récupère d'abord la fiche de l'artisan connecté via `/artisans/me`
/// pour connaître son id, puis on charge ses avis.
class AvisRecusRepository {
  const AvisRecusRepository();

  /// Charge la fiche de l'artisan connecté et ses avis.
  Future<AvisRecus> charger() async {
    final reponseFiche = await api.get('/artisans/me');
    final donneesFiche = reponseFiche['data'] as Map<String, dynamic>?;

    if (donneesFiche == null) {
      return const AvisRecus(
        noteMoyenne: 0,
        nbAvis: 0,
        avis: [],
      );
    }

    final artisan = Artisan.depuisJson(donneesFiche);

    final reponseAvis = await api.get('/artisans/${artisan.id}/avis');
    final liste = ((reponseAvis['data'] as List?) ?? [])
        .map((a) => Avis.depuisJson(a as Map<String, dynamic>))
        .toList();

    return AvisRecus(
      noteMoyenne: artisan.noteMoyenne,
      nbAvis: artisan.nbAvis,
      avis: liste,
    );
  }
}

/// Résultat complet : statistiques + liste des avis.
class AvisRecus {
  const AvisRecus({
    required this.noteMoyenne,
    required this.nbAvis,
    required this.avis,
  });

  final double noteMoyenne;
  final int nbAvis;
  final List<Avis> avis;

  /// Nombre d'avis par note (5 étoiles → 1 étoile).
  Map<int, int> get repartition {
    final map = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final a in avis) {
      map[a.note] = (map[a.note] ?? 0) + 1;
    }
    return map;
  }
}