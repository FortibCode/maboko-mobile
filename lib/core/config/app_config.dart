/// Configuration d'execution de l'application.
///
/// L'adresse de l'API n'est plus ecrite en dur dans les ecrans : elle est
/// injectee au moment de la compilation, ce qui permet d'utiliser le meme
/// code source en developpement, en preproduction et en production.
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
///   flutter build apk --dart-define=API_BASE_URL=https://api.maboko.cg/api/v1
class AppConfig {
  const AppConfig._();

  /// Adresse de base de l'API, prefixe de version compris.
  ///
  /// La valeur par defaut vise l'emulateur Android, ou 10.0.2.2 designe la
  /// machine hote. Sur un telephone physique, passer l'adresse du poste de
  /// developpement sur le reseau local.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  /// Duree maximale d'attente d'une reponse. Volontairement genereuse :
  /// le cahier de charges vise un usage en 3G degradee a Brazzaville.
  static const Duration timeout = Duration(seconds: 30);

  /// Vrai lorsque l'application est compilee en mode release.
  static const bool isRelease = bool.fromEnvironment('dart.vm.product');

  /// En production, l'API doit obligatoirement etre jointe en HTTPS :
  /// le paragraphe 7.1 du cahier de charges impose le chiffrement
  /// systematique des donnees utilisateurs.
  static bool get transportEstSecurise => apiBaseUrl.startsWith('https://');

  /// Leve une erreur au demarrage si une compilation de production est
  /// configuree pour parler a l'API en clair. Mieux vaut un echec visible
  /// qu'une application qui transmet des mots de passe en HTTP.
  static void verifierConfiguration() {
    if (isRelease && !transportEstSecurise) {
      throw StateError(
        'Configuration refusee : une compilation de production doit viser une '
        'API en HTTPS. Valeur recue : $apiBaseUrl',
      );
    }
  }
}
