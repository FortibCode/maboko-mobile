import 'package:flutter/material.dart';

import '../../../core/session/role_utilisateur.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../compte/data/profil_repository.dart';
import '../../messagerie/ui/conversations_screen.dart';
import 'chauffeur_accueil_screen.dart';
import 'profil_chauffeur_screen.dart';

/// Espace chauffeur, à l'intérieur de l'application unique.
///
/// Il remplace `main_driver.dart`, un second point d'entrée qui n'a jamais été
/// buildable : aucun flavor Android ni schéma iOS n'a été créé pour lui. Le
/// chauffeur se connectait donc dans l'application principale et atterrissait
/// sur l'interface client.
class ChauffeurShell extends StatefulWidget {
  const ChauffeurShell({super.key});

  @override
  State<ChauffeurShell> createState() => _ChauffeurShellState();
}

class _ChauffeurShellState extends State<ChauffeurShell> {
  int _onglet = 0;

  @override
  void initState() {
    super.initState();
    _verifierLeRole();
  }

  /// Le serveur tranche : un compte qui n'est pas chauffeur n'a rien à faire
  /// ici, et toutes ses requêtes seraient refusées. Le rôle qui a conduit à
  /// cet écran vient du stockage du téléphone, qui peut avoir vieilli.
  Future<void> _verifierLeRole() async {
    try {
      final profil = await const ProfilRepository().moi();
      if (!mounted) return;

      await realignerSurLeServeur(
        context,
        roleServeur: profil.role,
        roleAffiche: RoleMaboko.chauffeur,
        nom: profil.nomComplet,
      );
    } catch (_) {
      // Réseau indisponible : on laisse l'espace ouvert plutôt que d'éjecter
      // un chauffeur légitime hors ligne.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      body: IndexedStack(
        index: _onglet,
        children: const [
          ChauffeurAccueilScreen(),
          ConversationsScreen(),
          ProfilChauffeurScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _onglet,
        onTap: (i) => setState(() => _onglet = i),
        type: BottomNavigationBarType.fixed,
        backgroundColor: context.surfaceMaboko,
        selectedItemColor: MabokoCouleurs.secondaire,
        unselectedItemColor: context.texteSecondaireMaboko,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), label: 'Courses'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
