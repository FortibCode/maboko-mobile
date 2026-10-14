import 'package:flutter/material.dart';

class Onboarding1 extends StatelessWidget {
  const Onboarding1({super.key});

  // Palette crème clair — fidèle à la maquette.
  static const Color beigeFond = Color(0xFFFAF4E7);      // fond général
  static const Color rosePeche = Color(0xFFEFB39D);      // cercle
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

              // Cercle pastel avec l'image loupe, posée au centre
              Container(
                width: 200,
                height: 200,
                decoration: const BoxDecoration(
                  color: rosePeche,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Image.asset(
                  'assets/images/loupe.jpeg',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.search_rounded,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Titre
              const Text(
                "Trouvez les meilleurs\nartisans",
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
                "Peintres, mécaniciens, couturiers,\nélectriciens... tous près de chez vous.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: texteDoux,
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Pagination
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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

              // Bouton Suivant
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, "/onboarding2"),
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