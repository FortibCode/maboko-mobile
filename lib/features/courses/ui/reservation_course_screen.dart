import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/localisation/service_position.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/course_repository.dart';
import '../models/course.dart';
import 'suivi_course_screen.dart';
import 'widgets_carte.dart';

/// Réservation d'une course (§5.1.8) : point de départ, destination,
/// choix entre moto et voiture, estimation du tarif, puis recherche d'un
/// chauffeur disponible à proximité.
class ReservationCourseScreen extends StatefulWidget {
  const ReservationCourseScreen({super.key});

  @override
  State<ReservationCourseScreen> createState() => _ReservationCourseScreenState();
}

class _ReservationCourseScreenState extends State<ReservationCourseScreen> {
  static const _repository = CourseRepository();

  /// Centre de Brazzaville, utilisé tant que la position réelle est inconnue.
  static const _brazzaville = LatLng(-4.2634, 15.2429);

  final _controleurCarte = MapController();
  final _adresseDepart = TextEditingController(text: 'Ma position');
  final _adresseArrivee = TextEditingController();

  LatLng? _depart;
  LatLng? _arrivee;
  String _typeVehicule = 'moto';
  EstimationCourse? _estimation;

  bool _localisationEnCours = true;
  bool _estimationEnCours = false;
  bool _reservationEnCours = false;
  String? _messageLocalisation;

  @override
  void initState() {
    super.initState();
    _localiser();
  }

  @override
  void dispose() {
    _adresseDepart.dispose();
    _adresseArrivee.dispose();
    super.dispose();
  }

  Future<void> _localiser() async {
    final position = await ServicePosition.actuelle();

    if (!mounted) return;

    setState(() {
      _localisationEnCours = false;
      if (position == null) {
        _messageLocalisation = 'Position indisponible. Touchez la carte pour '
            'indiquer votre point de départ.';
      } else {
        _depart = LatLng(position.latitude, position.longitude);
      }
    });

    if (_depart != null) _controleurCarte.move(_depart!, 15);
  }

  /// Premier appui : le départ si la position est inconnue. Sinon la destination.
  void _pointChoisi(LatLng point) {
    setState(() {
      if (_depart == null) {
        _depart = point;
        _messageLocalisation = null;
      } else {
        _arrivee = point;
        if (_adresseArrivee.text.trim().isEmpty) {
          _adresseArrivee.text = 'Point sur la carte';
        }
      }
      _estimation = null;
    });

    _estimer();
  }

