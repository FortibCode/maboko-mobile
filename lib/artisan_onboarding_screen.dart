// Fichier : lib/artisan_onboarding.dart
import 'package:flutter/material.dart';

class ArtisanOnboarding extends StatelessWidget {
  const ArtisanOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBrown = Color(0xFFB35B28);
    const Color backgroundColor = Color(0xFFFAF4E7);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3E5D8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.handyman_outlined,
                    size: 64,
                    color: primaryBrown,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "Développez votre activité\navec maboko.com",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Trouvez de nouveaux clients, présentez votre savoir-faire à travers votre portfolio et gérez vos chantiers facilement.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Emmène vers l'écran de personnalisation (ArtisanProfileChoiceScreen)
                    Navigator.pushNamed(context, '/artisan-profile-choice');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBrown,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Commencer",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
