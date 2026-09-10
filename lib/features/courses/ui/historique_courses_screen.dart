import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/course_repository.dart';
import '../models/course.dart';
import 'suivi_course_screen.dart';

/// Historique des courses Allô Chauffeur du client (§5.1.10).
///
/// Le cahier de charges le demande dans « Mon profil ». L'API le renvoyait
/// déjà — `GET /courses` filtre sur l'utilisateur connecté — mais aucun écran
/// ne l'affichait : un client ne pouvait pas revoir ses trajets passés.
class HistoriqueCoursesScreen extends StatefulWidget {
  const HistoriqueCoursesScreen({super.key});

  @override
  State<HistoriqueCoursesScreen> createState() => _HistoriqueCoursesScreenState();
}

class _HistoriqueCoursesScreenState extends State<HistoriqueCoursesScreen> {
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
      setState(() => _courses = liste);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mes courses'),
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
            titre: 'Aucune course',
            message: 'Vos trajets Allô Chauffeur apparaîtront ici une fois réservés.',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _courses!.length,
      itemBuilder: (contexte, i) => _carte(_courses![i]),
    );
  }

  Widget _carte(Course course) {
    final prix = course.tarifFinal ?? course.tarifEstime;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // Seules les courses encore en cours ont un écran de suivi utile.
          onTap: course.estCloturee
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SuiviCourseScreen(courseId: course.id)),
                  ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      course.typeVehicule == 'moto'
                          ? Icons.two_wheeler_rounded
                          : Icons.directions_car_rounded,
                      size: 19,
                      color: MabokoCouleurs.secondaire,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      course.typeVehicule == 'moto' ? 'Moto' : 'Voiture',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const Spacer(),
                    PastilleStatut(statut: course.statut),
                  ],
                ),
                const SizedBox(height: 12),
                _point(Icons.trip_origin_rounded, course.depart.adresse, MabokoCouleurs.succes),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(width: 2, height: 14, color: context.bordureMaboko),
                ),
                _point(Icons.place_rounded, course.arrivee.adresse, MabokoCouleurs.danger),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (course.chauffeur != null) ...[
                      Icon(Icons.person_outline, size: 15, color: context.texteSecondaireMaboko),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          course.chauffeur!.nomComplet,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.texteSecondaireMaboko,
                          ),
                        ),
                      ),
                    ] else
                      Expanded(
                        child: Text(
                          'Aucun chauffeur assigné',
                          style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
                        ),
                      ),
                    Text(
                      _fcfa(prix),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _point(IconData icone, String adresse, Color couleur) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 17, color: couleur),
        const SizedBox(width: 9),
        Expanded(
          child: Text(adresse, style: const TextStyle(fontSize: 13, height: 1.3)),
        ),
      ],
    );
  }

  static String _fcfa(double montant) {
    final entier = montant.round().toString();
    final tampon = StringBuffer();
    for (var i = 0; i < entier.length; i++) {
      if (i > 0 && (entier.length - i) % 3 == 0) tampon.write(' ');
      tampon.write(entier[i]);
    }

    return '$tampon FCFA';
  }
}
