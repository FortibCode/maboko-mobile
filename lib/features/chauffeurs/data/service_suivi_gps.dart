import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../courses/data/course_repository.dart';
import '../../../core/localisation/service_position.dart';

/// Suivi GPS du chauffeur, partagé par toute l'application.
///
/// Tant qu'il est actif, chaque position part au serveur via
/// [CourseRepository.transmettrePosition], y compris écran verrouillé :
/// c'est elle qui rend le chauffeur joignable et permet au client de suivre
/// son taxi. Démarré par [ChauffeurAccueilScreen] au passage « En ligne » et
/// par [CourseChauffeurScreen] pendant une course.
///
/// Une seule instance existe, car le plugin GPS ne tient qu'un flux à la
/// fois : un second abonnement recevrait le premier flux, et le couper
/// arrêterait le suivi pour tout le monde. Les écrans qui veulent afficher
/// la position écoutent [positions] au lieu d'ouvrir leur propre flux.
class ServiceSuiviGps {
  ServiceSuiviGps._();

  static final ServiceSuiviGps instance = ServiceSuiviGps._();

  static const _repository = CourseRepository();

  StreamSubscription<Position>? _abonnement;
  final _positions = StreamController<Position>.broadcast();

  /// Positions reçues pendant le suivi, pour l'affichage (carte, etc.).
  Stream<Position> get positions => _positions.stream;

  /// Dernière position reçue : un écran qui s'abonne en cours de route n'a
  /// pas à attendre le prochain déplacement de 25 m pour l'afficher.
  Position? get dernierePosition => _derniere;
  Position? _derniere;

  /// Indique si le suivi est actif.
  bool get estActif => _abonnement != null;

  /// Démarre le suivi GPS et la transmission automatique de la position.
  ///
  /// Renvoie false si le GPS est coupé ou l'autorisation refusée : le flux
  /// de position échouerait sinon dès son ouverture.
  Future<bool> demarrer() async {
    if (_abonnement != null) return true; // Déjà actif

    if (!await Geolocator.isLocationServiceEnabled()) return false;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    // Deux appels simultanés ont pu passer les vérifications ensemble.
    if (_abonnement != null) return true;

    _abonnement = ServicePosition.suivi(arrierePlan: true).listen(
      (position) {
        _derniere = position;
        _positions.add(position);

        // Une erreur réseau ne doit pas interrompre le suivi : la position
        // suivante sera envoyée normalement.
        _repository
            .transmettrePosition(
              latitude: position.latitude,
              longitude: position.longitude,
              vitesseKmh: position.speed * 3.6, // m/s vers km/h
            )
            .catchError((Object e) => debugPrint('Envoi de position échoué : $e'));
      },
      onError: (Object e) => debugPrint('Erreur GPS : $e'),
    );
    return true;
  }

  /// Arrête le suivi GPS (et la notification Android qui l'accompagne).
  void arreter() {
    _abonnement?.cancel();
    _abonnement = null;
    _derniere = null;
  }
}
