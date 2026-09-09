import 'package:flutter/material.dart';

/// Icône associée à chaque métier du référentiel.
/// Le serveur renvoie le slug ; l'illustration reste côté application.
IconData iconeMetier(String? slug) => switch (slug) {
      'macon' => Icons.foundation_rounded,
      'plombier' => Icons.plumbing_rounded,
      'menuisier' || 'charpentier' => Icons.carpenter_rounded,
      'ebeniste' => Icons.chair_rounded,
      'couturier' => Icons.content_cut_rounded,
      'mecanicien' => Icons.build_rounded,
      'electricien' => Icons.electrical_services_rounded,
      'peintre' => Icons.format_paint_rounded,
      'frigoriste' => Icons.ac_unit_rounded,
      'carreleur' => Icons.grid_on_rounded,
      'soudeur' || 'tolier' => Icons.hardware_rounded,
      'vitrier' => Icons.window_rounded,
      'plaquiste' => Icons.dashboard_rounded,
      'couvreur' => Icons.roofing_rounded,
      'serrurier' => Icons.lock_rounded,
      'jardinier' => Icons.grass_rounded,
      'coiffeur' => Icons.face_retouching_natural_rounded,
      'cordonnier' => Icons.checkroom_rounded,
      'tapissier' => Icons.weekend_rounded,
      'informaticien' => Icons.computer_rounded,
      _ => Icons.handyman_rounded,
    };
