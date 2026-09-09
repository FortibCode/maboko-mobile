/// Erreur remontee par la couche reseau, deja traduite en message
/// affichable a l'utilisateur.
class ApiException implements Exception {
  ApiException(
    this.message, {
    this.statusCode,
    this.erreursValidation = const {},
  });

  final String message;
  final int? statusCode;

  /// Erreurs champ par champ renvoyees par Laravel sur un 422.
  final Map<String, List<String>> erreursValidation;

  bool get estValidation => statusCode == 422;

  bool get estNonAutorise => statusCode == 401;

  bool get estTropDeRequetes => statusCode == 429;

  /// Premier message d'erreur pour un champ donne, s'il existe.
  String? pourChamp(String champ) => erreursValidation[champ]?.first;

  @override
  String toString() => message;
}
