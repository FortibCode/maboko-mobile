import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/maboko_theme.dart';

/// Prise d'une vraie photo, par l'appareil ou depuis la galerie.
///
/// Les écrans existants imposaient l'appareil photo. C'est justifié pour une
/// pièce d'identité, mais pas pour une photo de profil : beaucoup de gens ont
/// déjà celle qu'ils veulent utiliser dans leur galerie.
///
/// Renvoie l'image encodée en base64 (`data:image/jpeg;base64,...`), forme
/// attendue par l'API, ou `null` si l'utilisateur renonce.
Future<String?> choisirPhoto(
  BuildContext context, {
  double largeurMax = 1200,
  int qualite = 85,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: context.surfaceMaboko,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (contexte) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.bordureMaboko,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.photo_camera_rounded, color: MabokoCouleurs.secondaire),
            title: const Text('Prendre une photo'),
            onTap: () => Navigator.pop(contexte, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded, color: MabokoCouleurs.secondaire),
            title: const Text('Choisir dans la galerie'),
            onTap: () => Navigator.pop(contexte, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );

  if (source == null) return null;

  final XFile? fichier;
  try {
    fichier = await ImagePicker().pickImage(
      source: source,
      maxWidth: largeurMax,
      imageQuality: qualite,
    );
  } catch (_) {
    // Permission refusée, ou appareil sans caméra : on le dit plutôt que de
    // laisser l'écran sans réaction.
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir l’appareil photo. Vérifiez les autorisations.'),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );
    }

    return null;
  }

  if (fichier == null) return null;

  final octets = await fichier.readAsBytes();

  return 'data:image/jpeg;base64,${base64Encode(octets)}';
}
