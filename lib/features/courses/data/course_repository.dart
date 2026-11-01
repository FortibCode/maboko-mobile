import '../../../core/network/api_client.dart';
import '../models/course.dart';

class CourseRepository {
  const CourseRepository();

  /// Enregistre ou met à jour la fiche véhicule du chauffeur.
  Future<void> enregistrerFiche({
    required String typeVehicule,
    required String modele,
    required String plaque,
    required String permisCategories,
    required String permisNumero,
    bool estClimatise = false, // 👈 AJOUT
  }) async {
    await const ApiClient().post('/chauffeur', body: {
      'type_vehicule': typeVehicule,
      'vehicule_modele': modele,
      'plaque_immatriculation': plaque,
      'permis_categories': permisCategories,
      'permis_conduire': permisNumero,
      'est_climatise': estClimatise, // 👈 AJOUT
    });
  }

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

  Future<Course> contreProposer(int courseId, double nouveauPrix) async {
    final reponse = await const ApiClient().post(
      '/courses/$courseId/contre-proposition',
      body: {'prix_chauffeur': nouveauPrix},
    );
    return Course.fromJson(reponse['course']);
  }

  Future<Course> accepterPrix(int courseId) async {
    final reponse = await const ApiClient().post('/courses/$courseId/accepter-prix');
    return Course.fromJson(reponse['course']);
  }

  Future<Course> accepterCourse(int courseId) async {
    final reponse = await const ApiClient().post('/courses/$courseId/accepter');
    return Course.fromJson(reponse['course']);
  }

  Future<void> refuserCourse(int courseId) async {
    await const ApiClient().post('/courses/$courseId/refuser');
  }

  Future<Course> terminerCourse(int courseId) async {
    final reponse = await const ApiClient().post('/courses/$courseId/terminer');
    return Course.fromJson(reponse['course']);
  }
}