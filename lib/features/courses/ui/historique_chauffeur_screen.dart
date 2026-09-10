import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/course_repository.dart';
import '../models/course.dart';

/// Historique détaillé des courses effectuées par le chauffeur (§5.3.4).
///
/// L'application téléchargeait déjà cette liste — elle en tirait la course en
/// cours et jetait le reste. Le chauffeur n'avait donc aucun moyen de revoir
/// ce qu'il avait roulé, ni ce que chaque course lui avait rapporté.
class HistoriqueChauffeurScreen extends StatefulWidget {
  const HistoriqueChauffeurScreen({super.key});

  @override
  State<HistoriqueChauffeurScreen> createState() => _HistoriqueChauffeurScreenState();
}

class _HistoriqueChauffeurScreenState extends State<HistoriqueChauffeurScreen> {
  static const _depot = CourseRepository();

  List<Course>? _courses;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      final liste = await _depot.historique();
      if (!mounted) return;

      // Les courses en cours vivent sur l'écran d'accueil ; ici on regarde
      // derrière soi.
      setState(() => _courses = liste.where((c) => c.estCloturee).toList());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    }
  }

  double get _totalPercu => (_courses ?? [])
      .where((c) => c.statut == 'terminee')
      .fold<double>(0, (somme, c) => somme + (c.tarifFinal ?? c.tarifEstime));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Mes courses effectuées'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: MabokoCouleurs.secondaire,
        onRefresh: _charger,
        child: _corps(),
      ),
    );
  }

  Widget _corps() {
    if (_erreur != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          EtatErreur(message: _erreur!, onReessayer: _charger),
        ],
      );
    }

    if (_courses == null) return const ChargementEnCours();

    if (_courses!.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 60),
          EtatVide(
            icone: Icons.local_taxi_outlined,
            titre: 'Aucune course terminée',
            message: 'Vos courses passées s’afficheront ici, avec ce que '
                'chacune vous a rapporté.',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _courses!.length + 1,
      itemBuilder: (contexte, i) => i == 0 ? _recapitulatif() : _carte(_courses![i - 1]),
    );
  }

  Widget _recapitulatif() {
    final terminees = _courses!.where((c) => c.statut == 'terminee').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MabokoCouleurs.secondaire, MabokoCouleurs.accent],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total perçu',
              style: TextStyle(color: Colors.white70, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text(
            formaterFcfa(_totalPercu),
            style: const TextStyle(
                color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            '$terminees course${terminees > 1 ? 's' : ''} terminée${terminees > 1 ? 's' : ''}',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _carte(Course course) {
    final annulee = course.statut != 'terminee';
    final date = course.termineeLe ?? course.creeeLe;

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
                course.typeVehicule == 'moto'
                    ? Icons.two_wheeler_rounded
                    : Icons.directions_car_rounded,
                size: 18,
                color: MabokoCouleurs.secondaire,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  course.clientNom ?? 'Client Maboko',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              Text(
                annulee ? '—' : formaterFcfa(course.tarifFinal ?? course.tarifEstime),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: annulee
                      ? context.texteSecondaireMaboko
                      : MabokoCouleurs.succes,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _point(Icons.trip_origin, course.depart.adresse),
          _point(Icons.place_outlined, course.arrivee.adresse),
          const SizedBox(height: 8),
          Row(
            children: [
              PastilleStatut(statut: course.statut),
              const Spacer(),
              Text(
                '${course.distanceKm.toStringAsFixed(1)} km'
                '${date == null ? '' : ' · ${_date(date)}'}',
                style: TextStyle(fontSize: 11.5, color: context.texteSecondaireMaboko),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _point(IconData icone, String adresse) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 14, color: context.texteSecondaireMaboko),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              adresse,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  static const _mois = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  static String _date(DateTime valeur) {
    final local = valeur.toLocal();
    final heure = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '${local.day} ${_mois[local.month - 1]} à $heure:$minute';
  }
}
