import 'package:flutter/material.dart';

import '../theme/maboko_theme.dart';

/// Photo de profil réelle, avec repli sur les initiales.
///
/// Remplace les icônes tirées d'une liste figée : deux comptes ayant choisi le
/// même rang affichaient exactement la même image, ce qui ne distingue
/// personne. À défaut de photo, les initiales du compte sont au moins propres
/// au titulaire.
class PhotoProfil extends StatelessWidget {
  const PhotoProfil({
    super.key,
    required this.url,
    required this.nom,
    this.taille = 90,
    this.onModifier,
  });

  final String? url;
  final String nom;
  final double taille;

  /// Fourni, un bouton d'appareil photo se pose sur la vignette.
  final VoidCallback? onModifier;

  String get _initiales {
    final morceaux = nom.trim().split(RegExp(r'\s+')).where((m) => m.isNotEmpty).toList();
    if (morceaux.isEmpty) return '?';

    return morceaux.take(2).map((m) => m[0]).join().toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final aUnePhoto = url != null && url!.isNotEmpty;

    final vignette = Container(
      width: taille,
      height: taille,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5D8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: MabokoCouleurs.principale.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // ClipOval plutot que le seul clipBehavior du Container : avec une
      // bordure, celui-ci decoupe un rectangle arrondi, et la photo sortait
      // carree dans la barre du haut.
      child: aUnePhoto
          ? ClipOval(
              child: Image.network(
                url!,
                fit: BoxFit.cover,
                width: taille,
                height: taille,
                // Une photo indisponible ne doit pas casser l'écran : on
                // retombe sur les initiales.
                errorBuilder: (contexte, erreur, trace) => _initialesAffichees(),
                loadingBuilder: (contexte, enfant, progression) =>
                    progression == null ? enfant : _initialesAffichees(),
              ),
            )
          : _initialesAffichees(),
    );

    if (onModifier == null) return vignette;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        vignette,
        Positioned(
          right: -2,
          bottom: -2,
          child: Material(
            color: MabokoCouleurs.secondaire,
            shape: const CircleBorder(),
            elevation: 2,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onModifier,
              child: Padding(
                padding: EdgeInsets.all(taille * 0.08),
                child: Icon(
                  Icons.photo_camera_rounded,
                  size: taille * 0.2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _initialesAffichees() {
    return Center(
      child: Text(
        _initiales,
        style: TextStyle(
          fontSize: taille * 0.34,
          fontWeight: FontWeight.bold,
          color: MabokoCouleurs.secondaire,
        ),
      ),
    );
  }
}
