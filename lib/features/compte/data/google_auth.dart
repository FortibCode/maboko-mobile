import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api.dart';
import '../../../core/network/api_exception.dart';

/// Résultat d'une connexion Google réussie.
typedef SessionGoogle = ({String jeton, Map<String, dynamic> utilisateur});

/// Connexion via Google (§5.1.3).
///
/// L'application n'envoie jamais l'identité elle-même : elle transmet le jeton
/// signé par Google, que le serveur vérifie auprès de Google avant d'ouvrir la
/// session. Un client ne peut donc pas se déclarer propriétaire d'une adresse
/// qui ne lui appartient pas.
class GoogleAuth {
  const GoogleAuth();

  Future<SessionGoogle?> connecter() async {
    if (!AppConfig.googleDisponible) {
      throw ApiException(
        'La connexion Google n’est pas configurée sur cette version de '
        'l’application. Utilisez votre e-mail et votre mot de passe.',
      );
    }

    // serverClientId : c'est l'audience attendue par le serveur. Sans lui,
    // Google renvoie un jeton destiné à l'application Android, que la
    // vérification côté serveur rejetterait.
    final google = GoogleSignIn(
      serverClientId: AppConfig.googleClientId,
      scopes: const ['email', 'profile'],
    );

    final GoogleSignInAccount? compte;
    try {
      compte = await google.signIn();
    } catch (_) {
      throw ApiException(
        'La connexion Google a échoué. Vérifiez que les services Google Play '
        'sont disponibles sur cet appareil.',
      );
    }

    // L'utilisateur a fermé la fenêtre : ce n'est pas une erreur.
    if (compte == null) return null;

    final authentification = await compte.authentication;
    final idToken = authentification.idToken;

    if (idToken == null || idToken.isEmpty) {
      throw ApiException(
        'Google n’a pas fourni de jeton d’identité. Vérifiez la configuration '
        'OAuth du projet.',
      );
    }

    final reponse = await api.post('/login/google', corps: {'id_token': idToken})
        as Map<String, dynamic>;

    return (
      jeton: reponse['token'] as String? ?? '',
      utilisateur: (reponse['user'] as Map<String, dynamic>?) ?? const {},
    );
  }

  /// À appeler à la déconnexion, sinon Google reconnecte silencieusement le
  /// même compte au prochain essai.
  Future<void> deconnecter() async {
    if (!AppConfig.googleDisponible) return;

    try {
      await GoogleSignIn(serverClientId: AppConfig.googleClientId).signOut();
    } catch (_) {
      // La session locale prime : un échec ici ne doit pas bloquer la
      // déconnexion de l'application.
    }
  }
}
