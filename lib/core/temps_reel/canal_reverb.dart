import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import '../network/api.dart';
import '../network/api_exception.dart';

/// Client WebSocket pour les canaux privés Reverb.
///
/// Implémente le strict nécessaire du protocole Pusher, que Reverb parle :
/// poignée de main, autorisation du canal privé auprès de l'API, abonnement,
/// puis réception des événements. Un paquet Dart pur plutôt qu'une
/// implémentation native, pour que le même code serve sur mobile et sur web.
///
/// Sans clé Reverb fournie à la compilation, la connexion n'est pas tentée :
/// l'appelant se rabat alors sur l'interrogation périodique.
class CanalReverb {
  CanalReverb({required this.nomCanal});

  /// Nom du canal, sans le préfixe « private- ».
  final String nomCanal;

  WebSocketChannel? _socket;
  StreamSubscription<dynamic>? _abonnement;
  Timer? _reconnexion;

  final _evenements = StreamController<({String nom, Map<String, dynamic> donnees})>.broadcast();

  bool _ferme = false;
  int _tentatives = 0;

  /// Événements reçus sur le canal.
  Stream<({String nom, Map<String, dynamic> donnees})> get evenements => _evenements.stream;

  bool get connecte => _socket != null;

  Future<void> connecter() async {
    if (!AppConfig.tempsReelDisponible || _ferme) return;

    try {
      final socket = WebSocketChannel.connect(Uri.parse(AppConfig.reverbUrl));
      await socket.ready;

      _socket = socket;
      _tentatives = 0;

      _abonnement = socket.stream.listen(
        _traiter,
        onError: (_) => _programmerReconnexion(),
        onDone: _programmerReconnexion,
        cancelOnError: false,
      );
    } catch (_) {
      _programmerReconnexion();
    }
  }

  void _traiter(dynamic brut) {
    final Map<String, dynamic> trame;

    try {
      trame = jsonDecode(brut as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final nom = trame['event'] as String? ?? '';

    // La charge utile arrive encodée en JSON dans une chaîne.
    Map<String, dynamic> donnees = {};
    final charge = trame['data'];
    if (charge is String && charge.isNotEmpty) {
      try {
        final decode = jsonDecode(charge);
        if (decode is Map<String, dynamic>) donnees = decode;
      } catch (_) {
        // Charge non structurée : on la laisse vide.
      }
    } else if (charge is Map<String, dynamic>) {
      donnees = charge;
    }

    switch (nom) {
      case 'pusher:connection_established':
        final socketId = donnees['socket_id'] as String?;
        if (socketId != null) _autoriserPuisSAbonner(socketId);
      case 'pusher:ping':
        _envoyer({'event': 'pusher:pong', 'data': {}});
      case 'pusher:error':
        _programmerReconnexion();
      default:
        if (!nom.startsWith('pusher')) {
          _evenements.add((nom: nom, donnees: donnees));
        }
    }
  }

  /// Un canal privé exige une signature délivrée par l'API : c'est elle qui
  /// empêche d'écouter les conversations d'autrui.
  Future<void> _autoriserPuisSAbonner(String socketId) async {
    final canal = 'private-$nomCanal';

    try {
      final reponse = await api.post('/diffusion/auth', corps: {
        'socket_id': socketId,
        'channel_name': canal,
      });

      final signature = (reponse as Map<String, dynamic>)['auth'] as String?;
      if (signature == null) return;

      _envoyer({
        'event': 'pusher:subscribe',
        'data': {'channel': canal, 'auth': signature},
      });
    } on ApiException {
      // Autorisation refusée : inutile d'insister, l'appelant continuera
      // avec l'interrogation périodique.
      await fermer();
    }
  }

  void _envoyer(Map<String, dynamic> trame) {
    _socket?.sink.add(jsonEncode(trame));
  }

  /// Réessaie avec un délai croissant, plafonné : sur une connexion
  /// instable, marteler le serveur ne sert qu'à vider la batterie.
  void _programmerReconnexion() {
    if (_ferme || _reconnexion != null) return;

    _abonnement?.cancel();
    _abonnement = null;
    _socket = null;

    _tentatives++;
    final delai = Duration(seconds: (_tentatives * 2).clamp(2, 30));

    _reconnexion = Timer(delai, () {
      _reconnexion = null;
      connecter();
    });
  }

  Future<void> fermer() async {
    _ferme = true;
    _reconnexion?.cancel();
    await _abonnement?.cancel();
    await _socket?.sink.close();
    _socket = null;
    await _evenements.close();
  }
}
