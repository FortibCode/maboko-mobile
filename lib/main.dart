import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'core/config/adresse_api.dart';
import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'splash_screen.dart';
import 'login_page.dart';
import 'onboarding1.dart';
import 'onboarding2.dart';
import 'onboarding3.dart';
import 'profile_choice.dart';
import 'forgot_password.dart';
import 'register_page.dart';
import 'screens/home_page.dart';
import 'artisan_onboarding_screen.dart';
import 'features/courses/ui/chauffeur_shell.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
// import 'core/session/role_utilisateur.dart';  ❌ SUPPRIMÉ
import 'core/theme/controleur_theme.dart';

/// Cle globale du navigateur, necessaire pour ramener l'utilisateur vers
/// l'ecran de connexion depuis la couche reseau, sans contexte de widget.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Bascule clair / sombre, partagee par toute l'application.
final ControleurTheme controleurTheme = ControleurTheme();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ApiClient.onSessionExpiree = () {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  };

  await AdresseApi.charger();

  AppConfig.verifierConfiguration(AdresseApi.valeur);

  await controleurTheme.charger();

  await NotificationService.initialiser();

  runApp(const MabokoApp());
}

class MabokoApp extends StatelessWidget {
  const MabokoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controleurTheme,
      builder: (contexte, _) => MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Maboko',
        debugShowCheckedModeBanner: false,
        themeMode: controleurTheme.mode,
        darkTheme: MabokoThemes.sombre,
        theme: MabokoThemes.clair,

        // Sur le Web, l'application demarre sur la route du fragment (#/register…).
        // Sur mobile, elle demarre sur le splash.
        initialRoute: kIsWeb ? null : '/',

        routes: {
          "/": (context) => const SplashScreenWithTimer(),
          "/login": (context) => const LoginPage(),
          "/onboarding1": (context) => const Onboarding1(),
          "/onboarding2": (context) => const Onboarding2(),
          "/onboarding3": (context) => const Onboarding3(),
          "/profile-choice": (context) => const ProfileChoice(),
          "/artisan-onboarding": (context) => const ArtisanOnboarding(),
          "/forgot": (context) => const ForgotPasswordPage(),
          "/register": (context) => const RegisterPage(),
          "/chauffeur": (context) => const ChauffeurShell(),
        },

        onGenerateRoute: (settings) {
          if (settings.name == '/home') {
            final args = settings.arguments as Map<String, dynamic>?;

            return MaterialPageRoute(
              builder: (context) => HomePage(
                avatarName: args?['avatarName'] ?? "Utilisateur",
                userRole: args?['userRole'] ?? 'client',
              ),
            );
          }

          if (kIsWeb) {
            return MaterialPageRoute(
              settings: const RouteSettings(name: '/'),
              builder: (context) => const SplashScreenWithTimer(),
            );
          }

          return null;
        },
      ),
    );
  }
}

// SplashScreen avec vérification de la session utilisateur
class SplashScreenWithTimer extends StatefulWidget {
  const SplashScreenWithTimer({super.key});

  @override
  State<SplashScreenWithTimer> createState() => _SplashScreenWithTimerState();
}

class _SplashScreenWithTimerState extends State<SplashScreenWithTimer> {
  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Temps d'affichage du SplashScreen (4 secondes)
    await Future.delayed(const Duration(milliseconds: 4000));

    if (!mounted) return;

    // ⚠️ MODE TEST — RÉINITIALISATION À CHAQUE DÉMARRAGE
    //
    // On efface le jeton stocké pour forcer la reconnexion.
    // Avantages :
    //  - On ne peut plus être coincé dans l'espace d'un compte
    //    dont la fiche est cassée (cas du chauffeur sans fiche).
    //  - Idéal pour tester plusieurs rôles (client, artisan, chauffeur)
    //    en se déconnectant/reconnectant rapidement.
    //
    // Inconvénient :
    //  - Les vrais utilisateurs doivent se reconnecter à chaque
    //    ouverture de l'application.
    //
    // 👉 POUR REVENIR AU COMPORTEMENT NORMAL (auto-login) :
    //    Supprime la ligne `await StorageService.deconnecter();` ci-dessous
    //    et remets la logique « ouvrirEspace » d'origine.
    await StorageService.deconnecter();

    if (!mounted) return;

    // On regarde si l'onboarding a déjà été vu
    final onboardingDone = await StorageService.isOnboardingCompleted();

    if (!mounted) return;

    if (onboardingDone) {
      // L'utilisateur connaît l'app → connexion directe
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Première visite → choix du profil puis onboarding
      Navigator.pushReplacementNamed(context, '/profile-choice');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}