import '../../../core/network/api_client.dart';
import '../models/course.dart';

class CourseRepository {
  const CourseRepository();

  // Le client réserve une course ET propose un prix
  Future<Course> reserverCourse({
    required String lieuDepart,
    required String lieuArrivee,
    required double departLat,
    required double departLng,
    required double arriveeLat,
    required double arriveeLng,
    required String typeVehicule,
    double? prixClient,
  }) async {
    final reponse = await const ApiClient().post('/courses', body: {
      'lieu_depart': lieuDepart,
      'lieu_arrivee': lieuArrivee,
      'depart_latitude': departLat,
      'depart_longitude': departLng,
      'arrivee_latitude': arriveeLat,
      'arrivee_longitude': arriveeLng,
      'type_vehicule': typeVehicule,
      if (prixClient != null) 'prix_client': prixClient,
    });
    return Course.fromJson(reponse['course']);
  }

  // 🆕 Le chauffeur propose un autre prix
  Future<Course> contreProposer(int courseId, double nouveauPrix) async {
    final reponse = await const ApiClient().post(
      '/courses/$courseId/contre-proposition',
      body: {'prix_chauffeur': nouveauPrix},
    );
    return Course.fromJson(reponse['course']);
  }

  // 🆕 Le client accepte le prix du chauffeur
  Future<Course> accepterPrix(int courseId) async {
    final reponse = await const ApiClient().post('/courses/$courseId/accepter-prix');
    return Course.fromJson(reponse['course']);
  }

  // Le chauffeur accepte le prix initial du client
  Future<Course> accepterCourse(int courseId) async {
    final reponse = await const ApiClient().post('/courses/$courseId/accepter');
    return Course.fromJson(reponse['course']);
  }

  // Le chauffeur refuse la course
  Future<void> refuserCourse(int courseId) async {
    await const ApiClient().post('/courses/$courseId/refuser');
  }

  // Le client termine la course
  Future<Course> terminerCourse(int courseId) async {
    final reponse = await const ApiClient().post('/courses/$courseId/terminer');
    return Course.fromJson(reponse['course']);
  }
}