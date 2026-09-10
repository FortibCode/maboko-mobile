import 'package:flutter/material.dart';

import '../core/theme/maboko_theme.dart';
import '../core/network/api_exception.dart';
import '../features/abonnement/ui/abonnement_screen.dart';
import '../features/demandes/ui/demandes_screen.dart';
import '../features/courses/ui/historique_courses_screen.dart';
import '../features/courses/ui/reservation_course_screen.dart';
import '../features/fil/ui/fil_screen.dart';
import '../features/identite/ui/verification_identite_screen.dart';
import '../features/messagerie/ui/conversations_screen.dart';
import '../features/metiers/data/metier_repository.dart';
import '../features/metiers/models/metier.dart';
import '../features/metiers/ui/explorer_screen.dart';
import '../features/metiers/ui/visuel_metier.dart';
import '../features/artisans/ui/artisans_par_metier_screen.dart';
import '../features/tableau_bord/data/tableau_bord_repository.dart';
import '../core/widgets/choix_photo.dart';
import '../core/session/role_utilisateur.dart';
import '../features/artisans/ui/favoris_screen.dart';
import '../features/artisans/ui/fiche_artisan_screen.dart';
import '../features/notifications/ui/notifications_screen.dart';
import '../core/widgets/photo_profil.dart';
import '../features/compte/data/profil_repository.dart';
import '../features/tableau_bord/models/tableau_bord.dart';
import '../features/tableau_bord/ui/tableau_bord_artisan_screen.dart';
import 'portfolio_screen.dart';
import 'settings_screen.dart';
import '../services/storage_service.dart';
import '../features/compte/data/google_auth.dart';
import '../features/notifications/data/notification_repository.dart';
import 'tiroir_navigation.dart';
import '../main.dart' show controleurTheme;
import '../features/compte/ui/moyens_paiement_screen.dart';
import '../core/widgets/carte_pressable.dart';

class HomePage extends StatefulWidget {
  final String avatarName;
  final String userRole;

