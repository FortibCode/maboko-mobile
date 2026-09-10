import 'package:flutter/material.dart';

import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../../../services/storage_service.dart';
import '../data/course_repository.dart';
import '../models/course.dart';
import 'fiche_chauffeur_screen.dart';
import 'historique_chauffeur_screen.dart';
import '../../compte/data/google_auth.dart';

/// Profil du chauffeur.
///
/// Les chauffeurs n'avaient aucun écran de compte : ils ne pouvaient ni vérifier
/// le véhicule enregistré sous leur nom, ni consulter leurs revenus, ni se
/// déconnecter ailleurs que depuis la barre d'accueil.
class ProfilChauffeurScreen extends StatefulWidget {
  const ProfilChauffeurScreen({super.key});

  @override
  State<ProfilChauffeurScreen> createState() => _ProfilChauffeurScreenState();
}

class _ProfilChauffeurScreenState extends State<ProfilChauffeurScreen> {
  final _depot = const CourseRepository();

  EtatChauffeur? _fiche;
  RevenusChauffeur? _revenus;
  String? _nom;
  String? _email;
  String? _telephone;
  String? _erreur;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final resultats = await Future.wait([
        _depot.etatChauffeur(),
        _depot.revenus(),
        StorageService.getUserName(),
        StorageService.getUserEmail(),
        StorageService.getUserTelephone(),
      ]);

