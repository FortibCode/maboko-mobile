import '../../../core/network/api.dart';

/// Avis déposé par le client sur un artisan (§5.1.7).
///
/// Un client ne voit que ses propres avis : c'est l'historique de ce qu'il a
/// évalué, pas les avis reçus par les artisans.
class MonAvis {
  const MonAvis({
    required this.id,
    required this.note,
    required this.artisanNom,
    required this.artisanId,
    this.commentaire,
    this.publieLe,
  });

  final int id;
  final int note;
  final String artisanNom;
  final int artisanId;
  final String? commentaire;
  final DateTime? publieLe;

  factory MonAvis.depuisJson(Map<String, dynamic> json) {
    final artisan = json['artisan'] as Map<String, dynamic>?;
    final utilisateur = artisan?['utilisateur'] as Map<String, dynamic>?;

    return MonAvis(
      id: json['id'] as int? ?? 0,
      note: json['note'] as int? ?? 0,
      artisanId: artisan?['id'] as int? ?? 0,
      artisanNom: (utilisateur?['nomComplet'] as String?)?.trim().isNotEmpty == true
          ? utilisateur!['nomComplet'] as String
          : 'Artisan Maboko',
      commentaire: json['commentaire'] as String?,
      publieLe: DateTime.tryParse(json['publieLe'] as String? ?? ''),
    );
  }
}

class AvisRepository {
  const AvisRepository();

  /// Avis déposés par le client connecté.
  Future<List<MonAvis>> mesAvis() async {
    final reponse = await api.get('/compte/avis');

    return ((reponse['data'] as List?) ?? [])
        .map((a) => MonAvis.depuisJson(a as Map<String, dynamic>))
        .toList();
  }
}