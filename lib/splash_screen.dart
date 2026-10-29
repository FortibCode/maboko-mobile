// Fichier : lib/splash_screen.dart
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Configuration de l'animation d'apparition
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Palette crème clair — alignée sur les onboardings.
    const Color beigeFond = Color(0xFFFAF4E7);      // fond général
    const Color beigeChaud = Color(0xFFE8D5C0);     // cercle derrière le logo
    const Color orMaboko = Color(0xFFEAA023);       // accent doré
    const Color texteFort = Color(0xFF4A2A18);      // marron foncé
    const Color texteDoux = Color(0xFF7A6A5C);      // gris chaud

    return Scaffold(
      backgroundColor: beigeFond,
      body: Stack(
        children: [
          // 1. Le contenu existant (centré)
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),

                        // Logo dans son cercle beige chaud
                        Container(
                          width: 220,
                          height: 220,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: beigeChaud,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/maboko_logo_carre.png',
                              width: 160,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.handshake_rounded,
                                size: 90,
                                color: texteFort,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Titre principal — marron foncé
                        const Text(
                          "Bienvenue sur\nMaboko",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: texteFort,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Sous-titre
                        const Text(
                          "Les mains qui font le Congo",
                          style: TextStyle(
                            fontSize: 15,
                            color: texteDoux,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Petite barre dorée
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: orMaboko,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Description
                        const Text(
                          "La plateforme qui connecte les artisans\net leurs clients partout au Congo.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: texteDoux,
                            height: 1.5,
                          ),
                        ),

                        const Spacer(),

                        // Indicateur de chargement (doré)
                        const SizedBox(
                          height: 32,
                          width: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(orMaboko),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 👇 2. NOUVEAU BOUTON "PASSER" (en haut à droite) 👇
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () {
                    // Redirection vers l'inscription
                    // (Si ta route s'appelle /inscription ou autre, remplace '/register' par le bon nom)
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: texteFort,
                    backgroundColor: Colors.black.withValues(alpha: 0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Passer',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // 👆 FIN DU BOUTON "PASSER" 👆
        ],
      ),
    );
  }
}