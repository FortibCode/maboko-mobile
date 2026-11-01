import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Accès à la position de l'appareil.
///
/// Encapsule les autorisations : un refus doit produire un message clair,
/// pas une exception brute remontée jusqu'à l'écran.
class ServicePosition {
  const ServicePosition._();

  /// Position actuelle, ou null si le service ou l'autorisation manquent.
  static Future<Position?> actuelle() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  /// Flux de positions pour le suivi pendant une course.
  ///
  /// Le filtre de distance évite d'envoyer une position à chaque frémissement
  /// du GPS : sur une 3G facturée au volume, chaque envoi compte.
  ///
  /// Avec [arrierePlan], le suivi continue écran verrouillé : sur Android via
  /// un service de premier plan (notification permanente, exigée par le
  /// système), sur iOS via le mode d'arrière-plan « location » d'Info.plist.
  /// Le flux doit alors être ouvert pendant que l'application est visible.
  static Stream<Position> suivi({int filtreMetres = 25, bool arrierePlan = false}) {
    return Geolocator.getPositionStream(
      locationSettings: _reglages(filtreMetres, arrierePlan),
    );
  }

  static LocationSettings _reglages(int filtreMetres, bool arrierePlan) {
    if (!arrierePlan || kIsWeb) {
      return LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: filtreMetres,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: filtreMetres,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'Maboko : vous êtes en ligne',
            notificationText:
                'Votre position est partagée pour recevoir des courses.',
            notificationChannelName: 'Suivi de position',
            enableWakeLock: true,
            setOngoing: true,
          ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: filtreMetres,
          activityType: ActivityType.automotiveNavigation,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        );
      default:
        return LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: filtreMetres,
        );
    }
  }

  /// Vrai lorsque l'autorisation a été refusée définitivement : l'application
  /// doit alors renvoyer vers les réglages plutôt que redemander en boucle.
  static Future<bool> refusDefinitif() async {
    return await Geolocator.checkPermission() == LocationPermission.deniedForever;
  }
}
