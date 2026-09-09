import 'dart:async';

import 'package:flutter/material.dart';
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

  /// Transmet la position au serveur pendant la course : c'est ce qui permet
  /// au client de suivre l'arrivée du véhicule sur sa carte.
  void _suivrePosition() {
    _suiviPosition = ServicePosition.suivi().listen((position) {
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

  /// Ouvre le guidage vers le point utile : le client tant qu'il n'est pas
  /// à bord, sa destination ensuite.
  Future<void> _ouvrirNavigation() async {
    final course = _course;
    if (course == null) return;

    final cible = course.clientABord ? course.arrivee : course.depart;

    // Schéma universel : Google Maps le reconnaît, Waze et les cartes iOS
    // aussi. Repli sur le site web si aucune application n'est installée.
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
      backgroundColor: MabokoCouleurs.fond,
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
        color: MabokoCouleurs.surface,
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

  Widget _actionPrincipale(Course course) {
    final (libelle, action) = switch (course.statut) {
      'acceptee' => (
          'Je suis en route',
          () => _agir(() => _repository.demarrer(course.id), 'En route vers le client.'),
        ),
      'en_route' => (
          'Client à bord',
          () => _agir(() => _repository.prendreEnCharge(course.id), 'Client pris en charge.'),
        ),
      'prise_en_charge' => (
          'Terminer la course',
          () => _agir(() => _repository.terminer(course.id), 'Course terminée.'),
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
          disabledBackgroundColor: MabokoCouleurs.bordure,
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
          Icon(icone, size: 16, color: MabokoCouleurs.texteSecondaire),
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
