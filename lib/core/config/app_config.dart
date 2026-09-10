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
  /// La valeur par defaut vise le poste de developpement sur le reseau local.
  /// Elle remplace 10.0.2.2, qui n'existe qu'a l'interieur de l'emulateur
  /// Android : sur un telephone physique cette adresse ne mene nulle part et
  /// l'application restait suspendue trente secondes avant d'accuser le reseau
  /// du telephone. L'adresse du reseau local, elle, fonctionne dans les deux
  /// cas — emulateur comme appareil reel.
  ///
  /// A changer si le routeur attribue une autre adresse au poste :
  ///   flutter run --dart-define=API_BASE_URL=http://<ip-du-poste>:8000/api/v1
  ///
  /// Une compilation de production est de toute facon refusee au demarrage si
  /// elle vise une API en clair (voir verifierConfiguration).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.1.76:8000/api/v1',
  );

  /// Identifiant client OAuth du projet Google Cloud (§5.1.3).
  ///
  /// Sur Android, le jeton d'identite doit porter l'audience du client « Web »
  /// du projet, pas celle du client Android : c'est cette valeur que le serveur
  /// verifie. Elle se recupere dans la console Google Cloud et n'est pas un
  /// secret — elle voyage dans chaque requete d'authentification.
  ///
  ///   flutter run --dart-define=GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com
  ///
  /// Laissee vide, le bouton Google explique ce qui manque au lieu d'echouer
  /// sans raison visible.
  static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

  static bool get googleDisponible => googleClientId.isNotEmpty;

  /// Serveur WebSocket Reverb, pour la messagerie en temps réel (§7.2).
  ///
  ///   flutter run --dart-define=REVERB_HOST=10.0.2.2 --dart-define=REVERB_KEY=...
  static const String reverbHost = String.fromEnvironment('REVERB_HOST', defaultValue: '192.168.1.76');
  static const int reverbPort = int.fromEnvironment('REVERB_PORT', defaultValue: 8080);
  static const String reverbKey = String.fromEnvironment('REVERB_KEY');
  static const bool reverbTls = bool.fromEnvironment('REVERB_TLS');

  /// Le temps réel n'est tenté que si une clé a été fournie à la compilation.
  /// Sans elle, l'application se rabat sur l'interrogation périodique.
  static bool get tempsReelDisponible => reverbKey.isNotEmpty;

  static String get reverbUrl =>
      '${reverbTls ? 'wss' : 'ws'}://$reverbHost:$reverbPort/app/$reverbKey'
      '?protocol=7&client=flutter&version=1.0';

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
