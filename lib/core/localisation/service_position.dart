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
  static Stream<Position> suivi({int filtreMetres = 25}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: filtreMetres,
      ),
    );
  }

  /// Vrai lorsque l'autorisation a été refusée définitivement : l'application
  /// doit alors renvoyer vers les réglages plutôt que redemander en boucle.
  static Future<bool> refusDefinitif() async {
    return await Geolocator.checkPermission() == LocationPermission.deniedForever;
  }
}
