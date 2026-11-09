import 'package:shared_preferences/shared_preferences.dart';

/// Données du parcours d'inscription artisan.
class InscriptionArtisanData {
  const InscriptionArtisanData({
    this.experience,
    this.metiers, // 👈 AJOUT
    this.ville,
    this.quartier,
    this.bio,
    this.aRccm,
    this.photoRccm,
    this.photoPieceRecto,
    this.photoPieceVerso,
  });

  final String? experience;
  
  /// 👇 AJOUT : Liste des métiers sélectionnés
  final List<String>? metiers; 
  
  final String? ville;
  final String? quartier;
  final String? bio;
  final bool? aRccm;
  final String? photoRccm;
  final String? photoPieceRecto;
  final String? photoPieceVerso;

  /// Vrai si toutes les étapes obligatoires ont été remplies.
  bool get estComplet =>
      experience != null &&
      metiers != null && metiers!.isNotEmpty && // 👈 AJOUT
      ville != null &&
      quartier != null &&
      bio != null &&
      bio!.trim().isNotEmpty &&
      aRccm != null &&
      (aRccm == true
          ? photoRccm != null
          : photoPieceRecto != null && photoPieceVerso != null);

  // ---------------------------------------------------------------------------
  // Sérialisation vers SharedPreferences
  // ---------------------------------------------------------------------------

  static const _cleExperience = 'inscription_artisan_experience';
  static const _cleMetiers = 'inscription_artisan_metiers'; // 👈 AJOUT
  static const _cleVille = 'inscription_artisan_ville';
  static const _cleQuartier = 'inscription_artisan_quartier';
  static const _cleBio = 'inscription_artisan_bio';
  static const _cleARccm = 'inscription_artisan_a_rccm';
  static const _clePhotoRccm = 'inscription_artisan_photo_rccm';
  static const _clePhotoPieceRecto = 'inscription_artisan_photo_piece';
  static const _clePhotoPieceVerso = 'inscription_artisan_photo_piece_verso';

  /// Sauvegarde l'état complet du parcours en local.
  Future<void> sauvegarder() async {
    final prefs = await SharedPreferences.getInstance();

    if (experience != null) await prefs.setString(_cleExperience, experience!);
    if (metiers != null) await prefs.setStringList(_cleMetiers, metiers!); // 👈 AJOUT
    if (ville != null) await prefs.setString(_cleVille, ville!);
    if (quartier != null) await prefs.setString(_cleQuartier, quartier!);
    if (bio != null) await prefs.setString(_cleBio, bio!);
    if (aRccm != null) await prefs.setBool(_cleARccm, aRccm!);
    if (photoRccm != null) await prefs.setString(_clePhotoRccm, photoRccm!);
    if (photoPieceRecto != null) {
      await prefs.setString(_clePhotoPieceRecto, photoPieceRecto!);
    }
    if (photoPieceVerso != null) {
      await prefs.setString(_clePhotoPieceVerso, photoPieceVerso!);
    }
  }

  /// Relit l'état sauvegardé.
  static Future<InscriptionArtisanData?> charger() async {
    final prefs = await SharedPreferences.getInstance();

    final experience = prefs.getString(_cleExperience);
    final metiers = prefs.getStringList(_cleMetiers); // 👈 AJOUT
    final ville = prefs.getString(_cleVille);
    final quartier = prefs.getString(_cleQuartier);
    final bio = prefs.getString(_cleBio);
    final aRccm = prefs.getBool(_cleARccm);
    final photoRccm = prefs.getString(_clePhotoRccm);
    final photoPieceRecto = prefs.getString(_clePhotoPieceRecto);
    final photoPieceVerso = prefs.getString(_clePhotoPieceVerso);

    if (experience == null &&
        metiers == null && // 👈 AJOUT
        ville == null &&
        quartier == null &&
        bio == null &&
        aRccm == null) {
      return null;
    }

    return InscriptionArtisanData(
      experience: experience,
      metiers: metiers, // 👈 AJOUT
      ville: ville,
      quartier: quartier,
      bio: bio,
      aRccm: aRccm,
      photoRccm: photoRccm,
      photoPieceRecto: photoPieceRecto,
      photoPieceVerso: photoPieceVerso,
    );
  }

  /// Efface tout après la création réussie de la fiche artisan.
  static Future<void> vider() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_cleExperience);
    await prefs.remove(_cleMetiers); // 👈 AJOUT
    await prefs.remove(_cleVille);
    await prefs.remove(_cleQuartier);
    await prefs.remove(_cleBio);
    await prefs.remove(_cleARccm);
    await prefs.remove(_clePhotoRccm);
    await prefs.remove(_clePhotoPieceRecto);
    await prefs.remove(_clePhotoPieceVerso);
  }

  /// Copie avec modification.
  InscriptionArtisanData copierAvec({
    String? experience,
    List<String>? metiers, // 👈 AJOUT
    String? ville,
    String? quartier,
    String? bio,
    bool? aRccm,
    String? photoRccm,
    String? photoPieceRecto,
    String? photoPieceVerso,
  }) {
    return InscriptionArtisanData(
      experience: experience ?? this.experience,
      metiers: metiers ?? this.metiers, // 👈 AJOUT
      ville: ville ?? this.ville,
      quartier: quartier ?? this.quartier,
      bio: bio ?? this.bio,
      aRccm: aRccm ?? this.aRccm,
      photoRccm: photoRccm ?? this.photoRccm,
      photoPieceRecto: photoPieceRecto ?? this.photoPieceRecto,
      photoPieceVerso: photoPieceVerso ?? this.photoPieceVerso,
    );
  }
}

// ---------------------------------------------------------------------------
// Référentiels statiques : villes et quartiers
// ---------------------------------------------------------------------------

const Map<String, List<String>> quartiersParVille = {
  'Brazzaville': [
    'Bacongo', 'Makélékélé', 'Poto-Poto', 'Moungali', 
    'Talangaï', 'Ouenzé', 'Mfilou', 'Madibou', 'Djiri',
  ],
  'Pointe-Noire': [
    'Loandjili', 'Tié-Tié', 'Mvou-Mvou', 'Mpaka', 'Ngoyo', 'Lumumba',
  ],
  'Dolisie': [
    'Centre', 'Nkoulou', 'Moutampa', 'Banga',
  ],
  'Ouesso': [
    'Centre', 'Bandongo', 'Kombo',
  ],
  'Kinkala': [
    'Centre', 'Mbanza-Ndounga',
  ],
  'Nkayi': [
    'Centre', 'Mouyondzi',
  ],
};

const List<String> villesDisponibles = [
  'Brazzaville', 'Pointe-Noire', 'Dolisie', 'Ouesso', 'Kinkala', 'Nkayi',
];

const List<({String code, String libelle})> tranchesExperience = [
  (code: 'moins-2', libelle: 'Moins de 2 ans'),
  (code: '2-5', libelle: '2 à 5 ans'),
  (code: '5-10', libelle: '5 à 10 ans'),
  (code: '10-20', libelle: '10 à 20 ans'),
  (code: 'plus-20', libelle: 'Plus de 20 ans'),
];