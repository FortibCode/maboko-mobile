import 'dart:typed_data';

/// Version Web : l'envoi vocal n'est pas disponible.
///
/// Retourne toujours `null`, ce qui fait échouer proprement l'envoi avec
/// un message clair ("Impossible d'envoyer le message vocal") au lieu de
/// crasher l'application.
Future<Uint8List?> lireFichierAudio(String chemin) async => null;