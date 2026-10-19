import '../../../core/network/api.dart';
import '../models/demande.dart';

class DemandeRepository {
  const DemandeRepository();

  /// Liste des demandes (filtrées selon le rôle côté API).
  Future<List<Demande>> lister() async {
    final reponse = await api.get('/demandes');
    return ((reponse['data'] as List?) ?? [])
        .map((json) => Demande.depuisJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Détail d'une demande spécifique.
  Future<Demande> detail(int id) async {
    final reponse = await api.get('/demandes/$id');
    return Demande.depuisJson(reponse['demande'] as Map<String, dynamic>);
  }

  /// Création d'une demande par le client.
  Future<Demande> creer({
    required int artisanId,
    required String titre,
    required String description,
    required String adresse,
    double? budgetEstime,
    String? dateSouhaitee,
    List<String> photos = const [],
  }) async {
    final reponse = await api.post('/demandes', corps: {
      'artisan_id': artisanId,
      'titre': titre,
      'description': description,
      'adresse': adresse,
      if (budgetEstime != null) 'budget_estime': budgetEstime,
      if (dateSouhaitee != null) 'date_souhaitee': dateSouhaitee,
      if (photos.isNotEmpty) 'photos': photos,
    });
    return Demande.depuisJson(reponse['demande'] as Map<String, dynamic>);
  }

  /// L'artisan accepte et propose un montant.
  Future<Demande> accepter(int id, double montant) async {
    final reponse = await api.post('/demandes/$id/accepter', corps: {
      'montant_propose': montant,
    });
    return Demande.depuisJson(reponse['demande'] as Map<String, dynamic>);
  }

  /// L'artisan refuse la demande.
  Future<Demande> refuser(int id, {String? motif}) async {
    final reponse = await api.post('/demandes/$id/refuser', corps: {
      if (motif != null) 'motif_refus': motif,
    });
    return Demande.depuisJson(reponse['demande'] as Map<String, dynamic>);
  }

  /// L'artisan démarre l'intervention.
  Future<Demande> demarrer(int id) async {
    final reponse = await api.post('/demandes/$id/demarrer');
    return Demande.depuisJson(reponse['demande'] as Map<String, dynamic>);
  }

  /// L'artisan termine l'intervention (avec le montant final).
  Future<Demande> terminer(int id, {required double montantFinal}) async {
    final reponse = await api.post('/demandes/$id/terminer', corps: {
      'montant_final': montantFinal,
    });
    return Demande.depuisJson(reponse['demande'] as Map<String, dynamic>);
  }

  /// Le client annule la demande.
  Future<Demande> annuler(int id) async {
    final reponse = await api.post('/demandes/$id/annuler');
    return Demande.depuisJson(reponse['demande'] as Map<String, dynamic>);
  }

  /// Le client paie l'artisan (SIMULATION).
  Future<Demande> payer(int id) async {
    final reponse = await api.post('/demandes/$id/payer');
    return Demande.depuisJson(reponse['demande'] as Map<String, dynamic>);
  }

  /// Le client note l'artisan après paiement.
  Future<void> noter(int id, {required int note, required String commentaire}) async {
    await api.post('/demandes/$id/avis', corps: {
      'note': note,
      'commentaire': commentaire,
    });
  }
}