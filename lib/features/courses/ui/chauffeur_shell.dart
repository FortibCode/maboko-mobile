import 'package:flutter/material.dart';

import '../../../core/network/api.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/session/role_utilisateur.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../services/storage_service.dart';
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
///
/// Depuis cette version : un bouton « Se déconnecter » est présent dans la
/// barre d'application. Sans lui, un chauffeur dont la fiche n'existe pas
/// restait piégé dans un écran qui ne chargeait jamais.
class ChauffeurShell extends StatefulWidget {
  const ChauffeurShell({super.key});

  @override
  State<ChauffeurShell> createState() => _ChauffeurShellState();
}

class _ChauffeurShellState extends State<ChauffeurShell> {
  int _onglet = 0;
  bool _deconnexionEnCours = false;

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

  /// Déconnexion : confirmation → appel API (best-effort) → purge locale →
  /// retour à l'écran de connexion.
  Future<void> _seDeconnecter() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Se déconnecter ?'),
        content: const Text(
          'Vous devrez vous reconnecter pour accéder à votre espace chauffeur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: MabokoCouleurs.danger,
              foregroundColor: Colors.white,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;

    setState(() => _deconnexionEnCours = true);

    // 1. Révocation côté serveur (best-effort : on continue même si le
    //    réseau est coupé, l'utilisateur veut partir *maintenant*).
    try {
      await api.post('/logout', corps: const {});
    } on ApiException {
      // Ignoré volontairement.
    } catch (_) {
      // Ignoré volontairement.
    }

    // 2. Purge locale.
    await StorageService.deconnecter();

    if (!mounted) return;

    // 3. Retour à l'écran de connexion, en purgeant toute la pile.
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Espace chauffeur'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Se déconnecter',
            onPressed: _deconnexionEnCours ? null : _seDeconnecter,
            icon: _deconnexionEnCours
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.2,
                    ),
                  )
                : const Icon(Icons.logout_rounded),
          ),
        ],
      ),
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