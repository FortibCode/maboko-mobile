import 'dart:async';

import 'package:flutter/material.dart';

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
import 'screens/avatar_selection_screen.dart';
import 'artisan_onboarding_screen.dart'; 
import 'artisan_profile_choice_screen.dart';
import 'services/storage_service.dart';

/// Cle globale du navigateur, necessaire pour ramener l'utilisateur vers
/// l'ecran de connexion depuis la couche reseau, sans contexte de widget.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Refuse de demarrer une compilation de production configuree pour parler
  // a l'API en HTTP : le paragraphe 7.1 impose le chiffrement systematique.
  AppConfig.verifierConfiguration();

  // Un jeton expire ou revoque ramene immediatement a la connexion, au lieu
  // de laisser l'utilisateur sur un ecran qui ne chargera jamais.
  ApiClient.onSessionExpiree = () {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  };

  runApp(const MabokoApp());
}

class MabokoApp extends StatelessWidget {
  const MabokoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Maboko Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFB35B28),
        scaffoldBackgroundColor: const Color(0xFFFAF4E7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFB35B28),
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFB35B28),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFB35B28),
          ),
        ),
      ),
      initialRoute: "/",
      routes: {
        "/": (context) => const SplashScreenWithTimer(),
        "/login": (context) => const LoginPage(),
        "/onboarding1": (context) => const Onboarding1(),
        "/onboarding2": (context) => const Onboarding2(),
        "/onboarding3": (context) => const Onboarding3(),
        "/profile-choice": (context) => const ProfileChoice(),
        "/avatar_selection": (context) => const AvatarSelectionScreen(),
        
        // 2. Correction ici : l'onboarding arrive en premier
        "/artisan-onboarding": (context) => const ArtisanOnboarding(),
        // 3. Et la page de choix de profil vient juste après
        "/artisan-profile-choice": (context) => const ArtisanProfileChoiceScreen(),

        "/forgot": (context) => const ForgotPasswordPage(),
        "/register": (context) => const RegisterPage(),
      },
      // Gestion dynamique de la HomePage avec transmission des arguments
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final args = settings.arguments as Map<String, dynamic>?;

          return MaterialPageRoute(
            builder: (context) => HomePage(
              avatarName: args?['avatarName'] ?? "Utilisateur",
              avatarIndex: args?['avatarIndex'] ?? 0,
              userRole: args?['userRole'] ?? 'client',
            ),
          );
        }
        return null;
      },
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
      final avatarIndex = await StorageService.getAvatarIndex() ?? 0;

      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/home',
        arguments: {
          'avatarName': name,
          'avatarIndex': avatarIndex,
          'userRole': role,
        },
      );
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
