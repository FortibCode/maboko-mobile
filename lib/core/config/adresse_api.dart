import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

/// Adresse de l'API réellement utilisée, modifiable sans recompiler.
class AdresseApi {
  const AdresseApi._();

  static const _cle = 'api_base_url';

  /// Adresse visée quand rien d'exploitable n'est configuré.
  static const _domaineDeSecours = 'https://maboko-api.onrender.com';
  static const _replis = '$_domaineDeSecours/api/v1';

  /// Valeur en vigueur, lue une fois au démarrage puis gardée en mémoire :
  /// chaque requête la consulte, elle ne peut pas être asynchrone.
  static String _courante = AppConfig.apiBaseUrl;

  /// Adresse réellement appelée, chemin des routes compris.
  static String get valeur => _normaliser(_courante);

  /// Adresse telle qu'elle a été configurée ou saisie.
  static String get valeurConfiguree => _courante;

  /// Vrai si l'adresse a été changée depuis l'application.
  static bool get personnalisee => valeur != valeurCompilee;

  static String get valeurCompilee => _normaliser(AppConfig.apiBaseUrl);

  /// À appeler au démarrage, avant la première requête.
  static Future<void> charger() async {
    if (AppConfig.isRelease) return;

    final prefs = await SharedPreferences.getInstance();
    final enregistree = prefs.getString(_cle)?.trim();

    if (enregistree != null && enregistree.isNotEmpty) {
      _courante = enregistree;
    }
  }

  /// Enregistre une nouvelle adresse.
  static Future<String?> definir(String saisie) async {
    if (AppConfig.isRelease) return 'Adresse non modifiable en production.';

    if (saisie.trim().isEmpty) return 'Adresse incompréhensible.';

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

  static String _normaliser(String saisie) {
    var texte = saisie.trim();

    if (texte.isEmpty) return _replis;

    if (!texte.startsWith('http://') && !texte.startsWith('https://')) {
      texte = 'http://$texte';
    }

    final uri = Uri.tryParse(texte);

    if (uri != null && uri.host.isNotEmpty) {
      final chemin = uri.path.replaceAll(RegExp(r'/+$'), '');

      final port = uri.hasPort
          ? ':${uri.port}'
          : uri.isScheme('http')
              ? ':8000'
              : '';

      texte = '${uri.scheme}://${uri.host}$port'
          '${chemin.isEmpty ? '/api/v1' : chemin}';
    }

    texte = texte.replaceAll(RegExp(r'/+$'), '');

    final controle = Uri.tryParse(texte);

    if (controle == null || !controle.hasScheme || controle.host.isEmpty) {
      return _replis;
    }

    return texte;
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