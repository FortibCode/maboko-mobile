import 'dart:io';
import 'dart:typed_data';

/// Version mobile : lit le fichier audio en mémoire.
Future<Uint8List?> lireFichierAudio(String chemin) async {
  try {
    final fichier = File(chemin);
    return await fichier.readAsBytes();
  } catch (_) {
    return null;
  }
}