// Fichier : lib/screens/avatar_selection_screen.dart
import 'package:flutter/material.dart';

class AvatarSelectionScreen extends StatefulWidget {
  final String userRole;
  final String userName;
  final String userId;

  const AvatarSelectionScreen({
    super.key,
    this.userRole = "client",
    this.userName = "",
    this.userId = "",
  });

  @override
  State<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  int _selectedAvatarIndex = 0;
  late TextEditingController _nameController;

  // Définition des 2 images d'avatars personnalisées (.jpg)
  final List<String> _avatarAssets = const [
    'assets/images/emojiF.jpg',
    'assets/images/emojiG.jpg',
  ];

  @override
  void initState() {
    super.initState();
    // Nom par défaut pour le profil client
    _nameController = TextEditingController(text: "Mon Profil Client");
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4E7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Choisissez votre Avatar",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Choisissez votre avatar et saisissez votre nom d'utilisateur.",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                // Aperçu de l'avatar sélectionné
                Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3E5D8),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      _avatarAssets[_selectedAvatarIndex],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.person,
                        size: 50,
                        color: Color(0xFFB35B28),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Champ de saisie du nom de profil client
                TextField(
                  controller: _nameController,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: "Nom du Profil",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFB35B28), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 25),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "CHOISISSEZ UN AVATAR",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 10),

                // Sélection des 2 avatars (emojiF.jpg et emojiG.jpg)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_avatarAssets.length, (index) {
                    bool isSelected = _selectedAvatarIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatarIndex = index),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? const Color(0xFFB35B28) : Colors.grey.shade300,
                            width: isSelected ? 3 : 1,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: const Color(0xFFB35B28).withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                          ],
                        ),
                        child: ClipOval(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              _avatarAssets[index],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => const Icon(
                                Icons.person,
                                color: Color(0xFFB35B28),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 40),

                // Bouton de validation (ne mène nulle part pour l'instant)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      String name = _nameController.text.trim();
                      if (name.isEmpty) name = "Client";
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/home',
                        (route) => false,
                        arguments: {
                          'avatarName': name,
                          'avatarIndex': _selectedAvatarIndex,
                          'userRole': 'client',
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB35B28),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text(
                      "Accéder à l'accueil",
                      style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
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
