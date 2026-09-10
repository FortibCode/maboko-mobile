import 'package:flutter/material.dart';

import '../core/theme/maboko_theme.dart';
import '../core/widgets/photo_profil.dart';
import '../features/artisans/ui/favoris_screen.dart';
import '../features/artisans/ui/fiche_artisan_screen.dart';
import '../features/compte/data/profil_repository.dart';
import '../features/compte/ui/modifier_profil_screen.dart';
import '../features/compte/ui/moyens_paiement_screen.dart';
import '../features/courses/ui/historique_courses_screen.dart';
import '../features/demandes/ui/demandes_screen.dart';
import '../features/messagerie/ui/conversations_screen.dart';
import '../features/notifications/ui/notifications_screen.dart';
import '../features/abonnement/ui/abonnement_screen.dart';
import '../features/identite/ui/verification_identite_screen.dart';
import '../features/tableau_bord/ui/tableau_bord_artisan_screen.dart';
import 'a_propos_screen.dart';
import 'portfolio_screen.dart';
import 'settings_screen.dart';

/// Tiroir de navigation du client.
///
/// Il dégage la barre du bas, qui portait dix entrées empilées dans l'onglet
/// Profil. Les destinations secondaires vivent ici ; les quatre parcours
/// quotidiens restent dans la barre.
class TiroirNavigation extends StatelessWidget {
  const TiroirNavigation({
    super.key,
    required this.profil,
    required this.nomSecours,
    required this.onDeconnexion,
    required this.estClient,
    this.onPhotoModifiee,
  });

  final ProfilUtilisateur? profil;
  final String nomSecours;

  /// Les deux rôles partagent la coquille mais pas leurs destinations : un
  /// artisan n'a que faire de « Mes courses », un client de « Mon portfolio ».
  final bool estClient;

  final VoidCallback onDeconnexion;
  final VoidCallback? onPhotoModifiee;

  String get _nom =>
      profil?.nomComplet.isNotEmpty == true ? profil!.nomComplet : nomSecours;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            _entete(context),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _rubrique(context, 'Mon activité'),
                  if (estClient) ...[
                    _lien(context, Icons.business_outlined, 'Mes demandes & missions',
                        const DemandesScreen(estArtisan: false)),
                    _lien(context, Icons.local_taxi_outlined, 'Mes courses Allô Chauffeur',
                        const HistoriqueCoursesScreen()),
                    _lien(context, Icons.favorite_border_rounded, 'Mes artisans de confiance',
                        const FavorisScreen()),
                  ] else ...[
                    _lien(context, Icons.assignment_outlined, 'Missions reçues',
                        const DemandesScreen(estArtisan: true)),
                    _lien(context, Icons.insights_rounded, 'Mon activité',
                        const TableauBordArtisanScreen()),
                    _lien(context, Icons.photo_library_outlined, 'Mon portfolio',
                        const PortfolioScreen()),
                    _lien(context, Icons.handyman_outlined, 'Mes métiers et ma zone',
                        const FicheArtisanScreen(modification: true)),
                  ],

                  const Divider(height: 20, indent: 16, endIndent: 16),
                  _rubrique(context, 'Mon compte'),
                  _lien(context, Icons.person_outline_rounded, 'Modifier mon profil',
                      const ModifierProfilScreen()),
                  if (!estClient) ...[
                    _lien(context, Icons.workspace_premium_outlined, 'Mon abonnement',
                        const AbonnementScreen()),
                    _lien(context, Icons.verified_user_outlined, 'Vérifier mon identité',
                        const VerificationIdentiteScreen()),
                  ],
                  _lien(context, Icons.account_balance_wallet_outlined, 'Moyens de paiement',
                      const MoyensPaiementScreen()),
                  _lien(context, Icons.notifications_none_rounded, 'Notifications',
                      const NotificationsScreen()),

                  const Divider(height: 20, indent: 16, endIndent: 16),
                  _rubrique(context, 'Aide'),
                  _lien(context, Icons.support_agent_rounded, 'Aide & Support',
                      const ConversationsScreen()),
                  _lien(context, Icons.info_outline_rounded, 'À propos de Maboko',
                      const AProposScreen()),
                  _lien(context, Icons.settings_outlined, 'Paramètres',
                      const SettingsScreen()),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: MabokoCouleurs.danger),
              title: const Text(
                'Se déconnecter',
                style: TextStyle(color: MabokoCouleurs.danger, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                onDeconnexion();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _entete(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MabokoCouleurs.principale, Color(0xFF2E1A0F)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PhotoProfil(
            url: profil?.avatarUrl,
            nom: _nom,
            taille: 64,
            onModifier: onPhotoModifiee == null
                ? null
                : () {
                    Navigator.pop(context);
                    onPhotoModifiee!();
                  },
          ),
          const SizedBox(height: 14),
          Text(
            _nom,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            profil?.localisation ?? profil?.email ?? 'Compte Maboko',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _rubrique(BuildContext context, String titre) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Text(
        titre.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
          color: context.texteSecondaireMaboko,
        ),
      ),
    );
  }

  Widget _lien(BuildContext context, IconData icone, String libelle, Widget destination) {
    return ListTile(
      dense: true,
      leading: Icon(icone, color: MabokoCouleurs.secondaire, size: 21),
      title: Text(libelle, style: const TextStyle(fontSize: 14)),
      onTap: () {
        // Le tiroir se ferme avant la navigation, sinon il reste ouvert
        // derrière l'écran appelé au retour.
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
      },
    );
  }
}
