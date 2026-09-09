import 'package:flutter/material.dart';

import '../core/theme/maboko_theme.dart';
import '../core/network/api_exception.dart';
import '../features/abonnement/ui/abonnement_screen.dart';
import '../features/demandes/ui/demandes_screen.dart';
import '../features/courses/ui/reservation_course_screen.dart';
import '../features/fil/ui/fil_screen.dart';
import '../features/identite/ui/verification_identite_screen.dart';
import '../features/messagerie/ui/conversations_screen.dart';
import '../features/metiers/ui/explorer_screen.dart';
import '../features/tableau_bord/data/tableau_bord_repository.dart';
import '../features/tableau_bord/models/tableau_bord.dart';
import '../features/tableau_bord/ui/tableau_bord_artisan_screen.dart';
import 'portfolio_screen.dart';
import 'settings_screen.dart';
import '../services/storage_service.dart';

class HomePage extends StatefulWidget {
  final String avatarName;
  final int avatarIndex;
  final String userRole;

  const HomePage({
    super.key,
    required this.avatarName,
    required this.avatarIndex,
    this.userRole = 'client',
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _tableauBord = TableauBordRepository();

  int _currentIndex = 0;

  /// Compteurs du profil. Null tant qu'ils ne sont pas chargés : ils étaient
  /// auparavant écrits en dur dans le code (« 12 Favoris, 3 Messages »).
  TableauBord? _bord;
  // Liste des icônes d'avatars synchronisée avec AvatarSelectionScreen
  final List<IconData> _artisanAvatars = const [
    Icons.construction,
    Icons.engineering,
    Icons.precision_manufacturing,
    Icons.handyman,
    Icons.build_circle,
    Icons.home_repair_service,
    Icons.architecture,
    Icons.design_services,
  ];

  final List<IconData> _clientAvatars = const [
    Icons.face_3,
    Icons.face_6,
    Icons.face,
    Icons.person,
    Icons.account_circle,
    Icons.emoji_emotions,
    Icons.sentiment_very_satisfied,
    Icons.portrait,
  ];

  @override
  void initState() {
    super.initState();
    _chargerTableauBord();
  }

  Future<void> _chargerTableauBord() async {
    try {
      final bord = await _tableauBord.charger();
      if (!mounted) return;
      setState(() => _bord = bord);
    } on ApiException {
      // Les compteurs ne sont pas essentiels à l'affichage du profil :
      // en cas d'échec, ils restent à « — » plutôt que de bloquer l'écran.
    }
  }

  Future<void> _logout() async {
    await StorageService.clearToken();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // Formate 'artisan_menuisier' en 'Menuisier'
  String _getFormattedRoleLabel() {
    if (!widget.userRole.contains('artisan')) return "Client";
    String rawTrade = widget.userRole.replaceAll('artisan_', '').trim();
    if (rawTrade.isEmpty) return "Artisan";
    return rawTrade[0].toUpperCase() + rawTrade.substring(1);
  }

  // Récupère l'icône de profil sélectionnée lors de l'enregistrement
  IconData _getSelectedAvatarIcon(bool isClient) {
    final list = isClient ? _clientAvatars : _artisanAvatars;
    if (widget.avatarIndex >= 0 && widget.avatarIndex < list.length) {
      return list[widget.avatarIndex];
    }
    return isClient ? Icons.person : Icons.handyman;
  }

  @override
  Widget build(BuildContext context) {
    final bool isClient = !widget.userRole.toLowerCase().contains('artisan');

    return Scaffold(
      backgroundColor: const Color(0xFFFAF4E7),
      // Bouton de création rapide pour les artisans sur la vue Accueil
      floatingActionButton: (!isClient && _currentIndex == 0)
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PortfolioScreen()),
                );
              },
              backgroundColor: const Color(0xFFB35B28),
              icon: const Icon(Icons.add_a_photo, color: Colors.white),
              label: const Text("Publier", style: TextStyle(color: Colors.white)),
            )
          : null,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // --- ONGLET 0 : FIL D'ACTUALITÉ (§5.1.4) ---
            // Les publications viennent de l'API. Elles étaient auparavant
            // écrites en dur dans ce fichier.
            FilScreen(
              enTete: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'serif'),
                        children: [
                          TextSpan(text: "maboko", style: TextStyle(color: MabokoCouleurs.secondaire)),
                          TextSpan(text: ".com", style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    ),
                        IconButton(
                          icon: const Icon(Icons.search, color: Colors.black87),
                          tooltip: 'Rechercher un métier ou un artisan',
                          // La recherche vit dans l'onglet Découvrir, qui
                          // interroge le référentiel complet plutôt que le
                          // fil affiché.
                          onPressed: () => setState(() => _currentIndex = 1),
                        ),
                      ],
                    ),
                  ),
                  // Bandeau Allô Chauffeur : réserver une course en un clic
                  // depuis l'accueil (§5.1.4).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: Material(
                      color: MabokoCouleurs.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ReservationCourseScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.5)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.local_taxi_rounded, color: MabokoCouleurs.accent),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Allô Chauffeur',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                                    Text('Moto ou voiture, près de chez vous',
                                        style: TextStyle(
                                            fontSize: 12, color: MabokoCouleurs.texteSecondaire)),
                                  ],
                                ),
                              ),
                              Icon(Icons.arrow_forward_ios, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),


            // --- ONGLET 1 : DÉCOUVRIR (§5.1.5) ---
            const ExplorerScreen(),

            // --- ONGLET 2 : MESSAGERIE (§5.1.9) ---
            const ConversationsScreen(),

            // --- ONGLET 3 : PROFIL ---
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Affichage de l'avatar sélectionné lors de la configuration
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3E5D8),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        _getSelectedAvatarIcon(isClient),
                        size: 45,
                        color: const Color(0xFFB35B28),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    widget.avatarName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isClient ? "Bacongo, Brazzaville" : "Artisan • ${_getFormattedRoleLabel()}",
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB35B28),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Statistiques
                  if (isClient) ...[
                    Row(
                      children: [
                        Expanded(child: _buildClientStatCard(_compteur(_bord?.compteurs.total), "Demandes", Icons.business_outlined, MabokoCouleurs.secondaire)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildClientStatCard(_compteur(_bord?.favoris), "Favoris", Icons.favorite, Colors.red)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildClientStatCard(_compteur(_bord?.avisDeposes), "Avis donnés", Icons.star, Colors.amber.shade700)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem("Missions", _compteur(_bord?.compteurs.terminees)),
                          _buildStatItem("En attente", _compteur(_bord?.compteurs.enAttente)),
                          _buildStatItem(
                            "Note",
                            _bord == null
                                ? "—"
                                : (_bord!.nbAvis == 0 ? "—" : _bord!.noteMoyenne.toStringAsFixed(1)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Menu dynamique du Profil
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
                    ),
                    child: isClient ? _buildClientProfileMenu() : _buildArtisanProfileMenu(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFFB35B28),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Accueil"),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Découvrir"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Messages"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profil"),
        ],
      ),
    );
  }

  /// Un compteur non encore chargé s'affiche par un tiret, jamais par un zéro
  /// qui ferait croire à une valeur réelle.
  String _compteur(int? valeur) => valeur?.toString() ?? '—';

  Widget _buildClientStatCard(String value, String label, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildClientProfileMenu() {
    return Column(
      children: [
        _buildMenuItem(Icons.business_outlined, "Mes demandes & missions", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DemandesScreen(estArtisan: false)),
          );
        }),
        _buildMenuItem(Icons.favorite_border, "Mes artisans de confiance"),
        _buildMenuItem(Icons.bookmark_border, "Mes enregistrements"),
        _buildMenuItem(Icons.storefront_outlined, "Boutiques de matériaux"),
        _buildMenuItem(Icons.lightbulb_outline, "Conseils & astuces"),
        _buildMenuItem(Icons.star_border, "Mes avis"),
        _buildMenuItem(Icons.notifications_none, "Notifications"),
        _buildMenuItem(Icons.language, "Langue (Français/Lingala/Kituba)"),
        _buildMenuItem(Icons.help_outline, "Aide & Support"),
        _buildMenuItem(Icons.settings_outlined, "Paramètres avancés", onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
        }),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: Colors.red),
          title: const Text("Se déconnecter", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _buildArtisanProfileMenu() {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.assignment_outlined, color: MabokoCouleurs.secondaire),
          title: const Text("Missions reçues"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DemandesScreen(estArtisan: true)),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.star_rounded, color: Color(0xFFB35B28)),
          title: const Text("Mon Abonnement"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AbonnementScreen()),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.verified_user_outlined, color: MabokoCouleurs.secondaire),
          title: const Text("Vérifier mon identité"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VerificationIdentiteScreen()),
          ),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.business_center_rounded, color: Color(0xFFB35B28)),
          title: const Text("Mon activité"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TableauBordArtisanScreen()),
            );
            await _chargerTableauBord();
          },
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.photo_library_rounded, color: Color(0xFFB35B28)),
          title: const Text("Mon Portfolio"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PortfolioScreen())),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.settings_outlined, color: Color(0xFFB35B28)),
          title: const Text("Paramètres"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen())),
        ),
        const Divider(height: 1),
        ListTile(
          leading: const Icon(Icons.logout_rounded, color: Colors.red),
          title: const Text("Se déconnecter", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: const Color(0xFFB35B28), size: 22),
          title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          onTap: onTap ?? () {},
        ),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

}