import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/maboko_theme.dart';

/// Carte OpenStreetMap partagée par les écrans Allô Chauffeur.
///
/// Le cahier de charges laisse le choix entre Google Maps et OSM (§6.2) :
/// OSM évite une facture d'API que le budget ne supporterait pas.
class CarteMaboko extends StatelessWidget {
  const CarteMaboko({
    super.key,
    required this.controleur,
    required this.centre,
    this.marqueurs = const [],
    this.trace = const [],
    this.onTap,
    this.zoom = 14,
  });

  final MapController controleur;
  final LatLng centre;
  final List<Marker> marqueurs;
  final List<LatLng> trace;
  final void Function(LatLng)? onTap;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: controleur,
      options: MapOptions(
        initialCenter: centre,
        initialZoom: zoom,
        onTap: onTap == null ? null : (_, point) => onTap!(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'cg.maboko.app',
        ),
        if (trace.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(points: trace, color: MabokoCouleurs.secondaire, strokeWidth: 4),
            ],
          ),
        if (marqueurs.isNotEmpty) MarkerLayer(markers: marqueurs),
      ],
    );
  }
}

/// Marqueur circulaire aux couleurs de la plateforme.
Marker marqueurMaboko({
  required LatLng point,
  required IconData icone,
  required Color couleur,
  String? etiquette,
}) {
  return Marker(
    point: point,
    width: 46,
    height: 46,
    child: Tooltip(
      message: etiquette ?? '',
      child: Container(
        decoration: BoxDecoration(
          color: couleur,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6),
          ],
        ),
        child: Icon(icone, color: Colors.white, size: 22),
      ),
    ),
  );
}
