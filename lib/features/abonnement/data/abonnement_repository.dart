import '../../../core/network/api.dart';
import '../models/plan.dart';

class AbonnementRepository {
  const AbonnementRepository();

  Future<List<Plan>> plans() async {
    final reponse = await api.get('/plans');

    return ((reponse['data'] as List?) ?? [])
        .map((p) => Plan.depuisJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<AbonnementActuel> actuel() async {
    final reponse = await api.get('/abonnement');

    return AbonnementActuel.depuisJson(reponse as Map<String, dynamic>);
  }

  /// Lance la souscription. Le paiement Mobile Money étant rarement immédiat,
  /// la transaction peut revenir « en attente » : c'est le cas normal.
  Future<({String message, TransactionPaiement? transaction, bool abonnementActif})> souscrire({
    required String plan,
    required String periodicite,
    required String operateur,
    required String telephone,
  }) async {
    final reponse = await api.post('/abonnement', corps: {
      'plan': plan,
      'periodicite': periodicite,
      'operateur': operateur,
      'telephone': telephone,
    });

    final donnees = reponse['transaction'] as Map<String, dynamic>?;

    return (
      message: reponse['message'] as String? ?? '',
      transaction: donnees == null ? null : TransactionPaiement.depuisJson(donnees),
      abonnementActif: reponse['abonnementActif'] as bool? ?? false,
    );
  }

  /// Suit une transaction pendant que le client confirme sur son téléphone.
  Future<TransactionPaiement> suivre(String reference) async {
    final reponse = await api.get('/transactions/$reference');

    return TransactionPaiement.depuisJson(reponse['transaction'] as Map<String, dynamic>);
  }
}
