import 'package:shared_preferences/shared_preferences.dart';

/// Données du parcours d'inscription artisan.
///
/// Rempli étape par étape (expérience → ville → quartier → bio → RCCM) et
/// sauvegardé en local au fur et à mesure. Si l'utilisateur ferme
/// l'application au milieu, il reprend là où il s'était arrêté.
///
/// Vidé une fois la fiche artisan créée avec succès sur le serveur.
class InscriptionArtisanData {
  const InscriptionArtisanData({
    this.experience,
    this.ville,
    this.quartier,
    this.bio,
    this.aRccm,
    this.photoRccm,
    this.photoPiece,
  });

  /// Tranche d'expérience choisie : « moins-2 », « 2-5 », « 5-10 »,
  /// « 10-20 », « plus-20 ».
  final String? experience;

  /// Ville d'exercice (Brazzaville, Pointe-Noire, etc.).
  final String? ville;

  /// Quartier dans la ville.
  final String? quartier;

  /// Présentation libre, limitée à 100 mots.
  final String? bio;

  /// L'artisan possède-t-il un RCCM ?
  final bool? aRccm;

  /// Photo du RCCM, encodée en base64 (`data:image/jpeg;base64,...`).
  final String? photoRccm;

  /// Photo de la pièce d'identité, encodée en base64.
  final String? photoPiece;

  /// Vrai si toutes les étapes obligatoires ont été remplies.
  bool get estComplet =>
      experience != null &&
      ville != null &&
      quartier != null &&
      bio != null &&
      bio!.trim().isNotEmpty &&
      aRccm != null &&
      (aRccm == true ? photoRccm != null : photoPiece != null);

  // ---------------------------------------------------------------------------
  // Sérialisation vers SharedPreferences
  // ---------------------------------------------------------------------------

  static const _cleExperience = 'inscription_artisan_experience';
  static const _cleVille = 'inscription_artisan_ville';
  static const _cleQuartier = 'inscription_artisan_quartier';
  static const _cleBio = 'inscription_artisan_bio';
  static const _cleARccm = 'inscription_artisan_a_rccm';
  static const _clePhotoRccm = 'inscription_artisan_photo_rccm';
  static const _clePhotoPiece = 'inscription_artisan_photo_piece';

  /// Sauvegarde l'état complet du parcours en local.
  Future<void> sauvegarder() async {
    final prefs = await SharedPreferences.getInstance();

    if (experience != null) await prefs.setString(_cleExperience, experience!);
    if (ville != null) await prefs.setString(_cleVille, ville!);
    if (quartier != null) await prefs.setString(_cleQuartier, quartier!);
    if (bio != null) await prefs.setString(_cleBio, bio!);
    if (aRccm != null) await prefs.setBool(_cleARccm, aRccm!);
    if (photoRccm != null) await prefs.setString(_clePhotoRccm, photoRccm!);
    if (photoPiece != null) await prefs.setString(_clePhotoPiece, photoPiece!);
  }

  /// Relit l'état sauvegardé. Renvoie `null` si rien n'a été sauvegardé.
  static Future<InscriptionArtisanData?> charger() async {
    final prefs = await SharedPreferences.getInstance();

    final experience = prefs.getString(_cleExperience);
    final ville = prefs.getString(_cleVille);
    final quartier = prefs.getString(_cleQuartier);
    final bio = prefs.getString(_cleBio);
    final aRccm = prefs.getBool(_cleARccm);
    final photoRccm = prefs.getString(_clePhotoRccm);
    final photoPiece = prefs.getString(_clePhotoPiece);

    if (experience == null &&
        ville == null &&
        quartier == null &&
        bio == null &&
        aRccm == null) {
      return null;
    }

    return InscriptionArtisanData(
      experience: experience,
      ville: ville,
      quartier: quartier,
      bio: bio,
      aRccm: aRccm,
      photoRccm: photoRccm,
      photoPiece: photoPiece,
    );
  }

  /// Efface tout après la création réussie de la fiche artisan.
  static Future<void> vider() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_cleExperience);
    await prefs.remove(_cleVille);
    await prefs.remove(_cleQuartier);
    await prefs.remove(_cleBio);
    await prefs.remove(_cleARccm);
    await prefs.remove(_clePhotoRccm);
    await prefs.remove(_clePhotoPiece);
  }

  /// Copie avec modification : chaque écran renvoie sa valeur et on
  /// reconstruit l'objet complet sans toucher aux autres champs.
  InscriptionArtisanData copierAvec({
    String? experience,
    String? ville,
    String? quartier,
    String? bio,
    bool? aRccm,
    String? photoRccm,
    String? photoPiece,
  }) {
    return InscriptionArtisanData(
      experience: experience ?? this.experience,
      ville: ville ?? this.ville,
      quartier: quartier ?? this.quartier,
      bio: bio ?? this.bio,
      aRccm: aRccm ?? this.aRccm,
      photoRccm: photoRccm ?? this.photoRccm,
      photoPiece: photoPiece ?? this.photoPiece,
    );
  }
}

// ---------------------------------------------------------------------------
// Référentiels statiques : villes et quartiers
// ---------------------------------------------------------------------------

/// Quartiers par ville du Congo.
///
/// Sert à l'écran de choix du quartier : une fois la ville choisie, on
/// affiche uniquement ses quartiers.
const Map<String, List<String>> quartiersParVille = {
  'Brazzaville': [
    'Bacongo',
    'Makélékélé',
    'Poto-Poto',
    'Moungali',
    'Talangaï',
    'Ouenzé',
    'Mfilou',
    'Madibou',
    'Djiri',
  ],
  'Pointe-Noire': [
    'Loandjili',
    'Tié-Tié',
    'Mvou-Mvou',
    'Mpaka',
    'Ngoyo',
    'Lumumba',
  ],
  'Dolisie': [
    'Centre',
    'Nkoulou',
    'Moutampa',
    'Banga',
  ],
  'Ouesso': [
    'Centre',
    'Bandongo',
    'Kombo',
  ],
  'Kinkala': [
    'Centre',
    'Mbanza-Ndounga',
  ],
  'Nkayi': [
    'Centre',
    'Mouyondzi',
  ],
};

/// Liste ordonnée des villes proposées à l'inscription.
const List<String> villesDisponibles = [
  'Brazzaville',
  'Pointe-Noire',
  'Dolisie',
  'Ouesso',
  'Kinkala',
  'Nkayi',
];

/// Tranches d'expérience proposées à l'étape 1.
const List<({String code, String libelle})> tranchesExperience = [
  (code: 'moins-2', libelle: 'Moins de 2 ans'),
  (code: '2-5', libelle: '2 à 5 ans'),
  (code: '5-10', libelle: '5 à 10 ans'),
  (code: '10-20', libelle: '10 à 20 ans'),
  (code: 'plus-20', libelle: 'Plus de 20 ans'),
];