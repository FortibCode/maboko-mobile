import 'package:flutter_test/flutter_test.dart';
import 'package:maboko_mobile/core/config/adresse_api.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Adresse du serveur, modifiable sans recompiler.
///
/// Le poste de développement reçoit son adresse en DHCP. Au renouvellement du
/// bail elle change, et l'application ne joint plus rien : « Impossible de
/// joindre Maboko ». L'adresse était figée à la compilation, il fallait donc
/// reconstruire l'application à chaque fois.
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AdresseApi.reinitialiser();
  });

  test('sans réglage, l’adresse compilée s’applique', () async {
    await AdresseApi.charger();

    // La constante porte l'adresse du serveur ; le chemin des routes est
    // ajouté à la lecture.
    expect(AdresseApi.valeur, 'https://maboko-api.onrender.com/api/v1');

    expect(AdresseApi.valeur, AdresseApi.valeurCompilee);
    expect(AdresseApi.personnalisee, isFalse);
  });

  test('une simple adresse IP suffit', () async {
    final motif = await AdresseApi.definir('192.168.1.90');

    expect(motif, isNull);
    expect(AdresseApi.valeur, 'http://192.168.1.90:8000/api/v1');
  });

  test('un port explicite est conservé', () async {
    await AdresseApi.definir('192.168.1.90:9000');

    expect(AdresseApi.valeur, 'http://192.168.1.90:9000/api/v1');
  });

  test('une adresse complète est reprise telle quelle', () async {
    await AdresseApi.definir('https://api.maboko.cg/api/v1');

    expect(AdresseApi.valeur, 'https://api.maboko.cg/api/v1');
  });

  test('la barre finale est retirée', () async {
    await AdresseApi.definir('http://192.168.1.90:8000/api/v1/');

    expect(AdresseApi.valeur, 'http://192.168.1.90:8000/api/v1');
  });

  test('une saisie incompréhensible est refusée', () async {
    final motif = await AdresseApi.definir('   ');

    expect(motif, isNotNull);
    expect(AdresseApi.valeur, AdresseApi.valeurCompilee);
  });

  test('l’adresse choisie survit à un redémarrage', () async {
    await AdresseApi.definir('192.168.1.90');
    // Redémarrage : la valeur en mémoire repart de la valeur compilée.
    await AdresseApi.reinitialiser();
    SharedPreferences.setMockInitialValues({
      'api_base_url': 'http://192.168.1.90:8000/api/v1',
    });

    await AdresseApi.charger();

    expect(AdresseApi.valeur, 'http://192.168.1.90:8000/api/v1');
    expect(AdresseApi.personnalisee, isTrue);
  });

  test('le domaine seul reçoit le préfixe des routes', () async {
    // « https://maboko-api.onrender.com » est l'adresse du serveur, pas celle
    // des routes : sans « /api/v1 », chaque appel repart en 404.
    await AdresseApi.definir('https://maboko-api.onrender.com');

    expect(AdresseApi.valeur, 'https://maboko-api.onrender.com/api/v1');
  });

  test('une barre finale seule ne suffit pas à faire un chemin', () async {
    await AdresseApi.definir('https://maboko-api.onrender.com/');

    expect(AdresseApi.valeur, 'https://maboko-api.onrender.com/api/v1');
  });

  test('la réinitialisation ramène à l’adresse compilée', () async {
    await AdresseApi.definir('192.168.1.90');
    await AdresseApi.reinitialiser();

    expect(AdresseApi.valeur, AdresseApi.valeurCompilee);
    expect(AdresseApi.personnalisee, isFalse);
  });

  test('une adresse vide retombe sur une adresse exploitable', () async {
    // « String.fromEnvironment » ne rend sa valeur par defaut que si la cle
    // est absente : un --dart-define=API_BASE_URL= vide renvoie une chaine
    // vide, dont aucune requete ne peut etre construite.
    SharedPreferences.setMockInitialValues({'api_base_url': '   '});
    await AdresseApi.charger();

    final adresse = Uri.tryParse(AdresseApi.valeur);

    expect(adresse, isNotNull);
    expect(adresse!.hasScheme, isTrue);
    expect(adresse.host, isNotEmpty);
  });

  test('une saisie incompréhensible ne casse pas les appels', () async {
    await AdresseApi.definir('n importe quoi');

    final adresse = Uri.tryParse(AdresseApi.valeur);

    expect(adresse?.hasScheme, isTrue);
    expect(adresse?.host, isNotEmpty);
  });

  test('un hôte sans protocole reste utilisable', () async {
    await AdresseApi.definir('maboko-api.onrender.com');

    expect(Uri.parse(AdresseApi.valeur).host, 'maboko-api.onrender.com');
  });
}
