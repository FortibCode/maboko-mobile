import '../../../core/network/api.dart';
import '../../../core/network/api_exception.dart';
import '../models/course.dart';

class CourseRepository {
  const CourseRepository();

  // ------------------------------------------------------------------
  // Côté client (§5.1.8)
  // ------------------------------------------------------------------

  /// Tarif estimé avant réservation : le client voit le prix avant de
  /// s'engager, ce qui remplace la négociation au bord de la route.
  Future<EstimationCourse> estimer({
    required double departLat,
    required double departLng,
    required double arriveeLat,
    required double arriveeLng,
    required String typeVehicule,
  }) async {
    final reponse = await api.post('/courses/estimation', corps: {
      'depart_latitude': departLat,
      'depart_longitude': departLng,
      'arrivee_latitude': arriveeLat,
      'arrivee_longitude': arriveeLng,
      'type_vehicule': typeVehicule,
    });

    return EstimationCourse.depuisJson(reponse as Map<String, dynamic>);
  }

  Future<({Course course, int chauffeursContactes})> reserver({
    required String lieuDepart,
    required String lieuArrivee,
    required double departLat,
    required double departLng,
    required double arriveeLat,
    required double arriveeLng,
    required String typeVehicule,
  }) async {
    final reponse = await api.post('/courses', corps: {
      'lieu_depart': lieuDepart,
      'lieu_arrivee': lieuArrivee,
      'depart_latitude': departLat,
      'depart_longitude': departLng,
      'arrivee_latitude': arriveeLat,
      'arrivee_longitude': arriveeLng,
      'type_vehicule': typeVehicule,
    });

    return (
      course: Course.depuisJson(reponse['course'] as Map<String, dynamic>),
      chauffeursContactes: reponse['chauffeursContactes'] as int? ?? 0,
    );
  }

  Future<Course> detail(int id) async {
    final reponse = await api.get('/courses/$id');

    return Course.depuisJson(reponse['data'] as Map<String, dynamic>);
  }

  Future<List<Course>> historique() async {
    final reponse = await api.get('/courses');

    return ((reponse['data'] as List?) ?? [])
        .map((c) => Course.depuisJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<Course> annuler(int id, {String? motif}) =>
      _transition(id, 'annuler', motif == null ? {} : {'motif': motif});

  // ------------------------------------------------------------------
  // Côté chauffeur (§5.3)
  // ------------------------------------------------------------------

  Future<EtatChauffeur> etatChauffeur() async {
    try {
      final reponse = await api.get('/chauffeur');

      return EtatChauffeur.depuisJson(reponse as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return const EtatChauffeur(ficheManquante: true);

      rethrow;
    }
  }

  /// Dépôt de la fiche véhicule du chauffeur connecté (§5.3.1).
  Future<EtatChauffeur> enregistrerFiche({
    required String typeVehicule,
    required String modele,
    required String plaque,
    required String permis,
  }) async {
    final reponse = await api.post('/chauffeur', corps: {
      'type_vehicule': typeVehicule,
      'vehicule_modele': modele,
      'plaque_immatriculation': plaque,
      'permis_conduire': permis,
    });

    return EtatChauffeur.depuisJson(reponse as Map<String, dynamic>);
  }

  /// Refus d'une course proposée (§5.3.1).
  Future<void> refuser(int courseId) async {
    await api.post('/courses/$courseId/refuser');
  }

  Future<bool> basculerDisponibilite(bool enLigne) async {
    final reponse = await api.post('/chauffeur/disponibilite', corps: {'en_ligne': enLigne});

    return reponse['enLigne'] as bool? ?? false;
  }

  Future<void> transmettrePosition({
    required double latitude,
    required double longitude,
    double? vitesseKmh,
  }) async {
    await api.post('/chauffeur/position', corps: {
      'latitude': latitude,
      'longitude': longitude,
      if (vitesseKmh != null) 'vitesse_kmh': vitesseKmh,
    });
  }

  Future<List<Course>> propositions() async {
    final reponse = await api.get('/chauffeur/propositions');

    return ((reponse['data'] as List?) ?? [])
        .map((c) => Course.depuisJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<RevenusChauffeur> revenus() async {
    final reponse = await api.get('/chauffeur/revenus');

    return RevenusChauffeur.depuisJson(reponse as Map<String, dynamic>);
  }

  Future<Course> accepter(int id) => _transition(id, 'accepter', {});

  Future<Course> demarrer(int id) => _transition(id, 'demarrer', {});

  Future<Course> prendreEnCharge(int id) => _transition(id, 'prise-en-charge', {});

  /// Fin de course (§5.3.3).
  ///
  /// Le [codeConfirmation] est le code à 4 chiffres que le client communique
  /// au chauffeur. Le serveur le valide ; en simulation locale, l'écran
  /// chauffeur le compare avant d'appeler cette méthode.
  Future<Course> terminer(
    int id, {
    required String codeConfirmation,
    double? tarifFinal,
  }) =>
      _transition(id, 'terminer', {
        'code_confirmation': codeConfirmation,
        if (tarifFinal != null) 'tarif_final': tarifFinal,
      });

  Future<Course> _transition(int id, String action, Map<String, dynamic> corps) async {
    final reponse = await api.post('/courses/$id/$action', corps: corps);

    return Course.depuisJson(reponse['course'] as Map<String, dynamic>);
  }
}