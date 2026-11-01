import 'dart:async';
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