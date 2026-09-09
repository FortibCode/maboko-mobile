/// Point d'un trajet.
class PointTrajet {
  const PointTrajet({required this.adresse, required this.latitude, required this.longitude});

  final String adresse;
  final double latitude;
  final double longitude;

  factory PointTrajet.depuisJson(Map<String, dynamic>? json) => PointTrajet(
        adresse: json?['adresse'] as String? ?? '',
        latitude: (json?['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json?['longitude'] as num?)?.toDouble() ?? 0,
      );
}

/// Chauffeur attribué à une course, vu par le client.
class ChauffeurCourse {
  const ChauffeurCourse({
    required this.id,
    required this.nomComplet,
    this.vehicule,
    this.plaque,
    this.telephone,
    this.noteMoyenne = 0,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String nomComplet;
  final String? vehicule;
  final String? plaque;
  final String? telephone;
  final double noteMoyenne;
  final double? latitude;
  final double? longitude;

  bool get aUnePosition => latitude != null && longitude != null;

  factory ChauffeurCourse.depuisJson(Map<String, dynamic> json) {
    final position = json['position'] as Map<String, dynamic>?;

    return ChauffeurCourse(
      id: json['id'] as int? ?? 0,
      nomComplet: (json['nomComplet'] as String?)?.trim().isNotEmpty == true
          ? json['nomComplet'] as String
          : 'Chauffeur Maboko',
      vehicule: json['vehicule'] as String?,
      plaque: json['plaque'] as String?,
      telephone: json['telephone'] as String?,
      noteMoyenne: (json['noteMoyenne'] as num?)?.toDouble() ?? 0,
      latitude: (position?['latitude'] as num?)?.toDouble(),
      longitude: (position?['longitude'] as num?)?.toDouble(),
    );
  }
}

/// Course « Allô Chauffeur » (§5.1.8, §5.3).
class Course {
  const Course({
    required this.id,
    required this.statut,
    required this.typeVehicule,
    required this.depart,
    required this.arrivee,
    this.distanceKm = 0,
    this.dureeEstimeeMin = 0,
    this.tarifEstime = 0,
    this.tarifFinal,
    this.chauffeur,
    this.clientNom,
    this.annuleePar,
  });

  final int id;
  final String statut;
  final String typeVehicule;
  final PointTrajet depart;
  final PointTrajet arrivee;
  final double distanceKm;
  final int dureeEstimeeMin;
  final double tarifEstime;
  final double? tarifFinal;
  final ChauffeurCourse? chauffeur;
  final String? clientNom;
  final String? annuleePar;

  bool get chercheChauffeur => statut == 'recherche';

  bool get estActive =>
      const ['acceptee', 'en_route', 'prise_en_charge'].contains(statut);

  bool get estCloturee => const ['terminee', 'annulee'].contains(statut);

  bool get clientABord => statut == 'prise_en_charge';

  factory Course.depuisJson(Map<String, dynamic> json) {
    final chauffeur = json['chauffeur'] as Map<String, dynamic>?;
    final client = json['client'] as Map<String, dynamic>?;

    return Course(
      id: json['id'] as int,
      statut: json['statut'] as String,
      typeVehicule: json['typeVehicule'] as String? ?? 'moto',
      depart: PointTrajet.depuisJson(json['depart'] as Map<String, dynamic>?),
      arrivee: PointTrajet.depuisJson(json['arrivee'] as Map<String, dynamic>?),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      dureeEstimeeMin: json['dureeEstimeeMin'] as int? ?? 0,
      tarifEstime: (json['tarifEstime'] as num?)?.toDouble() ?? 0,
      tarifFinal: (json['tarifFinal'] as num?)?.toDouble(),
      chauffeur: chauffeur == null ? null : ChauffeurCourse.depuisJson(chauffeur),
      clientNom: (client?['nomComplet'] as String?)?.trim(),
      annuleePar: json['annuleePar'] as String?,
    );
  }
}

/// Estimation affichée avant la réservation.
class EstimationCourse {
  const EstimationCourse({
    required this.distanceKm,
    required this.dureeMin,
    required this.tarif,
  });

  final double distanceKm;
  final int dureeMin;
  final double tarif;

  factory EstimationCourse.depuisJson(Map<String, dynamic> json) => EstimationCourse(
        distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
        dureeMin: json['dureeMin'] as int? ?? 0,
        tarif: (json['tarif'] as num?)?.toDouble() ?? 0,
      );
}

/// Revenus du chauffeur (§5.3.4).
class RevenusChauffeur {
  const RevenusChauffeur({
    required this.aujourdhui,
    required this.coursesAujourdhui,
    required this.totalSemaine,
    required this.total,
    required this.semaine,
    required this.nbCoursesTerminees,
  });

  final double aujourdhui;
  final int coursesAujourdhui;
  final double totalSemaine;
  final double total;
  final List<({String jour, double total, int courses})> semaine;
  final int nbCoursesTerminees;

  factory RevenusChauffeur.depuisJson(Map<String, dynamic> json) => RevenusChauffeur(
        aujourdhui: (json['aujourdhui'] as num?)?.toDouble() ?? 0,
        coursesAujourdhui: json['coursesAujourdhui'] as int? ?? 0,
        totalSemaine: (json['totalSemaine'] as num?)?.toDouble() ?? 0,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        nbCoursesTerminees: json['nbCoursesTerminees'] as int? ?? 0,
        semaine: ((json['semaine'] as List?) ?? []).map((j) {
          final entree = j as Map<String, dynamic>;

          return (
            jour: entree['jour'] as String? ?? '',
            total: (entree['total'] as num?)?.toDouble() ?? 0,
            courses: entree['courses'] as int? ?? 0,
          );
        }).toList(),
      );
}

/// État de la fiche chauffeur.
class EtatChauffeur {
  const EtatChauffeur({
    required this.ficheManquante,
    this.id,
    this.typeVehicule,
    this.vehicule,
    this.plaque,
    this.enLigne = false,
    this.disponible = false,
    this.noteMoyenne = 0,
    this.nbCoursesTerminees = 0,
  });

  final bool ficheManquante;
  final int? id;
  final String? typeVehicule;
  final String? vehicule;
  final String? plaque;
  final bool enLigne;
  final bool disponible;
  final double noteMoyenne;
  final int nbCoursesTerminees;

  factory EtatChauffeur.depuisJson(Map<String, dynamic> json) => EtatChauffeur(
        ficheManquante: json['ficheManquante'] as bool? ?? false,
        id: json['id'] as int?,
        typeVehicule: json['typeVehicule'] as String?,
        vehicule: json['vehicule'] as String?,
        plaque: json['plaque'] as String?,
        enLigne: json['enLigne'] as bool? ?? false,
        disponible: json['disponible'] as bool? ?? false,
        noteMoyenne: (json['noteMoyenne'] as num?)?.toDouble() ?? 0,
        nbCoursesTerminees: json['nbCoursesTerminees'] as int? ?? 0,
      );
}
