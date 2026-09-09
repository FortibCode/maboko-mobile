import 'package:flutter/material.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/theme/maboko_theme.dart';
import 'features/courses/ui/chauffeur_accueil_screen.dart';
import 'login_page.dart';
import 'services/storage_service.dart';

/// Point d'entrée de l'application chauffeur « Allô Chauffeur » (§10.1).
///
/// Le cahier de charges attend deux applications distinctes sur les stores.
/// Plutôt que deux projets Flutter, un second point d'entrée dans le même
/// projet : deux binaires, deux fiches, mais l'authentification, le thème et
/// le client HTTP restent partagés.
///
/// Reste à faire pour la publication : identifiants applicatifs, icônes et
/// fiches de store propres à chaque flavor, côté Android et iOS.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.verifierConfiguration();

  ApiClient.onSessionExpiree = () {
    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false);
  };

  runApp(const MabokoChauffeurApp());
}

class MabokoChauffeurApp extends StatelessWidget {
  const MabokoChauffeurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Allô Chauffeur',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: MabokoCouleurs.secondaire,
        scaffoldBackgroundColor: MabokoCouleurs.fond,
        appBarTheme: const AppBarTheme(
          backgroundColor: MabokoCouleurs.secondaire,
          foregroundColor: Colors.white,
        ),
      ),
      routes: {'/login': (context) => const LoginPage()},
      home: const _RedirectionChauffeur(),
    );
  }
}

/// Ouvre directement l'espace chauffeur si une session existe.
class _RedirectionChauffeur extends StatefulWidget {
  const _RedirectionChauffeur();

  @override
  State<_RedirectionChauffeur> createState() => _RedirectionChauffeurState();
}

class _RedirectionChauffeurState extends State<_RedirectionChauffeur> {
  bool? _connecte;

  @override
  void initState() {
    super.initState();
    _verifier();
  }

  Future<void> _verifier() async {
    final jeton = await StorageService.getToken();
    if (!mounted) return;
    setState(() => _connecte = jeton != null && jeton.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return switch (_connecte) {
      null => const Scaffold(
          backgroundColor: MabokoCouleurs.fond,
          body: Center(child: CircularProgressIndicator(color: MabokoCouleurs.secondaire)),
        ),
      true => const ChauffeurAccueilScreen(),
      false => const LoginPage(),
    };
  }
}
