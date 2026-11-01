import 'dart:async';

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
