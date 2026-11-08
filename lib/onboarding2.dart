import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Onboarding2 extends StatelessWidget {
  const Onboarding2({super.key});

  static const Color orMaboko = Color(0xFFEAA023);
  static const Color texteMarron = Color(0xFF4A2A18);

  static const Color gradientHaut = Color(0xFF3B1F0E);
  static const Color gradientMilieu = Color(0xFF6B3318);
  static const Color gradientBas = Color(0xFFB35B28);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: gradientHaut,
      body: Stack(
        children: [
          // ── Image plein-écran, partie haute ──────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.58,
            child: Image.asset(
              'assets/images/I1.jpeg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: gradientMilieu,
                child: const Icon(Icons.photo_camera_rounded, size: 80, color: Colors.white30),
              ),
            ),
          ),

          // ── Fondu bas de l'image vers le gradient ────────────────────
          Positioned(
            top: size.height * 0.32,
            left: 0,
            right: 0,
            height: size.height * 0.28,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, gradientHaut],
                ),
              ),
            ),
          ),

          // ── Fond gradient sous l'image ───────────────────────────────
          Positioned(
            top: size.height * 0.55,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gradientHaut, gradientMilieu, gradientBas],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ── Contenu superposé ────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // Bouton « Passer »
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 4),
                    child: TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/onboarding3'),
                      child: const Text(
                        'Passer',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          shadows: [Shadow(color: Colors.black45, blurRadius: 6)],
                        ),
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Indicateurs de pagination
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _point(actif: false),
                    const SizedBox(width: 6),
                    _point(actif: true),
                    const SizedBox(width: 6),
                    _point(actif: false),
                  ],
                ),
                const SizedBox(height: 24),

                // Bouton Suivant
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/onboarding3'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: texteMarron,
                        elevation: 6,
                        shadowColor: Colors.black38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Suivant',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: texteMarron,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18, color: texteMarron),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _point({required bool actif}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: actif ? 22 : 6,
      height: 6,
      decoration: BoxDecoration(
        color: actif ? orMaboko : Colors.white38,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}