import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/localisation/service_position.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/course_repository.dart';
import '../models/course.dart';
import 'widgets_carte.dart';

/// Course en cours, côté chauffeur (§5.3.2, §5.3.3).
///
/// La navigation guidée est déléguée à Google Maps ou Waze, déjà installés
/// sur le téléphone : les réimplémenter coûterait cher pour un résultat
/// inférieur, et le cahier de charges autorise ce choix (§6.2).
///
/// La fin de course exige le code à 4 chiffres que le client lit à l'écran
/// de son propre téléphone : un chauffeur ne peut donc pas clôturer une
/// course sans l'accord du client.
class CourseChauffeurScreen extends StatefulWidget {
  const CourseChauffeurScreen({super.key, required this.courseId});

  final int courseId;

  @override
  State<CourseChauffeurScreen> createState() => _CourseChauffeurScreenState();
}

class _CourseChauffeurScreenState extends State<CourseChauffeurScreen> {
  static const _repository = CourseRepository();

  final _controleurCarte = MapController();

  Course? _course;
  StreamSubscription<dynamic>? _suiviPosition;

  LatLng? _positionActuelle;
  bool _chargement = true;
  bool _actionEnCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
    _suivrePosition();
  }

  @override
  void dispose() {
    _suiviPosition?.cancel();
    super.dispose();
  }

  void _suivrePosition() {
    _suiviPosition = ServicePosition.suivi().listen((position) {
      if (mounted) {
        setState(() => _positionActuelle = LatLng(position.latitude, position.longitude));
      }

      _repository.transmettrePosition(
        latitude: position.latitude,
        longitude: position.longitude,
        vitesseKmh: position.speed * 3.6,
      );
    });
  }

  Future<void> _charger() async {
    try {
      final course = await _repository.detail(widget.courseId);
      if (!mounted) return;
      setState(() {
        _course = course;
        _chargement = false;
        _erreur = null;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    }
  }

  Future<void> _agir(Future<Course> Function() action, String succes) async {
    setState(() => _actionEnCours = true);

    try {
      final course = await action();
      if (!mounted) return;
      setState(() {
        _course = course;
        _actionEnCours = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(succes), backgroundColor: MabokoCouleurs.succes),
      );

      if (course.estCloturee && mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

  /// Demande le code à 4 chiffres du client, puis termine la course.
  ///
  /// Le code est comparé localement (simulation). Quand le serveur validera
  /// lui-même, cette méthode lui enverra simplement la valeur saisie.
  Future<void> _terminerAvecCode(Course course) async {
    final controleur = TextEditingController();
    String? erreur;

    final code = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogue) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.pin_outlined, color: MabokoCouleurs.secondaire),
              SizedBox(width: 8),
              Text('Code de confirmation'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Demandez au client son code à 4 chiffres pour clôturer la course.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controleur,
                keyboardType: TextInputType.number,
                maxLength: 4,
                autofocus: true,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 10,
                ),
                decoration: InputDecoration(
                  hintText: '0000',
                  counterText: '',
                  errorText: erreur,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                final saisi = controleur.text.trim();

                if (saisi.length != 4) {
                  setDialogue(() => erreur = 'Entrez les 4 chiffres.');

                  return;
                }

                if (saisi != course.codePin) {
                  setDialogue(() => erreur = 'Code incorrect. Demandez au client.');

                  return;
                }

                Navigator.pop(context, saisi);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: MabokoCouleurs.secondaire,
                foregroundColor: Colors.white,
              ),
              child: const Text('Valider'),
            ),
          ],
        ),
      ),
    );

    if (code == null) return;

    await _agir(
      () => _repository.terminer(course.id, codeConfirmation: code),
      'Course terminée.',
    );
  }

  /// Ouvre le guidage vers le point utile : le client tant qu'il n'est pas
  /// à bord, sa destination ensuite.
  Future<void> _ouvrirNavigation() async {
    final course = _course;
    if (course == null) return;

    final cible = course.clientABord ? course.arrivee : course.depart;

    final uris = [
      Uri.parse('geo:${cible.latitude},${cible.longitude}?q=${cible.latitude},${cible.longitude}'),
      Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${cible.latitude},${cible.longitude}'),
    ];

    for (final uri in uris) {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucune application de navigation trouvée.')),
    );
  }

  Future<void> _signaler() async {
    final motif = await showDialog<String>(
      context: context,
      builder: (context) {
        final controleur = TextEditingController();

        return AlertDialog(
          title: const Text('Signaler un problème'),
          content: TextField(
            controller: controleur,
            maxLines: 3,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Décrivez ce qui se passe…',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Revenir')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controleur.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: MabokoCouleurs.danger),
              child: const Text('Signaler', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (motif == null || motif.isEmpty) return;

    await _agir(
      () => _repository.annuler(widget.courseId, motif: motif),
      'Problème signalé, course annulée.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Course en cours'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.report_problem_outlined),
            tooltip: 'Signaler un problème',
            onPressed: _actionEnCours ? null : _signaler,
          ),
        ],
      ),
      body: _corps(),
    );
  }

  Widget _corps() {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null) return EtatErreur(message: _erreur!, onReessayer: _charger);

    final course = _course!;
    final depart = LatLng(course.depart.latitude, course.depart.longitude);
    final arrivee = LatLng(course.arrivee.latitude, course.arrivee.longitude);

    return Column(
      children: [
        Expanded(
          child: CarteMaboko(
            controleur: _controleurCarte,
            centre: course.clientABord ? arrivee : depart,
            trace: [depart, arrivee],
            marqueurs: [
              marqueurMaboko(point: depart, icone: Icons.trip_origin, couleur: MabokoCouleurs.principale),
              marqueurMaboko(point: arrivee, icone: Icons.place, couleur: MabokoCouleurs.secondaire),
            ],
          ),
        ),
        _panneau(course),
      ],
    );
  }

  Widget _panneau(Course course) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: context.surfaceMaboko,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  course.clientABord ? 'Vers la destination' : 'Vers le client',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                formaterFcfa(course.tarifEstime),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: MabokoCouleurs.secondaire,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _ligne(Icons.person_outline, course.clientNom ?? 'Client Maboko'),
          _ligne(Icons.trip_origin, course.depart.adresse),
          _ligne(Icons.place_outlined, course.arrivee.adresse),
          const SizedBox(height: 10),
          _estimation(course),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 56,
                height: 50,
                child: OutlinedButton(
                  onPressed: _ouvrirNavigation,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: MabokoCouleurs.secondaire,
                    side: const BorderSide(color: MabokoCouleurs.secondaire),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Icon(Icons.navigation_outlined),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _actionPrincipale(course)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _estimation(Course course) {
    final cible = course.clientABord ? course.arrivee : course.depart;
    final depuis = _positionActuelle;

    final distance = depuis == null
        ? (course.clientABord ? course.distanceKm : null)
        : _distanceKm(depuis, LatLng(cible.latitude, cible.longitude));

    if (distance == null) {
      return Text(
        'Trajet total : ${course.distanceKm.toStringAsFixed(1)} km · '
        'environ ${course.dureeEstimeeMin} min',
        style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
      );
    }

    final minutes = (distance / 25 * 60).ceil().clamp(1, 999);

    return Row(
      children: [
        const Icon(Icons.near_me_outlined, size: 15, color: MabokoCouleurs.secondaire),
        const SizedBox(width: 6),
        Text(
          '${distance.toStringAsFixed(1)} km · environ $minutes min',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: MabokoCouleurs.secondaire,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            course.clientABord ? 'jusqu’à la destination' : 'jusqu’au client',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko),
          ),
        ),
      ],
    );
  }

  static double _distanceKm(LatLng a, LatLng b) {
    const rayonTerre = 6371.0;

    final dLat = _radians(b.latitude - a.latitude);
    final dLon = _radians(b.longitude - a.longitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_radians(a.latitude)) *
            math.cos(_radians(b.latitude)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    return rayonTerre * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  }

  static double _radians(double degres) => degres * math.pi / 180;

  Widget _actionPrincipale(Course course) {
    // Fin de course : on demande le code au client avant de clôturer.
    if (course.statut == 'prise_en_charge') {
      return SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          onPressed: _actionEnCours ? null : () => _terminerAvecCode(course),
          style: ElevatedButton.styleFrom(
            backgroundColor: MabokoCouleurs.secondaire,
            foregroundColor: Colors.white,
            disabledBackgroundColor: context.bordureMaboko,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: _actionEnCours
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                )
              : const Icon(Icons.pin_outlined),
          label: const Text(
            'Terminer la course',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    final (libelle, action) = switch (course.statut) {
      'acceptee' => (
          'Je suis en route',
          () => _agir(() => _repository.demarrer(course.id), 'En route vers le client.'),
        ),
      'en_route' => (
          'Client à bord',
          () => _agir(() => _repository.prendreEnCharge(course.id), 'Client pris en charge.'),
        ),
      _ => ('Course terminée', null),
    };

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _actionEnCours || action == null ? null : action,
        style: ElevatedButton.styleFrom(
          backgroundColor: MabokoCouleurs.secondaire,
          foregroundColor: Colors.white,
          disabledBackgroundColor: context.bordureMaboko,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _actionEnCours
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
              )
            : Text(libelle, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _ligne(IconData icone, String texte) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icone, size: 16, color: context.texteSecondaireMaboko),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texte,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}