  Future<void> _estimer() async {
    if (_depart == null || _arrivee == null) return;

    setState(() => _estimationEnCours = true);

    try {
      final estimation = await _repository.estimer(
        departLat: _depart!.latitude,
        departLng: _depart!.longitude,
        arriveeLat: _arrivee!.latitude,
        arriveeLng: _arrivee!.longitude,
        typeVehicule: _typeVehicule,
      );

      if (!mounted) return;
      setState(() {
        _estimation = estimation;
        _estimationEnCours = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _estimationEnCours = false);
      _informer(e.message, MabokoCouleurs.danger);
    }
  }

  Future<void> _reserver() async {
    if (_depart == null || _arrivee == null) {
      _informer('Indiquez votre destination sur la carte.', MabokoCouleurs.danger);

      return;
    }

    setState(() => _reservationEnCours = true);

    try {
      final resultat = await _repository.reserver(
        lieuDepart: _adresseDepart.text.trim().isEmpty ? 'Ma position' : _adresseDepart.text.trim(),
        lieuArrivee: _adresseArrivee.text.trim().isEmpty ? 'Destination' : _adresseArrivee.text.trim(),
        departLat: _depart!.latitude,
        departLng: _depart!.longitude,
        arriveeLat: _arrivee!.latitude,
        arriveeLng: _arrivee!.longitude,
        typeVehicule: _typeVehicule,
      );

      if (!mounted) return;
      setState(() => _reservationEnCours = false);

      if (resultat.chauffeursContactes == 0) {
        _informer(
          'Aucun chauffeur disponible pour le moment. Réessayez dans quelques minutes.',
          MabokoCouleurs.accent,
        );
      }

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => SuiviCourseScreen(courseId: resultat.course.id)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _reservationEnCours = false);
      _informer(e.message, MabokoCouleurs.danger);
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
      backgroundColor: MabokoCouleurs.fond,
      appBar: AppBar(
        title: const Text('Allô Chauffeur'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Recentrer sur ma position',
            onPressed: _localiser,
          ),
        ],
      ),
      body: _localisationEnCours
          ? const ChargementEnCours(message: 'Recherche de votre position…')
          : Column(
              children: [
                Expanded(child: _carte()),
                _panneau(),
              ],
            ),
    );
  }

  Widget _carte() {
    final marqueurs = <Marker>[
      if (_depart != null)
        marqueurMaboko(
          point: _depart!,
          icone: Icons.trip_origin,
          couleur: MabokoCouleurs.principale,
          etiquette: 'Départ',
        ),
      if (_arrivee != null)
        marqueurMaboko(
          point: _arrivee!,
          icone: Icons.place,
          couleur: MabokoCouleurs.secondaire,
          etiquette: 'Destination',
        ),
    ];

    return Stack(
      children: [
        CarteMaboko(
          controleur: _controleurCarte,
          centre: _depart ?? _brazzaville,
          marqueurs: marqueurs,
          trace: [if (_depart != null) _depart!, if (_arrivee != null) _arrivee!],
          onTap: _pointChoisi,
        ),
        if (_messageLocalisation != null || _arrivee == null)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: MabokoCouleurs.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app_outlined, size: 18, color: MabokoCouleurs.secondaire),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _messageLocalisation ?? 'Touchez la carte pour choisir votre destination.',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _panneau() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: MabokoCouleurs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12)],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _champAdresse(_adresseDepart, 'Départ', Icons.trip_origin, MabokoCouleurs.principale),
            const SizedBox(height: 8),
            _champAdresse(_adresseArrivee, 'Destination', Icons.place, MabokoCouleurs.secondaire),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _choixVehicule('moto', 'Moto', Icons.two_wheeler)),
                const SizedBox(width: 10),
                Expanded(child: _choixVehicule('voiture', 'Voiture', Icons.directions_car)),
              ],
            ),
            const SizedBox(height: 14),
            _resume(),
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _reservationEnCours || _arrivee == null ? null : _reserver,
                icon: _reservationEnCours
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
                      )
                    : const Icon(Icons.local_taxi_rounded),
                label: Text(
                  _reservationEnCours ? 'Recherche…' : 'Chercher un chauffeur',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MabokoCouleurs.secondaire,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: MabokoCouleurs.bordure,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _champAdresse(TextEditingController controleur, String libelle, IconData icone, Color couleur) {
    return TextField(
      controller: controleur,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: libelle,
        prefixIcon: Icon(icone, color: couleur, size: 20),
        isDense: true,
        filled: true,
        fillColor: MabokoCouleurs.fond,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _choixVehicule(String valeur, String libelle, IconData icone) {
    final actif = _typeVehicule == valeur;

    return InkWell(
      onTap: () {
        setState(() {
          _typeVehicule = valeur;
          _estimation = null;
        });
        _estimer();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: actif ? MabokoCouleurs.secondaire.withValues(alpha: 0.12) : MabokoCouleurs.fond,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: actif ? MabokoCouleurs.secondaire : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icone, color: actif ? MabokoCouleurs.secondaire : MabokoCouleurs.texteSecondaire),
            const SizedBox(height: 4),
            Text(
              libelle,
              style: TextStyle(
                fontSize: 13,
                fontWeight: actif ? FontWeight.bold : FontWeight.w500,
                color: actif ? MabokoCouleurs.secondaire : MabokoCouleurs.principale,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resume() {
    if (_estimationEnCours) {
      return const SizedBox(
        height: 22,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: MabokoCouleurs.secondaire),
          ),
        ),
      );
    }

    final estimation = _estimation;

    if (estimation == null) {
      return const SizedBox(
        height: 22,
        child: Text(
          'Choisissez une destination pour voir le tarif.',
          style: TextStyle(fontSize: 12.5, color: MabokoCouleurs.texteSecondaire),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MabokoCouleurs.fond,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formaterFcfa(estimation.tarif),
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              Text(
                '${estimation.distanceKm.toStringAsFixed(1)} km · environ ${estimation.dureeMin} min',
                style: const TextStyle(fontSize: 12, color: MabokoCouleurs.texteSecondaire),
              ),
            ],
          ),
          const Icon(Icons.receipt_long_outlined, color: MabokoCouleurs.secondaire),
        ],
      ),
    );
  }
}
