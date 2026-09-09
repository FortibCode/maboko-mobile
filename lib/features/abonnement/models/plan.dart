/// Formule d'abonnement proposée aux artisans (§4.5).
class Plan {
  const Plan({
    required this.slug,
    required this.nom,
    required this.prixMensuel,
    required this.prixAnnuel,
    this.description,
    this.avantages = const [],
    this.boostClassement = 1,
  });

  final String slug;
  final String nom;
  final String? description;
  final double prixMensuel;
  final double prixAnnuel;
  final List<String> avantages;
  final double boostClassement;

  bool get estGratuit => slug == 'gratuit';

  /// Économie réalisée en payant à l'année plutôt que douze mois.
  double get economieAnnuelle => (prixMensuel * 12) - prixAnnuel;

  factory Plan.depuisJson(Map<String, dynamic> json) => Plan(
        slug: json['slug'] as String,
        nom: json['nom'] as String,
        description: json['description'] as String?,
        prixMensuel: (json['prixMensuel'] as num?)?.toDouble() ?? 0,
        prixAnnuel: (json['prixAnnuel'] as num?)?.toDouble() ?? 0,
        avantages: ((json['avantages'] as List?) ?? []).map((a) => a.toString()).toList(),
        boostClassement: (json['boostClassement'] as num?)?.toDouble() ?? 1,
      );
}

/// Abonnement en cours de l'artisan.
class AbonnementActuel {
  const AbonnementActuel({
    required this.plan,
    this.debutLe,
    this.finLe,
    this.renouvellementAuto = false,
  });

  final Plan plan;
  final String? debutLe;
  final String? finLe;
  final bool renouvellementAuto;

  factory AbonnementActuel.depuisJson(Map<String, dynamic> json) => AbonnementActuel(
        plan: Plan.depuisJson(json['plan'] as Map<String, dynamic>),
        debutLe: json['debutLe'] as String?,
        finLe: json['finLe'] as String?,
        renouvellementAuto: json['renouvellementAuto'] as bool? ?? false,
      );
}

/// Paiement Mobile Money.
class TransactionPaiement {
  const TransactionPaiement({
    required this.reference,
    required this.statut,
    required this.montant,
    this.operateur,
    this.motifEchec,
  });

  final String reference;
  final String statut;
  final double montant;
  final String? operateur;
  final String? motifEchec;

  bool get estReussie => statut == 'reussie';

  bool get estEnAttente => statut == 'initiee' || statut == 'en_attente';

  bool get aEchoue => statut == 'echouee';

  factory TransactionPaiement.depuisJson(Map<String, dynamic> json) => TransactionPaiement(
        reference: json['reference'] as String,
        statut: json['statut'] as String,
        montant: (json['montant'] as num?)?.toDouble() ?? 0,
        operateur: json['operateur'] as String?,
        motifEchec: json['motifEchec'] as String?,
      );
}
