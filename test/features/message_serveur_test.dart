import 'package:flutter_test/flutter_test.dart';
import 'package:maboko_mobile/core/network/api_exception.dart';

/// Les messages d'erreur que l'application montre.
///
/// Une panne serveur ne se raconte pas a l'utilisateur. Mais quand le serveur
/// explique lui-meme ce qui manque — « L'envoi de SMS n'est pas configure sur
/// ce serveur » — remplacer cette phrase par « incident » prive tout le monde
/// de la seule information utile.
void main() {
  test('un message porteur est conservé', () {
    final exception = ApiException(
      'L’envoi de SMS n’est pas configuré sur ce serveur.',
      statusCode: 503,
    );

    expect(exception.message, contains('SMS'));
    expect(exception.message, isNot(contains('incident')));
  });

  test('le repli reste disponible pour une panne muette', () {
    final exception = ApiException(
      'Le service Maboko rencontre un incident. Reessayez dans un instant.',
      statusCode: 500,
    );

    expect(exception.statusCode, 500);
  });
}
