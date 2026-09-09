/// Demande de devis (§5.1.7 côté client, §5.2.2 côté artisan).
class Demande {
  const Demande({
    required this.id,
    required this.titre,
    required this.description,
    required this.statut,
    required this.adresse,
    this.photos = const [],
    this.budgetEstime,
    this.montantPropose,
    this.montantFinal,
    this.dateSouhaitee,
    this.metier,
    this.clientNom,
    this.artisanNom,
    this.artisanId,
    this.motifRefus,
    this.creeeLe,
  });

  final int id;
  final String titre;
  final String description;
  final String statut;
  final String adresse;
  final List<String> photos;
  final double? budgetEstime;
  final double? montantPropose;
  final double? montantFinal;
  final String? dateSouhaitee;
  final String? metier;
  final String? clientNom;
  final String? artisanNom;
  final int? artisanId;
  final String? motifRefus;
  final DateTime? creeeLe;

  bool get estTerminee => statut == 'terminee';

  bool get estEnAttente => statut == 'en_attente';

  bool get estCloturee => const ['terminee', 'refusee', 'annulee'].contains(statut);

  factory Demande.depuisJson(Map<String, dynamic> json) {
    final artisan = json['artisan'] as Map<String, dynamic>?;
    final client = json['client'] as Map<String, dynamic>?;
    final metier = json['metier'] as Map<String, dynamic>?;

    return Demande(
      id: json['id'] as int,
      titre: json['titre'] as String,
      description: json['description'] as String? ?? '',
      statut: json['statut'] as String,
      adresse: json['adresse'] as String? ?? '',
      photos: ((json['photos'] as List?) ?? []).map((p) => p.toString()).toList(),
      budgetEstime: (json['budgetEstime'] as num?)?.toDouble(),
      montantPropose: (json['montantPropose'] as num?)?.toDouble(),
      montantFinal: (json['montantFinal'] as num?)?.toDouble(),
      dateSouhaitee: json['dateSouhaitee'] as String?,
      metier: metier?['nom'] as String?,
      clientNom: (client?['nomComplet'] as String?)?.trim(),
      artisanNom: ((artisan?['utilisateur'] as Map<String, dynamic>?)?['nomComplet'] as String?)?.trim(),
      artisanId: artisan?['id'] as int?,
      motifRefus: json['motifRefus'] as String?,
      creeeLe: DateTime.tryParse(json['creeeLe'] as String? ?? ''),
    );
  }
}
