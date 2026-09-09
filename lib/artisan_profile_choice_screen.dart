// Fichier : lib/artisan_profile_choice_screen.dart
import 'package:flutter/material.dart';
import 'services/storage_service.dart';

class ArtisanProfileChoiceScreen extends StatefulWidget {
  const ArtisanProfileChoiceScreen({super.key});

  @override
  State<ArtisanProfileChoiceScreen> createState() => _ArtisanProfileChoiceScreenState();
}

class _ArtisanProfileChoiceScreenState extends State<ArtisanProfileChoiceScreen> {
  // Contrôleur pour modifier le nom de l'artisan / de l'atelier
  late TextEditingController _nameController;

  // Liste des icônes de métiers pour la grille
  final List<Map<String, dynamic>> _artisanIcons = [
    {"icon": Icons.handyman_outlined, "label": "Général"},
    {"icon": Icons.build_outlined, "label": "Outils"},
    {"icon": Icons.construction_outlined, "label": "BTP"},
    {"icon": Icons.home_repair_service_outlined, "label": "Atelier"},
    {"icon": Icons.handyman, "label": "Menuiserie"},
    {"icon": Icons.format_paint_outlined, "label": "Peinture"},
    {"icon": Icons.settings_suggest_outlined, "label": "Technique"},
    {"icon": Icons.engineering_outlined, "label": "Expert"},
  ];

  int _selectedIndex = 4; // Index 4 pour Menuiserie par défaut

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: "Mon Entreprise / Atelier");
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBrown = Color(0xFFB35B28);
    const Color backgroundColor = Color(0xFFFAF4E7);
    const Color cardBg = Colors.white;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Titre principal
              const Text(
                "Personnalisez votre vitrine\nartisan",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              
              // Sous-titre
              Text(
                "Vous pourrez la remplacer par une vraie photo plus tard",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Aperçu central de la vitrine (Icône)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF3E5D8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _artisanIcons[_selectedIndex]["icon"],
                    size: 45,
                    color: primaryBrown,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Champ de saisie modifiable pour le nom de l'artisan
              TextField(
                controller: _nameController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBrown),
                decoration: InputDecoration(
                  labelText: "Nom de votre activité",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: primaryBrown, width: 2),
                  ),
                  filled: true,
                  fillColor: cardBg,
                ),
              ),
              const SizedBox(height: 24),

              // Libellé de la grille
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "CHOISISSEZ UNE ICÔNE DE MÉTIER",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Grille des icônes de métiers
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _artisanIcons.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final bool isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? primaryBrown : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        _artisanIcons[index]["icon"],
                        color: isSelected ? primaryBrown : Colors.grey.shade700,
                        size: 26,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),

              // Bouton Prendre une vraie photo
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Fonctionnalité photo bientôt disponible"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: primaryBrown, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_outlined, color: primaryBrown, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Prendre une vraie photo",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: primaryBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Bouton de validation (inefficace pour l'instant comme demandé)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    String name = _nameController.text.trim();
                    if (name.isEmpty) name = "Artisan";
                    await StorageService.saveOnboardingCompleted(true);
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/register',
                      (route) => false,
                      arguments: {
                        'userRole': 'artisan',
                        'avatarName': name,
                        'avatarIndex': _selectedIndex,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBrown,
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: primaryBrown.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Commencer à explorer maboko.com",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
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
