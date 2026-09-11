import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

/// Adresse de l'API réellement utilisée, modifiable sans recompiler.
///
/// Elle était figée à la compilation. Or le poste de développement reçoit son
/// adresse de la box en DHCP : au premier renouvellement de bail, l'adresse
/// change et l'application ne joint plus rien — « Impossible de joindre
/// Maboko » — jusqu'à ce que quelqu'un reconstruise l'application avec la
/// nouvelle valeur.
///
/// La valeur compilée reste le point de départ ; un réglage local, quand il
/// existe, la remplace. En production, l'adresse compilée pointe sur le vrai
/// domaine et rien n'a besoin d'être touché.
class AdresseApi {
  const AdresseApi._();

  static const _cle = 'api_base_url';

  /// Valeur en vigueur, lue une fois au démarrage puis gardée en mémoire :
  /// chaque requête la consulte, elle ne peut pas être asynchrone.
  static String _courante = AppConfig.apiBaseUrl;

  static String get valeur => _normaliser(_courante);

  /// Vrai si l'adresse a été changée depuis l'application.
  static bool get personnalisee => valeur != valeurCompilee;

  static String get valeurCompilee => _normaliser(AppConfig.apiBaseUrl);

  /// À appeler au démarrage, avant la première requête.
  static Future<void> charger() async {
    // Une compilation de production ne se laisse pas détourner vers une autre
    // adresse : ce serait un moyen commode de rediriger les identifiants
    // d'un utilisateur vers un serveur tiers.
    if (AppConfig.isRelease) return;

    final prefs = await SharedPreferences.getInstance();
    final enregistree = prefs.getString(_cle)?.trim();

    if (enregistree != null && enregistree.isNotEmpty) {
      _courante = enregistree;
    }
  }

  /// Enregistre une nouvelle adresse. Retourne null si elle convient, sinon
  /// le motif du refus.
  static Future<String?> definir(String saisie) async {
    if (AppConfig.isRelease) return 'Adresse non modifiable en production.';

    final nettoyee = _normaliser(saisie);
    final motif = _valider(nettoyee);

    if (motif != null) return motif;

    _courante = nettoyee;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cle, nettoyee);

    return null;
  }

  /// Revient à l'adresse inscrite à la compilation.
  static Future<void> reinitialiser() async {
    _courante = AppConfig.apiBaseUrl;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cle);
  }

  /// Accepte « 192.168.1.83 » comme « http://192.168.1.83:8000/api/v1 » :
  /// c'est l'adresse que le serveur affiche au démarrage, et c'est elle que
  /// l'utilisateur a sous les yeux.
  static String _normaliser(String saisie) {
    var texte = saisie.trim();

    if (texte.isEmpty) return texte;

    if (!texte.startsWith('http://') && !texte.startsWith('https://')) {
      texte = 'http://$texte';
    }

    // Ni port ni chemin : on complète avec ceux du serveur de développement.
    // « https://maboko-api.onrender.com » est l'adresse du serveur ; les
    // routes vivent sous « /api/v1 ». Confondre les deux produit un 404 sur
    // chaque appel, sans rien qui explique pourquoi — le préfixe est donc
    // ajouté ici quand il manque.
    final uri = Uri.tryParse(texte);

    if (uri != null && uri.host.isNotEmpty) {
      final chemin = uri.path.replaceAll(RegExp(r'/+$'), '');

      // Le port de developpement n'est ajoute qu'a une adresse en clair et
      // sans port : une adresse de production en HTTPS garde le sien.
      final port = uri.hasPort
          ? ':${uri.port}'
          : uri.isScheme('http')
              ? ':8000'
              : '';

      texte = '${uri.scheme}://${uri.host}$port'
          '${chemin.isEmpty ? '/api/v1' : chemin}';
    }

    return texte.replaceAll(RegExp(r'/+$'), '');
  }

  static String? _valider(String adresse) {
    final uri = Uri.tryParse(adresse);

    if (uri == null || uri.host.isEmpty) return 'Adresse incompréhensible.';
    if (!uri.isScheme('http') && !uri.isScheme('https')) {
      return 'L’adresse doit commencer par http:// ou https://.';
    }

    return null;
  }
}