      if (!mounted) return;
      setState(() {
        _fiche = resultats[0] as EtatChauffeur;
        _revenus = resultats[1] as RevenusChauffeur;
        _nom = resultats[2] as String?;
        _email = resultats[3] as String?;
        _telephone = resultats[4] as String?;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.toString();
        _chargement = false;
      });
    }
  }

  Future<void> _confirmerDeconnexion() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (contexte) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Se déconnecter ?'),
        content: const Text('Vous devrez saisir à nouveau vos identifiants pour reprendre des courses.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexte, false),
            child: const Text('Rester connecté'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MabokoCouleurs.danger),
            onPressed: () => Navigator.pop(contexte, true),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;

    await const GoogleAuth().deconnecter();
    await StorageService.clearToken();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        color: MabokoCouleurs.secondaire,
        child: _corps(),
      ),
    );
  }

  Widget _corps() {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          EtatErreur(message: _erreur!, onReessayer: _charger),
        ],
      );
    }

    final fiche = _fiche;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _enTete(),
        const SizedBox(height: 16),

        if (fiche?.ficheManquante ?? false)
          _bandeauFicheManquante()
        else ...[
          _carteVehicule(fiche!),
          const SizedBox(height: 16),
        ],

        _carteRevenus(),
        const SizedBox(height: 12),
        // L'historique detaille des courses effectuees (§5.3.4) : la liste
        // etait deja telechargee, aucun ecran ne la montrait.
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoriqueChauffeurScreen()),
            ),
            icon: const Icon(Icons.history_rounded, size: 19),
            label: const Text('Historique de mes courses'),
            style: OutlinedButton.styleFrom(
              foregroundColor: MabokoCouleurs.secondaire,
              side: const BorderSide(color: MabokoCouleurs.secondaire),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _carteCoordonnees(),
        const SizedBox(height: 24),

        OutlinedButton.icon(
          onPressed: _confirmerDeconnexion,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Se déconnecter'),
          style: OutlinedButton.styleFrom(
            foregroundColor: MabokoCouleurs.danger,
            side: const BorderSide(color: MabokoCouleurs.danger),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  Widget _enTete() {
    final fiche = _fiche;
    final initiales = (_nom ?? 'CH').trim().split(RegExp(r'\s+')).take(2).map((m) => m.isEmpty ? '' : m[0]).join().toUpperCase();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MabokoCouleurs.principale, Color(0xFF2E1A0F)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 2),
            ),
            child: Text(
              initiales.isEmpty ? 'CH' : initiales,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _nom ?? 'Chauffeur',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: (fiche?.enLigne ?? false) ? Colors.greenAccent : Colors.white38,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (fiche?.enLigne ?? false) ? 'En ligne' : 'Hors ligne',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    if ((fiche?.nbCoursesTerminees ?? 0) > 0) ...[
                      const Text(' · ', style: TextStyle(color: Colors.white38)),
                      const Icon(Icons.star_rounded, color: MabokoCouleurs.accent, size: 15),
                      Text(
                        fiche!.noteMoyenne.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bandeauFicheManquante() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MabokoCouleurs.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: MabokoCouleurs.accent),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Votre fiche chauffeur n’est pas encore enregistrée : '
                  'aucune course ne peut vous être proposée.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Le bandeau invitait a « contacter l'equipe Maboko » sans dire
          // comment : le chauffeur n'avait aucun moyen d'avancer.
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: MabokoCouleurs.secondaire,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: () async {
                final depose = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const FicheChauffeurScreen()),
                );
                if (depose == true) await _charger();
              },
              icon: const Icon(Icons.directions_car_outlined, size: 19),
              label: const Text('Enregistrer mon véhicule',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteVehicule(EtatChauffeur fiche) {
    return _carte(
      titre: 'Véhicule',
      enfants: [
        _ligne('Type', fiche.typeVehicule ?? '—', icone: Icons.two_wheeler_rounded),
        _ligne('Modèle', fiche.vehicule ?? '—', icone: Icons.directions_car_outlined),
        _ligne('Plaque', fiche.plaque ?? '—', icone: Icons.pin_outlined, monospace: true),
        _ligne('Courses terminées', '${fiche.nbCoursesTerminees}', icone: Icons.check_circle_outline),
      ],
    );
  }

  Widget _carteRevenus() {
    final r = _revenus;

    return _carte(
      titre: 'Revenus',
      enfants: [
        Row(
          children: [
            Expanded(child: _bloc('Aujourd’hui', _fcfa(r?.aujourdhui), '${r?.coursesAujourdhui ?? 0} course(s)')),
            const SizedBox(width: 12),
            Expanded(child: _bloc('Cette semaine', _fcfa(r?.totalSemaine), null)),
          ],
        ),
        const SizedBox(height: 12),
        _ligne('Total cumulé', _fcfa(r?.total), icone: Icons.account_balance_wallet_outlined),
      ],
    );
  }

  Widget _carteCoordonnees() {
    // Empilé plutôt qu'en vis-à-vis : une adresse e-mail longue se coupait au
    // milieu d'un mot faute de place dans la colonne de droite.
    return _carte(
      titre: 'Coordonnées',
      enfants: [
        _ligneEmpilee('Téléphone', _telephone ?? '—', Icons.phone_outlined),
        const SizedBox(height: 12),
        _ligneEmpilee('E-mail', _email ?? '—', Icons.mail_outline_rounded),
      ],
    );
  }

  Widget _ligneEmpilee(String libelle, String valeur, IconData icone) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 18, color: context.texteSecondaireMaboko),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(libelle, style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko)),
              const SizedBox(height: 2),
              Text(valeur, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  /* ── Briques d'affichage ── */

  static String _fcfa(double? montant) {
    if (montant == null) return '—';
    final entier = montant.round().toString();
    final tampon = StringBuffer();
    for (var i = 0; i < entier.length; i++) {
      if (i > 0 && (entier.length - i) % 3 == 0) tampon.write(' ');
      tampon.write(entier[i]);
    }
    return '$tampon FCFA';
  }

  Widget _carte({required String titre, required List<Widget> enfants}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: context.texteSecondaireMaboko,
            ),
          ),
          const SizedBox(height: 12),
          ...enfants,
        ],
      ),
    );
  }

  Widget _ligne(String libelle, String valeur, {required IconData icone, bool monospace = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icone, size: 18, color: context.texteSecondaireMaboko),
          const SizedBox(width: 10),
          Text(libelle, style: TextStyle(fontSize: 13, color: context.texteSecondaireMaboko)),
          const Spacer(),
          Flexible(
            child: Text(
              valeur,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloc(String libelle, String valeur, String? detail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.teinteMaboko,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(libelle, style: TextStyle(fontSize: 11, color: context.texteSecondaireMaboko)),
          const SizedBox(height: 4),
          Text(valeur, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (detail != null)
            Text(detail, style: TextStyle(fontSize: 11, color: context.texteSecondaireMaboko)),
        ],
      ),
    );
  }
}
