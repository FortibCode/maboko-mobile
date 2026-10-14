import 'package:flutter/material.dart';

class Onboarding2 extends StatelessWidget {
  const Onboarding2({super.key});

  static const Color beigeFond = Color(0xFFFAF4E7);
  static const Color terracotta = Color(0xFFC15A2A);
  static const Color texteFort = Color(0xFF4A2A18);
  static const Color texteDoux = Color(0xFF7A6A5C);
  static const Color pointInactif = Color(0xFFD5C4B0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: beigeFond,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, "/onboarding3"),
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

              // L'image contient déjà son cercle pastel.
              Image.asset(
                'assets/images/Appareil.jpeg',
                width: 220,
                height: 220,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 48),

              const Text(
                "Découvrez leurs\nréalisations",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: texteFort,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                "Photos avant/après, vidéos, portfolios\ncomplets pour choisir en confiance.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: texteDoux,
                  height: 1.5,
                ),
              ),

              const Spacer(),

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
                    width: 22,
                    height: 6,
                    decoration: BoxDecoration(
                      color: terracotta,
                      borderRadius: BorderRadius.circular(3),
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
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, "/onboarding3"),
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
                        "Suivant",
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