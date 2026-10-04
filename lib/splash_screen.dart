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
    // Palette marron & beige — alignée sur la page de connexion du web.
    const Color beigeFond = Color(0xFFFFFDF8);      // fond clair / cercle du logo
    const Color beigeChaud = Color(0xFFE8D5C0);     // sous-titre
    const Color orMaboko = Color(0xFFEAA023);       // accent doré
    const Color terracotta = Color(0xFFB35B28);     // marron principal

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A2A18), // Marron foncé en haut
              Color(0xFF7A3F1D), // Marron moyen intermédiaire
              Color(0xFFB35B28), // Terracotta en bas
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
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
                      // Le logo entier, dans son cercle.
                      //
                      // Le probleme n'etait pas le cercle mais le rognage :
                      // « cover » remplissait le disque avec le symbole et
                      // poussait le mot « maboko » et la signature hors
                      // cadre. « contain » a l'interieur d'un carre inscrit
                      // dans le cercle — cote = diametre / racine de 2 —
                      // laisse le logo complet.
                      //
                      // Le disque reprend le creme du logo lui-meme : le bord
                      // carre de l'image se fond dedans, on ne voit que le
                      // cercle.
                      Container(
                        width: 210,
                        height: 210,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: beigeFond,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 25,
                              spreadRadius: 5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/maboko_logo_carre.png',
                            width: 152,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.handshake,
                              size: 80,
                              color: terracotta,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Titre principal
                      const Text(
                        "Bienvenue sur\nMaboko",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Sous-titre "Les mains qui font le Congo" avec la petite barre dorée
                      const Text(
                        "Les mains qui font le Congo",
                        style: TextStyle(
                          fontSize: 15,
                          color: beigeChaud,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 35,
                        height: 3,
                        decoration: BoxDecoration(
                          color: orMaboko,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Description
                      Text(
                        "La plateforme qui connecte les artisans\net leurs clients partout au Congo.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                      
                      const Spacer(),

                      // 3 Badges de fonctionnalités en bas
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFeatureItem(Icons.verified_user_rounded, "Fiable\net sécurisé"),
                          _buildFeatureItem(Icons.groups_rounded, "Artisans\nde confiance"),
                          _buildFeatureItem(Icons.favorite_rounded, "Un Congo\nqui avance"),
                        ],
                      ),
                      
                      const SizedBox(height: 30),

                      // Un indicateur, pas un bouton : la redirection est automatique
                      // (voir SplashScreenWithTimer). Le bouton « Découvrir »
                      // qui se trouvait ici appelait clearAll() : il deconnectait
                      // l'utilisateur deja identifie s'il y touchait.
                      const SizedBox(
                        height: 32,
                        width: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(orMaboko),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SizedBox(height: 25),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget utilitaire pour les 3 petites icônes du bas
  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.9),
            height: 1.2,
          ),
        ),
      ],
    );
  }
}