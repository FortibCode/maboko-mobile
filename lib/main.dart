import 'dart:async';

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
import 'core/session/role_utilisateur.dart';
import 'core/theme/controleur_theme.dart';

/// Cle globale du navigateur, necessaire pour ramener l'utilisateur vers
/// l'ecran de connexion depuis la couche reseau, sans contexte de widget.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Bascule clair / sombre, partagee par toute l'application.
final ControleurTheme controleurTheme = ControleurTheme();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Le controle de securite porte sur l'adresse reellement utilisee : il doit
  // donc venir apres la lecture du reglage, pas avant.

  // Un jeton expire ou revoque ramene immediatement a la connexion, au lieu
  // de laisser l'utilisateur sur un ecran qui ne chargera jamais.
  ApiClient.onSessionExpiree = () {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  };

  // Le mode enregistre est relu avant le premier rendu, pour eviter que
  // l'application s'ouvre en clair puis bascule sous les yeux de l'utilisateur.
  // L'adresse du serveur peut avoir ete corrigee depuis les parametres :
  // le poste de developpement change d'adresse a chaque bail DHCP.
  await AdresseApi.charger();

  // Refuse de demarrer une compilation de production configuree pour parler
  // a l'API en HTTP : le paragraphe 7.1 impose le chiffrement systematique.
  AppConfig.verifierConfiguration(AdresseApi.valeur);

  await controleurTheme.charger();

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
        initialRoute: "/",
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
          // Espace chauffeur : meme application, coquille dediee.
          "/chauffeur": (context) => const ChauffeurShell(),
        },
        // Gestion dynamique de la HomePage avec transmission des arguments
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

    // Récupération du token sauvegardé dans le StorageService
    final token = await StorageService.getToken();

    if (token != null && token.isNotEmpty) {
      // Utilisateur DÉJÀ connecté : chargement des préférences enregistrées
      final name = await StorageService.getUserName() ?? "Utilisateur";
      final role = await StorageService.getUserRole() ?? "client";

      if (!mounted) return;

      // Le rôle vient du stockage local, qui peut avoir vieilli. L'espace
      // ouvert se corrige de lui-même dès que le serveur a répondu.
      ouvrirEspace(context, RoleMaboko.depuis(role), nom: name);

      return;
    }

    // Utilisateur NON connecté : on regarde si l'onboarding a déjà été vu
    final onboardingDone = await StorageService.isOnboardingCompleted();

    if (!mounted) return;

    if (onboardingDone) {
      // Déjà découvert l'application : connexion directe
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      // Première découverte de l'application
      Navigator.pushReplacementNamed(context, '/profile-choice');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
