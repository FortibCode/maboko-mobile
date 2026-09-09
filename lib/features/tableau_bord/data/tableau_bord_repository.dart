import '../../../core/network/api.dart';
import '../../artisans/models/artisan.dart';
import '../models/tableau_bord.dart';

class TableauBordRepository {
  const TableauBordRepository();

  Future<TableauBord> charger() async {
    final reponse = await api.get('/tableau-de-bord');

    return TableauBord.depuisJson(reponse as Map<String, dynamic>);
  }

  Future<List<Artisan>> favoris() async {
    final reponse = await api.get('/favoris');

    return ((reponse['data'] as List?) ?? [])
        .map((a) => Artisan.depuisJson(a as Map<String, dynamic>))
        .toList();
  }

  /// Ajoute ou retire l'artisan des favoris. Retourne son nouvel état.
  Future<bool> basculerFavori(int artisanId) async {
    final reponse = await api.post('/favoris/$artisanId');

    return reponse['favori'] as bool? ?? false;
  }
}
