import '../../../core/network/api.dart';

/// Moyen de paiement Mobile Money enregistré (§5.1.10).
///
/// Seuls l'opérateur et le numéro sont conservés : l'opérateur confirme chaque
/// paiement par une invite envoyée au téléphone du titulaire.
class MoyenPaiement {
  const MoyenPaiement({
    required this.id,
    required this.operateur,
    required this.telephone,
    required this.telephoneMasque,
    required this.parDefaut,
    this.libelle,
  });

  final int id;
  final String operateur;
  final String telephone;
  final String telephoneMasque;
  final String? libelle;
  final bool parDefaut;

  String get nomOperateur => switch (operateur) {
        'airtel' => 'Airtel Money',
        'mtn' => 'MTN Mobile Money',
        _ => operateur,
      };

  factory MoyenPaiement.depuisJson(Map<String, dynamic> json) => MoyenPaiement(
        id: json['id'] as int,
        operateur: json['operateur'] as String? ?? '',
        telephone: json['telephone'] as String? ?? '',
        telephoneMasque: json['telephoneMasque'] as String? ?? '',
        libelle: json['libelle'] as String?,
        parDefaut: json['parDefaut'] as bool? ?? false,
      );
}

class MoyenPaiementRepository {
  const MoyenPaiementRepository();

  Future<List<MoyenPaiement>> lister() async {
    final reponse = await api.get('/moyens-paiement') as Map<String, dynamic>;

    return ((reponse['data'] as List?) ?? [])
        .map((m) => MoyenPaiement.depuisJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<MoyenPaiement> ajouter({
    required String operateur,
    required String telephone,
    String? libelle,
  }) async {
    final reponse = await api.post('/moyens-paiement', corps: {
      'operateur': operateur,
      'telephone': telephone,
      if (libelle != null && libelle.isNotEmpty) 'libelle': libelle,
    });

    return MoyenPaiement.depuisJson(reponse as Map<String, dynamic>);
  }

  Future<void> definirParDefaut(int id) => api.post('/moyens-paiement/$id/defaut');

  Future<void> retirer(int id) => api.delete('/moyens-paiement/$id');
}
