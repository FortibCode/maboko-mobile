import 'package:flutter/material.dart';

import '../core/config/adresse_api.dart';
import '../core/config/app_config.dart';
import '../core/config/reglage_adresse.dart';
import '../core/theme/maboko_theme.dart';

import '../services/storage_service.dart';
import '../features/messagerie/ui/conversations_screen.dart';
import 'a_propos_screen.dart';
import '../features/compte/ui/modifier_profil_screen.dart';
import '../features/notifications/ui/notifications_screen.dart';
import 'confidentialite_screen.dart';
import '../features/compte/data/google_auth.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Paramètres", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFFB35B28),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            "Préférences du compte",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.surfaceMaboko,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline, color: Color(0xFFB35B28)),
                  title: const Text("Modifier mon profil"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ModifierProfilScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: Color(0xFFB35B28)),
                  title: const Text("Mes notifications"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.lock_outline, color: Color(0xFFB35B28)),
                  title: const Text("Confidentialité et sécurité"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ConfidentialiteScreen()),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Support & Aide",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: context.surfaceMaboko,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Color(0xFFB35B28)),
                  title: const Text("Centre d'aide"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ConversationsScreen()),
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Color(0xFFB35B28)),
                  title: const Text("À propos de Maboko"),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AProposScreen()),
                  ),
                ),
              ],
            ),
          ),

          // Reglage de developpement : l'adresse du poste change a chaque
          // bail DHCP, et l'application ne joignait plus rien jusqu'a une
          // recompilation. Absent des compilations de production.
          if (!AppConfig.isRelease) ...[
            const SizedBox(height: 24),
            const Text(
              "Développement",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: context.surfaceMaboko,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
              ),
              child: StatefulBuilder(
                builder: (contexte, rafraichir) => ListTile(
                  leading: const Icon(Icons.dns_outlined, color: Color(0xFFB35B28)),
                  title: const Text("Adresse du serveur"),
                  subtitle: Text(
                    AdresseApi.valeur,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: contexte.texteSecondaireMaboko),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    await ouvrirReglageAdresse(contexte);
                    rafraichir(() {});
                  },
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),
          // Bouton de déconnexion
          Container(
            decoration: BoxDecoration(
              color: context.surfaceMaboko,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout_rounded, color: Colors.red),
              title: const Text(
                "Se déconnecter",
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onTap: () async {
                await const GoogleAuth().deconnecter();
                await StorageService.clearToken();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, "/login");
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
