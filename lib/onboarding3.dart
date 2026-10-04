// Fichier : lib/screens/onboarding3.dart
import 'package:flutter/material.dart';
import 'services/storage_service.dart';

class Onboarding3 extends StatelessWidget {
  const Onboarding3({super.key});

  // Palette marron & beige — alignée sur les autres écrans.
  static const Color terracotta = Color(0xFFB35B28);
  static const Color beigeFond = Color(0xFFFFFDF8);

  @override
  Widget build(BuildContext context) {
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),

                // Image agrandie avec cercle de fond et ombre douce
                Container(
                  width: 210,
                  height: 210,
                  decoration: BoxDecoration(
                    color: beigeFond, // Fond beige chaleureux
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 25,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.forum_rounded,
                      size: 96,
                      color: terracotta,
                    ),
                  ),
                ),
                const SizedBox(height: 35),

                // Titre principal
                const Text(
                  "Contactez-les directement",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Sous-titre exact
                Text(
                  "Messagerie intégrée ou WhatsApp. Avis\nvérifiés. Travail garanti.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 30),

                // Indicateurs de page (troisième point actif modernisé)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 22,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Bouton Commencer en bas aux bords arrondis harmonisés
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      await StorageService.saveOnboardingCompleted(true);
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        "/register",
                        (route) => false,
                        arguments: {'userRole': 'client'},
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: terracotta,
                      foregroundColor: Colors.white,
                      elevation: 5,
                      shadowColor: terracotta.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Commencer",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.check_circle_outline_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}