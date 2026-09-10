// Fichier : lib/screens/profile_choice.dart
import 'package:flutter/material.dart';

import 'core/theme/maboko_theme.dart';

class ProfileChoice extends StatelessWidget {
  const ProfileChoice({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBrown = Color(0xFFB35B28);
    final Color backgroundColor = context.fondMaboko;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Élément visuel d'en-tête subtil
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5D8).withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    size: 36,
                    color: primaryBrown,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Logo de l'application
              Center(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                      letterSpacing: -0.5,
                    ),
                    children: [
                      TextSpan(text: "mabok", style: TextStyle(color: primaryBrown)),
                      TextSpan(text: "o", style: TextStyle(color: Color(0xFFEAA023))),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Sous-titre
              Text(
                "Comment souhaitez-vous utiliser l'application ?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: context.texteSecondaireMaboko,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 48),

              // Option Client
              _buildCard(
                context,
                title: "Je suis à la recherche d'un artisan",
                subtitle: "Je cherche des professionnels qualifiés pour mes projets",
                icon: Icons.search_rounded,
                primaryColor: primaryBrown,
                onTap: () {
                  Navigator.pushNamed(context, '/onboarding1');
                },
              ),
              const SizedBox(height: 18),

              // Option Artisan
              _buildCard(
                context,
                title: "Je suis un Artisan",
                subtitle: "Je propose mes services et gère mon portfolio",
                icon: Icons.handyman_rounded,
                primaryColor: primaryBrown,
                onTap: () {
                  Navigator.pushNamed(context, '/artisan-onboarding');
                },
              ),
              const SizedBox(height: 18),

              // Option Chauffeur — le rôle existait côté API et côté écrans,
              // mais aucun parcours d'inscription n'y menait.
              _buildCard(
                context,
                title: "Je suis Chauffeur",
                subtitle: "Je transporte des passagers avec Allô Chauffeur",
                icon: Icons.local_taxi_rounded,
                primaryColor: primaryBrown,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/register',
                    arguments: const {'userRole': 'chauffeur'},
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    required VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceMaboko,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5D8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: primaryColor, size: 28),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: context.texteSecondaireMaboko,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
