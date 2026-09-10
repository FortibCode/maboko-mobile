import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/localisation/service_position.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/course_repository.dart';
import '../models/course.dart';
import 'course_chauffeur_screen.dart';
import 'fiche_chauffeur_screen.dart';

/// Accueil du chauffeur (§5.3.1 et §5.3.4) : bascule en ligne / hors ligne,
/// courses proposées, et revenus du jour.
class ChauffeurAccueilScreen extends StatefulWidget {
  const ChauffeurAccueilScreen({super.key});

  @override
  State<ChauffeurAccueilScreen> createState() => _ChauffeurAccueilScreenState();
}

class _ChauffeurAccueilScreenState extends State<ChauffeurAccueilScreen> {
  static const _repository = CourseRepository();
  static const _intervalleRelecture = Duration(seconds: 10);

  EtatChauffeur? _etat;
  RevenusChauffeur? _revenus;
  List<Course> _propositions = const [];
  Course? _courseEnCours;

  Timer? _minuterie;
  StreamSubscription<dynamic>? _suiviPosition;
  bool _chargement = true;
  bool _bascule = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger(premiereFois: true);
    _minuterie = Timer.periodic(_intervalleRelecture, (_) => _charger());
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    _suiviPosition?.cancel();
    super.dispose();
  }

  Future<void> _charger({bool premiereFois = false}) async {
    try {
      final etat = await _repository.etatChauffeur();
      if (!mounted) return;

      final resultats = await Future.wait([
        _repository.revenus(),
        etat.enLigne ? _repository.propositions() : Future.value(<Course>[]),
        _repository.historique(),
      ]);

      if (!mounted) return;

      final historique = resultats[2] as List<Course>;

      setState(() {
        _etat = etat;
        _revenus = resultats[0] as RevenusChauffeur;
        _propositions = resultats[1] as List<Course>;
        // Une course active passe devant tout le reste.
        _courseEnCours = historique.where((c) => c.estActive).firstOrNull;
        _chargement = false;
        _erreur = null;
      });

      if (etat.enLigne) _demarrerSuiviPosition();
    } on ApiException catch (e) {
      if (!mounted || !premiereFois) return;
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    }
  }

  /// Tant que le chauffeur est en ligne, sa position part au serveur : c'est
  /// elle qui le rend joignable pour les courses proches.
  void _demarrerSuiviPosition() {
    if (_suiviPosition != null) return;

    _suiviPosition = ServicePosition.suivi().listen((position) {
      _repository.transmettrePosition(
        latitude: position.latitude,
        longitude: position.longitude,
        vitesseKmh: position.speed * 3.6,
      );
    });
  }

  void _arreterSuiviPosition() {
    _suiviPosition?.cancel();
    _suiviPosition = null;
  }

  Future<void> _basculer(bool enLigne) async {
    setState(() => _bascule = true);

    // Sans position transmise, le chauffeur reste invisible à l'appariement :
    // on en envoie une immédiatement plutôt que d'attendre le premier
    // déplacement.
    if (enLigne) {
      final position = await ServicePosition.actuelle();

      if (position == null) {
        if (!mounted) return;
        setState(() => _bascule = false);
        _informer(
          'Activez la localisation pour recevoir des courses.',
          MabokoCouleurs.danger,
        );

        return;
      }

      await _repository.transmettrePosition(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }

    try {
      await _repository.basculerDisponibilite(enLigne);
      if (!mounted) return;
      setState(() => _bascule = false);

      enLigne ? _demarrerSuiviPosition() : _arreterSuiviPosition();
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _bascule = false);
      _informer(e.message, MabokoCouleurs.danger);
    }
  }

  Future<void> _accepter(Course course) async {
    try {
      final acceptee = await _repository.accepter(course.id);
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CourseChauffeurScreen(courseId: acceptee.id)),
      );
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      // 409 : un autre chauffeur a été plus rapide. Cas courant, pas une erreur.
      _informer(e.message, e.statusCode == 409 ? MabokoCouleurs.accent : MabokoCouleurs.danger);
      await _charger();
    }
  }

  /// Refus d'une course proposée (§5.3.1).
  ///
  /// Seul « Accepter » existait : une course sans intérêt revenait dans la
  /// liste à chaque relecture, toutes les dix secondes, jusqu'à expiration.
  Future<void> _refuser(Course course) async {
    // Retrait immédiat : le chauffeur conduit, il ne doit pas attendre le
    // serveur pour voir la carte disparaître.
    setState(() => _propositions = _propositions.where((c) => c.id != course.id).toList());

    try {
      await _repository.refuser(course.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      _informer(e.message, MabokoCouleurs.danger);
      await _charger();
    }
  }

  void _informer(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: couleur),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Allô Chauffeur'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _corps(),
    );
  }

  Widget _corps() {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null) {
      return EtatErreur(message: _erreur!, onReessayer: () => _charger(premiereFois: true));
    }

    final etat = _etat!;

    if (etat.ficheManquante) {
      // Le message renvoyait vers « l'equipe Maboko » sans aucun moyen de la
      // joindre ni de deposer quoi que ce soit : le compte etait fige la.
      return EtatVide(
        icone: Icons.no_transfer_outlined,
        titre: 'Votre fiche chauffeur est incomplète',
        message: 'Renseignez votre véhicule et votre permis pour commencer '
            'à recevoir des courses.',
        action: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: MabokoCouleurs.secondaire,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          ),
          onPressed: () async {
            final depose = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const FicheChauffeurScreen()),
            );
            if (depose == true) await _charger(premiereFois: true);
          },
          icon: const Icon(Icons.directions_car_outlined, size: 19),
          label: const Text('Enregistrer mon véhicule',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    return RefreshIndicator(
      color: MabokoCouleurs.secondaire,
      onRefresh: () => _charger(premiereFois: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _basculeDisponibilite(etat),
          const SizedBox(height: 16),
          if (_courseEnCours != null) ...[
            _carteCourseEnCours(_courseEnCours!),
            const SizedBox(height: 16),
          ],
          _revenusDuJour(),
          const SizedBox(height: 16),
          _sectionPropositions(etat),
        ],
      ),
    );
  }

  Widget _basculeDisponibilite(EtatChauffeur etat) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: etat.enLigne ? MabokoCouleurs.succes : context.surfaceMaboko,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: etat.enLigne ? MabokoCouleurs.succes : context.bordureMaboko),
      ),
      child: Row(
        children: [
          Icon(
            etat.enLigne ? Icons.wifi_tethering : Icons.wifi_tethering_off,
            color: etat.enLigne ? Colors.white : context.texteSecondaireMaboko,
            size: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  etat.enLigne ? 'Vous êtes en ligne' : 'Vous êtes hors ligne',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: etat.enLigne ? Colors.white : MabokoCouleurs.principale,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  etat.enLigne
                      ? '${etat.vehicule ?? ''} · ${etat.plaque ?? ''}'
                      : 'Passez en ligne pour recevoir des courses.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: etat.enLigne ? Colors.white70 : context.texteSecondaireMaboko,
                  ),
                ),
              ],
            ),
          ),
          _bascule
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Switch(
                  value: etat.enLigne,
                  onChanged: _basculer,
                  activeThumbColor: Colors.white,
                  activeTrackColor: Colors.white38,
                ),
        ],
      ),
    );
  }

  Widget _carteCourseEnCours(Course course) {
    return Material(
      color: MabokoCouleurs.accent.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CourseChauffeurScreen(courseId: course.id)),
          );
          await _charger();
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MabokoCouleurs.accent),
          ),
          child: Row(
            children: [
              const Icon(Icons.navigation_rounded, color: MabokoCouleurs.accent, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Course en cours',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text(
                      '${course.depart.adresse} → ${course.arrivee.adresse}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _revenusDuJour() {
    final revenus = _revenus;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceMaboko,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Aujourd’hui', style: TextStyle(fontSize: 13, color: context.texteSecondaireMaboko)),
          const SizedBox(height: 4),
          Text(
            formaterFcfa(revenus?.aujourdhui ?? 0),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${revenus?.coursesAujourdhui ?? 0} course(s) · '
            '${formaterFcfa(revenus?.totalSemaine ?? 0)} cette semaine',
            style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
          ),
          if (revenus != null && revenus.semaine.isNotEmpty) ...[
            const SizedBox(height: 16),
            _graphiqueSemaine(revenus),
          ],
        ],
      ),
    );
  }

  /// Graphique des sept derniers jours (§5.3.4). Barres proportionnelles au
  /// meilleur jour : un chauffeur voit d'un coup d'œil ses jours forts.
  Widget _graphiqueSemaine(RevenusChauffeur revenus) {
    final maximum = revenus.semaine.map((j) => j.total).fold<double>(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 78,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: revenus.semaine.map((jour) {
          final hauteur = maximum > 0 ? (jour.total / maximum) * 54 : 0.0;
          final date = DateTime.tryParse(jour.jour);

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  height: hauteur < 3 ? 3 : hauteur,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: jour.total > 0 ? MabokoCouleurs.secondaire : context.bordureMaboko,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  date == null ? '' : _jourCourt(date.weekday),
                  style: TextStyle(fontSize: 10, color: context.texteSecondaireMaboko),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _sectionPropositions(EtatChauffeur etat) {
    if (!etat.enLigne) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: EtatVide(
          icone: Icons.wifi_tethering_off,
          titre: 'Hors ligne',
          message: 'Passez en ligne pour voir les courses proposées près de vous.',
        ),
      );
    }

    if (_propositions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: EtatVide(
          icone: Icons.local_taxi_outlined,
          titre: 'Aucune course pour le moment',
          message: 'Les nouvelles demandes apparaîtront ici automatiquement.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Courses proposées (${_propositions.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 10),
        ..._propositions.map(_carteProposition),
      ],
    );
  }

  Widget _carteProposition(Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceMaboko,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                course.typeVehicule == 'moto' ? Icons.two_wheeler : Icons.directions_car,
                color: MabokoCouleurs.secondaire,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  course.clientNom ?? 'Client Maboko',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
              ),
              Text(
                formaterFcfa(course.tarifEstime),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: MabokoCouleurs.secondaire,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ligneTrajet(Icons.trip_origin, course.depart.adresse),
          _ligneTrajet(Icons.place_outlined, course.arrivee.adresse),
          const SizedBox(height: 6),
          Text(
            'Trajet : ${course.distanceKm.toStringAsFixed(1)} km · environ ${course.dureeEstimeeMin} min',
            style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko),
          ),
          // La distance du trajet ne dit pas si le client est a deux rues ou
          // a l'autre bout de la ville : c'est pourtant ce qui decide d'y
          // aller ou non (§5.3.1).
          if (course.distancePriseEnChargeKm != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.near_me_outlined, size: 14, color: MabokoCouleurs.secondaire),
                const SizedBox(width: 6),
                Text(
                  'Client à ${course.distancePriseEnChargeKm!.toStringAsFixed(1)} km de vous',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: MabokoCouleurs.secondaire,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => _refuser(course),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.texteSecondaireMaboko,
                      side: BorderSide(color: context.bordureMaboko),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Refuser'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => _accepter(course),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MabokoCouleurs.secondaire,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Accepter',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ligneTrajet(IconData icone, String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icone, size: 14, color: context.texteSecondaireMaboko),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texte,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  String _jourCourt(int jourSemaine) => switch (jourSemaine) {
        DateTime.monday => 'lun',
        DateTime.tuesday => 'mar',
        DateTime.wednesday => 'mer',
        DateTime.thursday => 'jeu',
        DateTime.friday => 'ven',
        DateTime.saturday => 'sam',
        _ => 'dim',
      };
}
