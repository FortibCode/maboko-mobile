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

  /// Artisans mis en favori par l'utilisateur connecté.
  ///
  /// L'API renvoie la même structure que la recherche : le modèle et la carte
  /// d'artisan existants sont réutilisés tels quels.
  Future<List<Artisan>> favoris() async {
    final reponse = await api.get('/favoris');

    return ((reponse['data'] as List?) ?? [])
        .map((a) => Artisan.depuisJson(a as Map<String, dynamic>))
        .toList();
  }

  /// Ajoute ou retire l'artisan des favoris. Renvoie l'état après bascule.
  Future<bool> basculerFavori(int artisanId) async {
    final reponse = await api.post('/favoris/$artisanId');

    return (reponse as Map<String, dynamic>)['favori'] as bool? ?? false;
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

  /// Création de la fiche artisan du compte connecté (§5.2.1).
  ///
  /// L'inscription crée le compte mais pas la fiche : sans elle l'artisan
  /// n'apparaît dans aucune recherche et son tableau de bord n'a rien à
  /// afficher. Aucun écran n'appelait cette route.
  Future<Artisan> creerFiche({
    required String specialite,
    required String adresse,
    required double latitude,
    required double longitude,
    required List<String> metiers,
    String? bio,
    String? zoneIntervention,
    int? rayonKm,
  }) async {
    final reponse = await api.post('/artisans', corps: {
      'specialite': specialite,
      'adresse': adresse,
      'latitude': latitude,
      'longitude': longitude,
      if (metiers.isNotEmpty) 'metiers': metiers,
      if (bio != null && bio.isNotEmpty) 'bio': bio,
      if (zoneIntervention != null && zoneIntervention.isNotEmpty)
        'zone_intervention': zoneIntervention,
      if (rayonKm != null) 'rayon_km': rayonKm,
    });

    final donnees = reponse['data'] ?? reponse;

    return Artisan.depuisJson(donnees as Map<String, dynamic>);
  }

  /// Modification de sa propre fiche (§5.2.1).
  ///
  /// Sert notamment à ajouter ou retirer un métier depuis l'onglet Profil :
  /// le choix fait à l'inscription n'était plus modifiable ensuite.
  Future<Artisan> mettreAJourFiche(
    int artisanId, {
    String? specialite,
    String? adresse,
    List<String>? metiers,
    String? bio,
    String? zoneIntervention,
    int? rayonKm,
  }) async {
    final reponse = await api.patch('/artisans/$artisanId', corps: {
      if (specialite != null) 'specialite': specialite,
      if (adresse != null) 'adresse': adresse,
      if (metiers != null) 'metiers': metiers,
      if (bio != null) 'bio': bio,
      if (zoneIntervention != null) 'zone_intervention': zoneIntervention,
      if (rayonKm != null) 'rayon_km': rayonKm,
    });

    final donnees = reponse['data'] ?? reponse;

    return Artisan.depuisJson(donnees as Map<String, dynamic>);
  }

  /// Fiche de l'artisan connecté. Null si le compte n'en a pas encore.
  Future<Artisan?> maFiche() async {
    final reponse = await api.get('/artisans/me');
    final donnees = reponse['data'];

    return donnees == null ? null : Artisan.depuisJson(donnees as Map<String, dynamic>);
  }
}
