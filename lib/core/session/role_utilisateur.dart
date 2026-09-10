import 'package:flutter/widgets.dart';

import '../../services/storage_service.dart';

/// Les rôles reconnus par Maboko.
///
/// Ils étaient jusqu'ici manipulés sous forme de chaînes, et l'interface se
/// décidait par `!role.contains('artisan')` — autrement dit un client n'était
/// pas défini comme un client, mais comme « quelqu'un qui n'est pas artisan ».
/// Un rôle inattendu, une valeur vide ou un compte d'administration tombaient
/// donc silencieusement dans l'espace client.
enum RoleMaboko {
  client,
  artisan,
  chauffeur,
  admin;

  /// Lit un rôle tel que l'API le renvoie.
  ///
  /// Les variantes « artisan_menuisier » héritées des premières versions sont
  /// reconnues ; tout le reste retombe sur client, mais explicitement.
  static RoleMaboko depuis(String? valeur) {
    final texte = valeur?.trim().toLowerCase() ?? '';

    if (texte == 'artisan' || texte.startsWith('artisan_')) return RoleMaboko.artisan;
    if (texte == 'chauffeur' || texte.startsWith('chauffeur_')) return RoleMaboko.chauffeur;
    if (texte == 'admin' || texte == 'super_admin') return RoleMaboko.admin;

    return RoleMaboko.client;
  }

  bool get estClient => this == RoleMaboko.client;
  bool get estArtisan => this == RoleMaboko.artisan;
  bool get estChauffeur => this == RoleMaboko.chauffeur;

  /// Valeur attendue par l'API à l'inscription.
  String get pourApi => switch (this) {
        RoleMaboko.artisan => 'artisan',
        RoleMaboko.chauffeur => 'chauffeur',
        _ => 'client',
      };

  String get libelle => switch (this) {
        RoleMaboko.artisan => 'Artisan',
        RoleMaboko.chauffeur => 'Chauffeur',
        RoleMaboko.admin => 'Administration',
        RoleMaboko.client => 'Client',
      };
}

/// Ouvre l'espace correspondant au rôle, en effaçant la pile de navigation.
///
/// Un compte d'administration n'a pas d'espace mobile : il reçoit l'espace
/// client, qui lui est de toute façon accessible.
void ouvrirEspace(BuildContext context, RoleMaboko role, {required String nom}) {
  if (role.estChauffeur) {
    Navigator.pushNamedAndRemoveUntil(context, '/chauffeur', (route) => false);

    return;
  }

  Navigator.pushNamedAndRemoveUntil(
    context,
    '/home',
    (route) => false,
    arguments: {'avatarName': nom, 'userRole': role.pourApi},
  );
}

/// Réaligne l'application sur le rôle que le serveur vient de confirmer.
///
/// Le rôle qui décide de l'interface était écrit une fois dans le stockage du
/// téléphone, à la connexion. Le compte, lui, vit sur le serveur : dès que les
/// deux divergeaient — inscription par un chemin qui imposait un rôle, rôle
/// modifié en base, session reprise sur un autre compte — l'utilisateur
/// restait enfermé dans la mauvaise interface, sans rien pour l'en sortir.
///
/// Retourne vrai si un réaiguillage a été déclenché.
Future<bool> realignerSurLeServeur(
  BuildContext context, {
  required String? roleServeur,
  required RoleMaboko roleAffiche,
  required String nom,
}) async {
  final reel = RoleMaboko.depuis(roleServeur);

  if (reel == roleAffiche) return false;

  // Le stockage local suivait déjà l'ancien rôle : on le corrige avant de
  // rouvrir, sinon la prochaine ouverture repartirait sur l'erreur.
  await StorageService.saveUserRole(reel.pourApi);

  if (!context.mounted) return false;

  ouvrirEspace(context, reel, nom: nom);

  return true;
}
