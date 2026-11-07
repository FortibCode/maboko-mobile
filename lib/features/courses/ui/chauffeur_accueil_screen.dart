import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../../../services/notification_service.dart';
import '../../chauffeurs/data/service_suivi_gps.dart';
import '../data/course_repository.dart';
import '../models/course.dart';
import 'course_chauffeur_screen.dart';
import 'fiche_chauffeur_screen.dart';

/// Accueil du chauffeur (§5.3.1 et §5.3.4).
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

  final Set<int> _coursesVues = {};

  /// ✅ IDs des courses où CE chauffeur a proposé un prix.
  /// Permet de distinguer "ma proposition en attente" (modifiable) de
  /// "un autre chauffeur a proposé" (lecture seule).
  final Set<int> _mesPropositions = {};

  bool _premierChargement = true;

  Timer? _minuterie;
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
    ServiceSuiviGps.instance.arreter();
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
      final propositions = resultats[1] as List<Course>;
      final active = historique.where((c) => c.estActive).firstOrNull;

      await _notifierNouvellesCourses(propositions);

      setState(() {
        _etat = etat;
        _revenus = resultats[0] as RevenusChauffeur;
        _propositions = propositions;
        _courseEnCours = active;
        _chargement = false;
        _erreur = null;
      });

      // ✅ GPS activé uniquement si une course est active (acceptee / en_route / prise_en_charge).
      if (active != null) {
        _demarrerSuiviPosition();
      } else {
        _arreterSuiviPosition();
      }
    } on ApiException catch (e) {
      if (!mounted || !premiereFois) return;
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    }
  }

  Future<void> _notifierNouvellesCourses(List<Course> propositions) async {
    if (_premierChargement) {
      _premierChargement = false;
      _coursesVues.addAll(propositions.map((c) => c.id));
      return;
    }

    final nouvelles = propositions.where((c) => !_coursesVues.contains(c.id)).toList();

    if (nouvelles.isNotEmpty) {
      final course = nouvelles.first;
      await NotificationService.notifierCourse(
        id: course.id,
        titre: 'Nouvelle course disponible',
        corps:
            '${course.depart.adresse} → ${course.arrivee.adresse} · ${formaterFcfa(course.tarifEstime)}',
      );
    }

    for (final c in propositions) {
      _coursesVues.add(c.id);
    }
  }

  void _demarrerSuiviPosition() => ServiceSuiviGps.instance.demarrer();

  void _arreterSuiviPosition() => ServiceSuiviGps.instance.arreter();

  Future<void> _basculer(bool enLigne) async {
    setState(() => _bascule = true);

    try {
      await _repository.basculerDisponibilite(enLigne);
      if (!mounted) return;
      setState(() => _bascule = false);

      if (!enLigne) {
        _arreterSuiviPosition();
      }
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _bascule = false);
      _informer(e.message, MabokoCouleurs.danger);
    }
  }

  Future<void> _proposerPrixEtAccepter(Course course) async {
    final prixInitial = course.prixChauffeur ??
        (course.prixClient != null && course.prixClient! > 0
            ? course.prixClient!
            : course.tarifEstime);

    final controleurPrix = TextEditingController(
      text: prixInitial.round().toString(),
    );

    final prixValide = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.surfaceMaboko,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.bordureMaboko,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Fixer votre prix',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '${course.depart.adresse} → ${course.arrivee.adresse}',
              style: TextStyle(fontSize: 13, color: context.texteSecondaireMaboko),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MabokoCouleurs.secondaire.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: MabokoCouleurs.secondaire, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tarif estimé : ${formaterFcfa(course.tarifEstime)}\n'
                      'Fixez le montant proposé au client.',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controleurPrix,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Votre tarif (FCFA)',
                suffixText: 'FCFA',
                filled: true,
                fillColor: context.fondMaboko,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      final p = double.tryParse(controleurPrix.text.trim());
                      if (p != null && p > 0) {
                        Navigator.pop(ctx, p);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MabokoCouleurs.secondaire,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Proposer ce prix',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (prixValide == null) return;

    try {
      await _repository.contreProposer(course.id, prixValide);
      if (!mounted) return;

      // ✅ On mémorise localement que c'est NOTRE proposition en attente.
      _mesPropositions.add(course.id);

      _informer(
        'Votre proposition de ${formaterFcfa(prixValide)} a été transmise au client.',
        MabokoCouleurs.succes,
      );
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      _informer(
        e.message,
        e.statusCode == 409 ? MabokoCouleurs.accent : MabokoCouleurs.danger,
      );
      await _charger();
    }
  }

  Future<void> _refuser(Course course) async {
    setState(() => _propositions = _propositions.where((c) => c.id != course.id).toList());

    try {
      await _repository.refuser(course.id);
      _mesPropositions.remove(course.id);
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
      return EtatErreur(
        message: _erreur!,
        onReessayer: () => _charger(premiereFois: true),
      );
    }

    final etat = _etat!;

    if (etat.ficheManquante) {
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
          label: const Text(
            'Enregistrer mon véhicule',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
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
        border: Border.all(
          color: etat.enLigne ? MabokoCouleurs.succes : context.bordureMaboko,
        ),
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
                    const Text(
                      'Course en cours',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
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
          Text(
            'Aujourd’hui',
            style: TextStyle(fontSize: 13, color: context.texteSecondaireMaboko),
          ),
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
          message: 'Passez en ligne pour voir les courses disponibles sur la plateforme.',
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
    final jaiPropose = _mesPropositions.contains(course.id);
    // ✅ Une course en négociation que je n'ai PAS proposée : un autre chauffeur
    // a déjà fixé un prix, on attend la réponse du client. Les boutons sont
    // désactivés pour éviter l'erreur 409 côté API.
    final autreAPropose = course.enNegociation && !jaiPropose;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceMaboko,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: autreAPropose ? MabokoCouleurs.bordureMaboko : context.bordureMaboko,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                course.typeVehicule == 'moto' ? Icons.two_wheeler : Icons.directions_car,
                color: autreAPropose ? Colors.grey : MabokoCouleurs.secondaire,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  course.clientNom ?? 'Client Maboko',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                    color: autreAPropose ? Colors.grey.shade600 : null,
                  ),
                ),
              ),
              Text(
                formaterFcfa(course.tarifEstime),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: autreAPropose ? Colors.grey : MabokoCouleurs.secondaire,
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

          // ✅ Bandeau "Ma proposition" (modifiable) ou "Un autre a proposé" (lecture seule).
          if (jaiPropose) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: MabokoCouleurs.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, size: 16, color: MabokoCouleurs.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ma proposition : ${formaterFcfa(course.prixChauffeur ?? course.tarifEstime)} · En attente du client',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: MabokoCouleurs.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (autreAPropose) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Un autre chauffeur a proposé ${formaterFcfa(course.prixChauffeur ?? course.tarifEstime)} · En attente du client',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: autreAPropose ? null : () => _refuser(course),
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
                    onPressed: autreAPropose ? null : () => _proposerPrixEtAccepter(course),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MabokoCouleurs.secondaire,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      jaiPropose
                          ? 'Modifier mon prix'
                          : (autreAPropose ? 'En attente du client' : 'Fixer mon prix'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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