  const HomePage({
    super.key,
    required this.avatarName,
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

  /// Profil réel du compte : photo, localisation, coordonnées.
  ProfilUtilisateur? _profil;

  /// Raccourcis vers les métiers les plus recherchés (§5.1.4).
  List<Metier> _metiers = const [];

  /// Ouvre le tiroir depuis la barre haute, qui n'est pas un AppBar.
  final GlobalKey<ScaffoldState> _cleEchafaudage = GlobalKey<ScaffoldState>();

  int _notificationsNonLues = 0;
  bool _envoiPhoto = false;


  @override
  void initState() {
    super.initState();
    _chargerTableauBord();
    _chargerProfil();
    _chargerMetiers();
    _chargerNotifications();
  }

  Future<void> _chargerMetiers() async {
    try {
      final liste = await const MetierRepository().lister();
      if (!mounted) return;
      setState(() => _metiers = liste.take(8).toList());
    } catch (_) {
      // Les raccourcis sont un confort : l'onglet « Découvrir » reste
      // accessible si le référentiel ne répond pas.
    }
  }

  Future<void> _chargerNotifications() async {
    try {
      final resultat = await const NotificationRepository().lister();
      if (!mounted) return;
      setState(() => _notificationsNonLues = resultat.nonLues);
    } catch (_) {
      // Le compteur est un confort : son échec ne doit rien bloquer.
    }
  }

  Future<void> _chargerProfil() async {
    try {
      final profil = await const ProfilRepository().moi();
      if (!mounted) return;

      // Le serveur fait autorité sur le rôle. Si l'interface ouverte n'est pas
      // celle du compte, on bascule au lieu de rester sur un espace qui ne lui
      // correspond pas — et dont aucune action n'aboutirait.
      final bascule = await realignerSurLeServeur(
        context,
        roleServeur: profil.role,
        roleAffiche: RoleMaboko.depuis(widget.userRole),
        nom: profil.nomComplet.isNotEmpty ? profil.nomComplet : widget.avatarName,
      );
      if (bascule || !mounted) return;

      setState(() => _profil = profil);
    } catch (_) {
      // Le profil enrichit l'écran sans le conditionner : en cas d'échec on
      // garde les initiales et le nom déjà connus localement.
    }
  }

  Future<void> _changerPhoto() async {
    final photo = await choisirPhoto(context);
    if (photo == null || !mounted) return;

    setState(() => _envoiPhoto = true);

    try {
      final url = await const ProfilRepository().enregistrerPhoto(photo);
      if (!mounted) return;

      setState(() {
        _envoiPhoto = false;
        _profil = _profil == null
            ? null
            : ProfilUtilisateur(
                id: _profil!.id,
                nomComplet: _profil!.nomComplet,
                role: _profil!.role,
                avatarUrl: url,
                ville: _profil!.ville,
                quartier: _profil!.quartier,
                email: _profil!.email,
                telephone: _profil!.telephone,
              );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo de profil mise à jour.'),
          backgroundColor: MabokoCouleurs.succes,
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _envoiPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    }
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
    await const GoogleAuth().deconnecter();
    await StorageService.clearToken();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  // Formate 'artisan_menuisier' en 'Menuisier'
  String _getFormattedRoleLabel() {
    if (!RoleMaboko.depuis(widget.userRole).estArtisan) return "Client";
    String rawTrade = widget.userRole.replaceAll('artisan_', '').trim();
    if (rawTrade.isEmpty) return "Artisan";
    return rawTrade[0].toUpperCase() + rawTrade.substring(1);
  }

  // Récupère l'icône de profil sélectionnée lors de l'enregistrement

  /// Barre supérieure du fil : accès au tiroir, marque, et les trois actions
  /// que l'utilisateur cherche le plus souvent — notifications, thème, profil.
  Widget _barreHaut() {
    final sombre = controleurTheme.estSombre(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 10, 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded),
            tooltip: 'Menu',
            onPressed: () => _cleEchafaudage.currentState?.openDrawer(),
          ),
          RichText(
            text: const TextSpan(
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, fontFamily: 'serif'),
              children: [
                TextSpan(text: "mabok", style: TextStyle(color: MabokoCouleurs.secondaire)),
                TextSpan(text: "o", style: TextStyle(color: MabokoCouleurs.accent)),
              ],
            ),
          ),
          const Spacer(),

          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Rechercher un métier ou un artisan',
            // La recherche vit dans l'onglet Découvrir, qui interroge le
            // référentiel complet plutôt que le fil affiché.
            onPressed: () => setState(() => _currentIndex = 1),
          ),

          // Le compteur de non-lues évite d'ouvrir l'écran pour rien.
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                tooltip: 'Notifications',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                  );
                  await _chargerNotifications();
                },
              ),
              if (_notificationsNonLues > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    constraints: const BoxConstraints(minWidth: 17),
                    decoration: BoxDecoration(
                      color: MabokoCouleurs.danger,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                    ),
                    child: Text(
                      _notificationsNonLues > 99 ? '99+' : '$_notificationsNonLues',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          IconButton(
            icon: Icon(sombre ? Icons.light_mode_rounded : Icons.dark_mode_outlined),
            tooltip: sombre ? 'Passer en clair' : 'Passer en sombre',
            onPressed: () => controleurTheme.basculer(context),
          ),

          // La photo mène au tiroir : c'est là que vit tout le compte.
          Padding(
            padding: const EdgeInsets.only(left: 2),
            child: GestureDetector(
              onTap: () => _cleEchafaudage.currentState?.openDrawer(),
              child: PhotoProfil(
                url: _profil?.avatarUrl,
                nom: _profil?.nomComplet.isNotEmpty == true
                    ? _profil!.nomComplet
                    : widget.avatarName,
                taille: 36,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Le rôle est lu explicitement : « client » ne se déduit plus de
    // « ne contient pas artisan », qui rangeait dans l'espace client tout ce
    // qui n'était pas prévu.
    final role = RoleMaboko.depuis(widget.userRole);
    final bool isClient = !role.estArtisan;

    return Scaffold(
      key: _cleEchafaudage,
      drawer: TiroirNavigation(
        estClient: isClient,
        profil: _profil,
        nomSecours: widget.avatarName,
        onDeconnexion: _logout,
        onPhotoModifiee: _changerPhoto,
      ),
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
            // --- ONGLET 0 : ACCUEIL ---
            //
            // Le client arrive sur le fil d'actualité (§5.1.4), l'artisan sur
            // son tableau de bord (§5.2.1). Les deux recevaient le fil : un
            // artisan qui se connectait atterrissait donc dans l'espace
            // client, avec « Explorer par métier » et « Allô Chauffeur ».
            if (!isClient)
              TableauBordArtisanScreen(enTete: _barreHaut())
            else
            FilScreen(
              enTete: Column(
                children: [
                  _barreHaut(),
                  // Accès rapide aux métiers les plus recherchés (§5.1.4).
                  //
                  // La bande était collée sous la barre et tronquée au bord
                  // droit : rien n'indiquait qu'elle défilait. Elle a
                  // desormais un en-tête, de l'air, et un lien « Tout voir ».
                  if (_metiers.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 12, 2),
                      child: Row(
                        children: [
                          Text(
                            'Explorer par métier',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.titleMedium?.color,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => setState(() => _currentIndex = 1),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Tout voir',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: MabokoCouleurs.secondaire,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 104,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        // La dernière carte s'arrête avant le bord : on voit
                        // qu'il reste quelque chose à faire défiler.
                        padding: const EdgeInsets.fromLTRB(20, 6, 28, 10),
                        itemCount: _metiers.length,
                        separatorBuilder: (contexte, index) => const SizedBox(width: 14),
                        itemBuilder: (contexte, i) => _CarteMetierAccueil(
                          metier: _metiers[i],
                          rang: i,
                        ),
                      ),
                    ),
                  ],
                  // Bandeau Allô Chauffeur : réserver une course en un clic
                  // depuis l'accueil (§5.1.4).
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                    child: CartePressable(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReservationCourseScreen()),
                      ),
                      echelle: 0.985,
                      child: Material(
                        color: MabokoCouleurs.accent.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_taxi_rounded, color: MabokoCouleurs.accent),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Allô Chauffeur',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                                    Text('Moto ou voiture, près de chez vous',
                                        style: TextStyle(
                                            fontSize: 12, color: context.texteSecondaireMaboko)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),


            // --- ONGLET 1 : « Découvrir » (§5.1.5) côté client,
            // « Missions reçues » (§5.2.2) côté artisan ---
            if (isClient)
              const ExplorerScreen()
            else
              const DemandesScreen(estArtisan: true),

            // --- ONGLET 2 : MESSAGERIE (§5.1.9) ---
            const ConversationsScreen(),

            // --- ONGLET 3 : PROFIL ---
            SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Affichage de l'avatar sélectionné lors de la configuration
                  _envoiPhoto
                      ? const SizedBox(
                          width: 90,
                          height: 90,
                          child: Center(
                            child: CircularProgressIndicator(color: MabokoCouleurs.secondaire),
                          ),
                        )
                      : PhotoProfil(
                          url: _profil?.avatarUrl,
                          nom: _profil?.nomComplet.isNotEmpty == true
                              ? _profil!.nomComplet
                              : widget.avatarName,
                          onModifier: _changerPhoto,
                        ),
                  const SizedBox(height: 15),
                  Text(
                    widget.avatarName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isClient
                        ? (_profil?.localisation ?? "Localisation non renseignée")
                        : "Artisan • ${_getFormattedRoleLabel()}",
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
                        color: context.surfaceMaboko,
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
                      color: context.surfaceMaboko,
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
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Accueil"),
          if (isClient)
            const BottomNavigationBarItem(icon: Icon(Icons.grid_view), label: "Découvrir")
          else
            const BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined), label: "Missions"),
          const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Messages"),
          const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Profil"),
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
        color: context.surfaceMaboko,
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
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).textTheme.titleLarge?.color)),
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
        // Les entrées sans destination ont été retirées plutôt que laissées
        // inertes : « Boutiques de matériaux », « Conseils & astuces »,
        // « Mes enregistrements », « Mes avis » et le choix de langue n'ont
        // aucun service derrière eux. Un bouton qui ne répond pas est pire
        // qu'une absence : il fait douter du reste de l'application.
        _buildMenuItem(Icons.favorite_border, "Mes artisans de confiance", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FavorisScreen()),
          );
        }),
        // Historique des courses Allô Chauffeur (§5.1.10) : l'API le renvoyait
        // deja, mais aucun ecran client ne l'affichait.
        _buildMenuItem(Icons.local_taxi_outlined, "Mes courses Allô Chauffeur", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HistoriqueCoursesScreen()),
          );
        }),
        _buildMenuItem(Icons.account_balance_wallet_outlined, "Moyens de paiement", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MoyensPaiementScreen()),
          );
        }),
        _buildMenuItem(Icons.notifications_none, "Notifications", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const NotificationsScreen()),
          );
        }),
        _buildMenuItem(Icons.help_outline, "Aide & Support", onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ConversationsScreen()),
          );
        }),
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
        // Le metier choisi a l'inscription n'etait plus modifiable ensuite :
        // un artisan qui ajoutait une corde a son arc restait catalogue.
        ListTile(
          leading: const Icon(Icons.handyman_outlined, color: Color(0xFFB35B28)),
          title: const Text("Mes métiers et ma zone"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FicheArtisanScreen(modification: true),
              ),
            );
            await _chargerTableauBord();
          },
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

/// Carte de métier de l'accueil.
///
/// Les couleurs viennent du thème : la même carte doit rester lisible en clair
/// comme en sombre, ce que ne permettait pas un fond blanc écrit en dur.
class _CarteMetierAccueil extends StatelessWidget {
  const _CarteMetierAccueil({required this.metier, required this.rang});

  final Metier metier;
  final int rang;

  @override
  Widget build(BuildContext context) {
    final sombre = Theme.of(context).brightness == Brightness.dark;

    return ApparitionDecalee(
      rang: rang,
      child: CartePressable(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArtisansParMetierScreen(
              slugMetier: metier.slug,
              titre: metier.nom,
            ),
          ),
        ),
        child: SizedBox(
          width: 84,
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: sombre
                      ? null
                      : [
                          BoxShadow(
                            color: MabokoCouleurs.principale.withValues(alpha: 0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                ),
                child: VisuelMetier(metier: metier, taille: 62, tailleIcone: 27),
              ),
              const SizedBox(height: 8),
              Text(
                metier.nom,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
