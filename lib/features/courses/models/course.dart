class Course {
  final int id;
  final String lieuDepart;
  final String lieuArrivee;
  final double departLatitude;
  final double departLongitude;
  final double arriveeLatitude;
  final double arriveeLongitude;
  final String typeVehicule;
  final String statut;
  final double? prixClient;
  final double? prixChauffeur;
  final double? tarifEstime;
  final double? tarifFinal;
  final ChauffeurResume? chauffeur;

  Course({
    required this.id,
    required this.lieuDepart,
    required this.lieuArrivee,
    required this.departLatitude,
    required this.departLongitude,
    required this.arriveeLatitude,
    required this.arriveeLongitude,
    required this.typeVehicule,
    required this.statut,
    this.prixClient,
    this.prixChauffeur,
    this.tarifEstime,
    this.tarifFinal,
    this.chauffeur,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'],
      lieuDepart: json['lieu_depart'] ?? '',
      lieuArrivee: json['lieu_arrivee'] ?? '',
      departLatitude: (json['depart_latitude'] as num).toDouble(),
      departLongitude: (json['depart_longitude'] as num).toDouble(),
      arriveeLatitude: (json['arrivee_latitude'] as num).toDouble(),
      arriveeLongitude: (json['arrivee_longitude'] as num).toDouble(),
      typeVehicule: json['type_vehicule'] ?? 'voiture',
      statut: json['statut'] ?? 'en_attente',
      prixClient: (json['prix_client'] as num?)?.toDouble(),
      prixChauffeur: (json['prix_chauffeur'] as num?)?.toDouble(),
      tarifEstime: (json['tarif_estime'] as num?)?.toDouble(),
      tarifFinal: (json['tarif_final'] as num?)?.toDouble(),
      chauffeur: json['chauffeur'] != null 
          ? ChauffeurResume.fromJson(json['chauffeur']) 
          : null,
    );
  }
}

class ChauffeurResume {
  final int id;
  final String nomComplet;
  final String telephone;
  final String? avatarUrl;
  final String? vehiculeModele;
  final String? plaque;

  ChauffeurResume({
    required this.id,
    required this.nomComplet,
    required this.telephone,
    this.avatarUrl,
    this.vehiculeModele,
    this.plaque,
  });

  factory ChauffeurResume.fromJson(Map<String, dynamic> json) {
    return ChauffeurResume(
      id: json['id'],
      nomComplet: json['nom_complet'] ?? 'Chauffeur',
      telephone: json['telephone'] ?? '',
      avatarUrl: json['avatar_url'],
      vehiculeModele: json['vehicule_modele'],
      plaque: json['plaque_immatriculation'],
    );
  }
}