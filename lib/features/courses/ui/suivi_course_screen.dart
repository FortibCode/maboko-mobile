import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/temps_reel/canal_reverb.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/course_repository.dart';
import '../models/course.dart';
import 'widgets_carte.dart';

/// Suivi d'une course côté client : recherche d'un chauffeur, puis position
/// du véhicule sur la carte jusqu'à la dépose.
///
/// Les évolutions arrivent par le canal privé Reverb ; une interrogation
/// périodique reste en filet si le temps réel est indisponible.
class SuiviCourseScreen extends StatefulWidget {
  const SuiviCourseScreen({super.key, required this.courseId});

  final int courseId;

  @override
  State<SuiviCourseScreen> createState() => _SuiviCourseScreenState();
}

class _SuiviCourseScreenState extends State<SuiviCourseScreen> {
  static const _repository = CourseRepository();

  final _controleurCarte = MapController();

  Course? _course;
  CanalReverb? _canal;
  Timer? _minuterie;
  bool _chargement = true;
  bool _actionEnCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger(premiereFois: true);
    _brancherTempsReel();

    _minuterie = Timer.periodic(
      Duration(seconds: AppConfig.tempsReelDisponible ? 30 : 6),
      (_) => _charger(),
    );
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    _canal?.fermer();
    super.dispose();
  }

  void _brancherTempsReel() {
    if (!AppConfig.tempsReelDisponible) return;

    final canal = CanalReverb(nomCanal: 'course.${widget.courseId}');
    _canal = canal;

    canal.evenements.listen((evenement) {
      if (evenement.nom != 'course.maj' || !mounted) return;

      final charge = evenement.donnees['course'];
      if (charge is! Map<String, dynamic>) return;

      setState(() => _course = Course.depuisJson(charge));
    });

    canal.connecter();
  }

  Future<void> _charger({bool premiereFois = false}) async {
    try {
      final course = await _repository.detail(widget.courseId);
      if (!mounted) return;
      setState(() {
        _course = course;
        _chargement = false;
        _erreur = null;
      });
    } on ApiException catch (e) {
      if (!mounted || !premiereFois) return;
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    }
  }

  Future<void> _annuler() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la course ?'),
        content: const Text('Le chauffeur en sera informé.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Revenir')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Annuler la course', style: TextStyle(color: MabokoCouleurs.danger)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() => _actionEnCours = true);

    try {
      final course = await _repository.annuler(widget.courseId);
      if (!mounted) return;
      setState(() {
        _course = course;
        _actionEnCours = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

  Future<void> _appeler(String telephone) async {
    final uri = Uri.parse('tel:$telephone');

    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Ma course'),
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

    final course = _course!;

    return Column(
      children: [
        Expanded(child: _carte(course)),
        _panneau(course),
      ],
    );
  }

  Widget _carte(Course course) {
    final depart = LatLng(course.depart.latitude, course.depart.longitude);
    final arrivee = LatLng(course.arrivee.latitude, course.arrivee.longitude);
    final chauffeur = course.chauffeur;

    return CarteMaboko(
      controleur: _controleurCarte,
      centre: depart,
      trace: [depart, arrivee],
      marqueurs: [
        marqueurMaboko(point: depart, icone: Icons.trip_origin, couleur: MabokoCouleurs.principale),
        marqueurMaboko(point: arrivee, icone: Icons.place, couleur: MabokoCouleurs.secondaire),
        if (chauffeur != null && chauffeur.aUnePosition)
          marqueurMaboko(
            point: LatLng(chauffeur.latitude!, chauffeur.longitude!),
            icone: course.typeVehicule == 'moto' ? Icons.two_wheeler : Icons.directions_car,
            couleur: MabokoCouleurs.accent,
            etiquette: chauffeur.nomComplet,
          ),
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
                  _titreStatut(course.statut),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                formaterFcfa(course.tarifFinal ?? course.tarifEstime),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: MabokoCouleurs.secondaire,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _sousTitreStatut(course),
            style: TextStyle(fontSize: 13, color: context.texteSecondaireMaboko, height: 1.4),
          ),
          if (course.chercheChauffeur) ...[
            const SizedBox(height: 14),
            LinearProgressIndicator(
              color: MabokoCouleurs.secondaire,
              backgroundColor: context.bordureMaboko,
            ),
          ],
          if (course.chauffeur != null) ...[
            const SizedBox(height: 16),
            _ficheChauffeur(course.chauffeur!),
          ],
          const SizedBox(height: 16),
          if (!course.estCloturee && !course.clientABord)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: _actionEnCours ? null : _annuler,
                style: OutlinedButton.styleFrom(
                  foregroundColor: MabokoCouleurs.danger,
                  side: const BorderSide(color: MabokoCouleurs.danger),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Annuler la course', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          if (course.estCloturee)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MabokoCouleurs.secondaire,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Terminer', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _ficheChauffeur(ChauffeurCourse chauffeur) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.teinteMaboko,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: context.surfaceMaboko,
            child: const Icon(Icons.person, color: MabokoCouleurs.secondaire),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  chauffeur.nomComplet,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
                const SizedBox(height: 2),
                // Le client doit pouvoir reconnaître le véhicule qui arrive.
                Text(
                  [chauffeur.vehicule, chauffeur.plaque].whereType<String>().join(' · '),
                  style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
                ),
                if (chauffeur.noteMoyenne > 0) ...[
                  const SizedBox(height: 4),
                  Etoiles(note: chauffeur.noteMoyenne, taille: 13),
                ],
              ],
            ),
          ),
          if (chauffeur.telephone != null)
            IconButton(
              icon: const Icon(Icons.phone, color: MabokoCouleurs.succes),
              tooltip: 'Appeler le chauffeur',
              onPressed: () => _appeler(chauffeur.telephone!),
            ),
        ],
      ),
    );
  }

  String _titreStatut(String statut) => switch (statut) {
        'recherche' => 'Recherche d’un chauffeur…',
        'acceptee' => 'Chauffeur trouvé',
        'en_route' => 'Votre chauffeur arrive',
        'prise_en_charge' => 'En route vers votre destination',
        'terminee' => 'Course terminée',
        'annulee' => 'Course annulée',
        _ => statut,
      };

  String _sousTitreStatut(Course course) => switch (course.statut) {
        'recherche' => 'Nous prévenons les chauffeurs disponibles autour de vous.',
        'acceptee' => 'Il se met en route. Restez au point de départ.',
        'en_route' => 'Suivez sa position sur la carte.',
        'prise_en_charge' =>
          '${course.distanceKm.toStringAsFixed(1)} km · environ ${course.dureeEstimeeMin} min',
        'terminee' => 'Merci d’avoir voyagé avec Maboko.',
        'annulee' => course.annuleePar == 'chauffeur'
            ? 'Le chauffeur a annulé. Vous pouvez réserver une autre course.'
            : 'Vous avez annulé cette course.',
        _ => '',
      };
}
