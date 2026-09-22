import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Cache local des dernières réponses de l'API.
///
/// Le paragraphe 7.2 vise une application utilisable en connexion dégradée.
/// À Brazzaville, une coupure de quelques minutes est banale : plutôt que
/// d'afficher une erreur, l'application montre le dernier contenu connu et
/// le signale à l'utilisateur.
///
/// Ce cache ne sert qu'à l'affichage : toute action passe par le réseau.
class CacheLocal {
  const CacheLocal._();

  static const _prefixe = 'cache_';
  static const _prefixeDate = 'cache_date_';

  /// Au-delà, le contenu est trop ancien pour être montré même hors ligne.
  static const dureeMax = Duration(hours: 12);

  static Future<void> ecrire(String cle, Object valeur) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString('$_prefixe$cle', jsonEncode(valeur));
    await prefs.setInt('$_prefixeDate$cle', DateTime.now().millisecondsSinceEpoch);
  }

  /// Contenu mis en cache, avec sa date. Null s'il est absent ou périmé.
  static Future<({dynamic contenu, DateTime enregistreLe})?> lire(String cle) async {
    final prefs = await SharedPreferences.getInstance();

    final brut = prefs.getString('$_prefixe$cle');
    final horodatage = prefs.getInt('$_prefixeDate$cle');

    if (brut == null || horodatage == null) return null;

    final date = DateTime.fromMillisecondsSinceEpoch(horodatage);

    if (DateTime.now().difference(date) > dureeMax) {
      await vider(cle);

      return null;
    }

    try {
      return (contenu: jsonDecode(brut), enregistreLe: date);
    } catch (_) {
      // Contenu illisible : on le jette plutôt que de faire planter l'écran.
      await vider(cle);

      return null;
    }
  }

  static Future<void> vider(String cle) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('$_prefixe$cle');
    await prefs.remove('$_prefixeDate$cle');
  }

  /// Appelé à la déconnexion : le cache d'un compte ne doit pas fuiter
  /// vers le suivant sur un téléphone partagé.
  static Future<void> viderTout() async {
    final prefs = await SharedPreferences.getInstance();

    for (final cle in prefs.getKeys().where((c) => c.startsWith(_prefixe))) {
      await prefs.remove(cle);
    }
  }

  /// Taille approximative du cache, en octets.
  ///
  /// Les valeurs sont stockées en JSON dans les préférences : la longueur de
  /// la chaîne encodée donne une bonne estimation de ce qu'elles pèsent.
  /// Les clés de date sont ignorées (elles sont minuscules).
  static Future<int> taille() async {
    final prefs = await SharedPreferences.getInstance();

    var total = 0;
    for (final cle in prefs.getKeys().where(
      (c) => c.startsWith(_prefixe) && !c.startsWith(_prefixeDate),
    )) {
      final valeur = prefs.getString(cle);
      if (valeur != null) total += valeur.length;
    }

    return total;
  }
}