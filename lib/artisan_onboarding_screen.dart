// Fichier : lib/artisan_onboarding.dart
import 'package:flutter/material.dart';

import 'core/theme/maboko_theme.dart';

class ArtisanOnboarding extends StatelessWidget {
  const ArtisanOnboarding({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBrown = Color(0xFFB35B28);
    final Color backgroundColor = context.fondMaboko;

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
              Text(
                "Développez votre activité\navec Maboko",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'serif',
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Trouvez de nouveaux clients, présentez votre savoir-faire à travers votre portfolio et gérez vos chantiers facilement.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: context.texteSecondaireMaboko,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Direction l'inscription. L'ecran de « vitrine » qui se
                    // trouvait ici demandait un metier et une photo avant
                    // qu'un compte existe : rien ne pouvait etre enregistre,
                    // et l'envoi de photo aurait ete refuse faute de jeton.
                    // Le metier se choisit desormais apres le code de
                    // verification, quand il y a un compte pour le porter.
                    Navigator.pushNamed(
                      context,
                      '/register',
                      arguments: {'userRole': 'artisan'},
                    );
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
