import '../../../core/network/api.dart';
import '../models/artisan.dart';

/// Critères de la recherche d'artisans (§4.1).
class FiltresArtisan {
  const FiltresArtisan({
    this.metier,
    this.recherche,
    this.noteMin,
    this.badge,
    this.latitude,
    this.longitude,
    this.rayonKm,
    this.tri,
  });

  final String? metier;
  final String? recherche;
  final double? noteMin;
  final String? badge;
  final double? latitude;
  final double? longitude;
  final int? rayonKm;
  final String? tri;

  Map<String, String> versParametres() => {
        if (metier != null) 'metier': metier!,
        if (recherche != null && recherche!.isNotEmpty) 'q': recherche!,
        if (noteMin != null) 'note_min': noteMin!.toString(),
        if (badge != null) 'badge': badge!,
        // La géolocalisation part par paire : l'API refuse l'une sans l'autre.
        if (latitude != null && longitude != null) ...{
          'latitude': latitude!.toString(),
          'longitude': longitude!.toString(),
          if (rayonKm != null) 'rayon_km': rayonKm!.toString(),
        },
        if (tri != null) 'tri': tri!,
      };

  FiltresArtisan copierAvec({
    String? metier,
    String? recherche,
    double? noteMin,
    String? badge,
    String? tri,
    bool effacerNoteMin = false,
    bool effacerBadge = false,
  }) {
    return FiltresArtisan(
      metier: metier ?? this.metier,
      recherche: recherche ?? this.recherche,
      noteMin: effacerNoteMin ? null : (noteMin ?? this.noteMin),
      badge: effacerBadge ? null : (badge ?? this.badge),
      latitude: latitude,
      longitude: longitude,
      rayonKm: rayonKm,
      tri: tri ?? this.tri,
    );
  }
}

class ArtisanRepository {
  const ArtisanRepository();

  Future<List<Artisan>> rechercher(FiltresArtisan filtres) async {
    final reponse = await api.get('/artisans', parametres: filtres.versParametres());

    return ((reponse['data'] as List?) ?? [])
        .map((a) => Artisan.depuisJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<Artisan> fiche(int id) async {
    final reponse = await api.get('/artisans/$id');

    return Artisan.depuisJson(reponse['data'] as Map<String, dynamic>);
  }

  Future<List<Avis>> avis(int id) async {
    final reponse = await api.get('/artisans/$id/avis');

    return ((reponse['data'] as List?) ?? [])
        .map((a) => Avis.depuisJson(a as Map<String, dynamic>))
        .toList();
  }

  /// Fiche de l'artisan connecté. Null si le compte n'en a pas encore.
  Future<Artisan?> maFiche() async {
    final reponse = await api.get('/artisans/me');
    final donnees = reponse['data'];

    return donnees == null ? null : Artisan.depuisJson(donnees as Map<String, dynamic>);
  }
}
