import '../../../core/network/api.dart';
import '../models/metier.dart';

class MetierRepository {
  const MetierRepository();

  /// Référentiel complet, éventuellement filtré par nom.
  Future<List<Metier>> lister({String? recherche}) async {
    final reponse = await api.get(
      '/metiers',
      parametres: {
        if (recherche != null && recherche.isNotEmpty) 'q': recherche,
      },
    );

    return ((reponse['data'] as List?) ?? [])
        .map((m) => Metier.depuisJson(m as Map<String, dynamic>))
        .toList();
  }
}
