/// Configuration d'execution de l'application.
class AppConfig {
  const AppConfig._();

  /// Adresse de base de l'API, prefixe de version compris.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://maboko-api.onrender.com',
  );

  /// Identifiant client OAuth du projet Google Cloud (§5.1.3).
  static const String googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

  static bool get googleDisponible => googleClientId.isNotEmpty;

  /// Serveur WebSocket Reverb, pour la messagerie en temps réel (§7.2).
  static const String reverbHost = String.fromEnvironment('REVERB_HOST', defaultValue: 'maboko-api.onrender.com');
  static const int reverbPort = int.fromEnvironment('REVERB_PORT', defaultValue: 8080);
  static const String reverbKey = String.fromEnvironment('REVERB_KEY');
  static const bool reverbTls = bool.fromEnvironment('REVERB_TLS');

  /// Le temps réel n'est tenté que si une clé a été fournie à la compilation.
  static bool get tempsReelDisponible => reverbKey.isNotEmpty;

  static String get reverbUrl =>
      '${reverbTls ? 'wss' : 'ws'}://$reverbHost:$reverbPort/app/$reverbKey'
      '?protocol=7&client=flutter&version=1.0';

  /// Duree maximale d'attente d'une reponse.
  static const Duration timeout = Duration(seconds: 30);

  /// Vrai lorsque l'application est compilee en mode release.
  static const bool isRelease = bool.fromEnvironment('dart.vm.product');

  /// En production, l'API doit obligatoirement etre jointe en HTTPS.
  static bool estSecurise(String adresse) => adresse.startsWith('https://');

  static void verifierConfiguration(String adresseEffective) {
    if (isRelease && !estSecurise(adresseEffective)) {
      throw StateError(
        'Configuration refusee : une compilation de production doit viser une '
        'API en HTTPS. Valeur recue : $adresseEffective',
      );
    }
  }
}