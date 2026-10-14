// Fichier : lib/onboarding3.dart
import 'package:flutter/material.dart';
import 'services/storage_service.dart';

class Onboarding3 extends StatelessWidget {
  const Onboarding3({super.key});

  // Palette crème clair — fidèle à la maquette.
  static const Color beigeFond = Color(0xFFFAF4E7);      // fond général
  static const Color vertSauge = Color(0xFFC8D6C0);      // cercle
  static const Color terracotta = Color(0xFFC15A2A);     // bouton + point actif
  static const Color texteFort = Color(0xFF4A2A18);      // titres
  static const Color texteDoux = Color(0xFF7A6A5C);      // sous-titres
  static const Color pointInactif = Color(0xFFD5C4B0);   // pagination

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beigeFond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // Lien "Passer" en haut à droite
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
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
                  child: const Text(
                    "Passer",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: texteFort,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Cercle vert sauge avec l'image message
              Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  color: vertSauge,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/message.jpeg',
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Titre
              const Text(
                "Contactez-les\ndirectement",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: texteFort,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // Sous-titre
              const Text(
                "Messagerie intégrée ou WhatsApp. Avis\nvérifiés. Travail garanti.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: texteDoux,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Pagination — troisième point actif
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: pointInactif,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: pointInactif,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 22,
                    height: 6,
                    decoration: BoxDecoration(
                      color: terracotta,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Bouton Commencer
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
                    elevation: 0,
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
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}