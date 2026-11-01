import 'dart:async';
<<<<<<< HEAD
import 'package:geolocator/geolocator.dart';
import '../../../core/network/api_client.dart';

class ServiceSuiviGps {
  Timer? _timer;
  bool _enCours = false;

  /// Démarre l'envoi de la position toutes les 10 secondes.
  Future<void> demarrer() async {
    if (_enCours) return;

    // 1. Vérifier si le GPS est activé
    final serviceActive = await Geolocator.isLocationServiceEnabled();
    if (!serviceActive) return;

    // 2. Demander la permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _enCours = true;

    // 3. Envoyer la position toutes les 10 secondes
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition();
        
        // On envoie à l'API Laravel (route POST /chauffeur/position)
        await const ApiClient().post('/chauffeur/position', body: {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'vitesse_kmh': position.speed * 3.6, // Conversion m/s en km/h
        });
      } catch (e) {
        // Erreur réseau silencieuse pour ne pas bloquer l'app
        print('Erreur GPS: $e');
      }
    });
  }

  /// Arrête l'envoi (quand le chauffeur passe hors ligne).
  void arreter() {
    _timer?.cancel();
    _enCours = false;
  }
}
=======

import '../../courses/data/course_repository.dart';
import '../../../core/localisation/service_position.dart';

/// Service de suivi GPS pour le chauffeur.
///
/// Démarre un flux de position continue quand le chauffeur est en ligne
/// et le transmet au serveur via [CourseRepository.transmettrePosition].
/// Appelé depuis [ChauffeurAccueilScreen] lorsque le chauffeur bascule
/// en mode « En ligne ».
///
/// Bien que ce service soit instanciable, la logique de suivi est déjà
/// intégrée dans [ChauffeurAccueilScreen] via [ServicePosition.suivi()].
/// Cette classe sert de point d'extension pour les tests et les futures
/// fonctionnalités (ex. : historique des trajets côté chauffeur).
class ServiceSuiviGps {
  static const _repository = CourseRepository();

  StreamSubscription<dynamic>? _abonnement;

  /// Démarre le suivi GPS et la transmission automatique de la position.
  void demarrer() {
    if (_abonnement != null) return; // Déjà actif

    _abonnement = ServicePosition.suivi().listen((position) {
      _repository.transmettrePosition(
        latitude: position.latitude,
        longitude: position.longitude,
        vitesseKmh: position.speed * 3.6,
      );
    });
  }

  /// Arrête le suivi GPS.
  void arreter() {
    _abonnement?.cancel();
    _abonnement = null;
  }

  /// Indique si le suivi est actif.
  bool get estActif => _abonnement != null;
}
>>>>>>> 1e016d67d9892b850e40325b501a17951038a399
