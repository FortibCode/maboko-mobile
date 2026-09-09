import '../../../core/network/api.dart';
import '../models/demande.dart';

class DemandeRepository {
  const DemandeRepository();

  /// Demandes envoyées pour un client, missions reçues pour un artisan :
  /// l'API distingue les deux selon le rôle du compte connecté.
  Future<List<Demande>> lister({String? statut}) async {
    final reponse = await api.get(
      '/demandes',
      parametres: {if (statut != null) 'statut': statut},
    );

    return ((reponse['data'] as List?) ?? [])
        .map((d) => Demande.depuisJson(d as Map<String, dynamic>))
        .toList();
  }

  Future<Demande> detail(int id) async {
    final reponse = await api.get('/demandes/$id');

    return Demande.depuisJson(reponse['data'] as Map<String, dynamic>);
  }

  Future<Demande> creer({
    required int artisanId,
    required String titre,
    required String description,
    required String adresse,
    String? metier,
    double? budgetEstime,
    String? dateSouhaitee,
    List<String> photos = const [],
  }) async {
    final reponse = await api.post('/demandes', corps: {
      'artisan_id': artisanId,
      'titre': titre,
      'description': description,
      'adresse': adresse,
      if (metier != null) 'metier': metier,
      if (budgetEstime != null) 'budget_estime': budgetEstime,
      if (dateSouhaitee != null) 'date_souhaitee': dateSouhaitee,
      if (photos.isNotEmpty) 'photos': photos,
    });

    return Demande.depuisJson(reponse['demande'] as Map<String, dynamic>);
  }

  Future<Demande> accepter(int id, double montantPropose) =>
      _transition(id, 'accepter', {'montant_propose': montantPropose});

  Future<Demande> refuser(int id, {String? motif}) =>
      _transition(id, 'refuser', {if (motif != null) 'motif_refus': motif});

  Future<Demande> demarrer(int id) => _transition(id, 'demarrer', {});

  Future<Demande> terminer(int id, {double? montantFinal}) =>
      _transition(id, 'terminer', {if (montantFinal != null) 'montant_final': montantFinal});

  Future<Demande> annuler(int id, {String? motif}) =>
      _transition(id, 'annuler', {if (motif != null) 'motif_refus': motif});

  Future<void> noter(int id, {required int note, String? commentaire}) async {
    await api.post('/demandes/$id/avis', corps: {
      'note': note,
      if (commentaire != null && commentaire.isNotEmpty) 'commentaire': commentaire,
    });
  }

  Future<Demande> _transition(int id, String action, Map<String, dynamic> corps) async {
    final reponse = await api.post('/demandes/$id/$action', corps: corps);

    return Demande.depuisJson(reponse['demande'] as Map<String, dynamic>);
  }
}
