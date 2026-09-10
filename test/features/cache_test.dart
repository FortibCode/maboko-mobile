import 'package:flutter_test/flutter_test.dart';
import 'package:maboko_mobile/core/cache/cache_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mode dégradé hors connexion (§7.2).
///
/// À Brazzaville, une coupure de quelques minutes est banale : l'application
/// doit montrer le dernier contenu connu plutôt qu'une page d'erreur.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('le contenu écrit se relit à l’identique', () async {
    await CacheLocal.ecrire('fil', [
      {'id': 1, 'description': 'Buffet en bois massif'},
    ]);

    final entree = await CacheLocal.lire('fil');

    expect(entree, isNotNull);
    expect((entree!.contenu as List).first['description'], 'Buffet en bois massif');
  });

  test('une clé absente renvoie null', () async {
    expect(await CacheLocal.lire('inexistant'), isNull);
  });

  test('un contenu trop ancien est écarté', () async {
    final expire = DateTime.now().subtract(CacheLocal.dureeMax).subtract(const Duration(minutes: 1));

    SharedPreferences.setMockInitialValues({
      'cache_fil': '[{"id":1}]',
      'cache_date_fil': expire.millisecondsSinceEpoch,
    });

    // Au-delà de douze heures, mieux vaut ne rien montrer qu'un contenu
    // manifestement dépassé.
    expect(await CacheLocal.lire('fil'), isNull);
  });

  test('un contenu illisible est jeté sans faire planter l’écran', () async {
    SharedPreferences.setMockInitialValues({
      'cache_fil': 'ceci n’est pas du JSON',
      'cache_date_fil': DateTime.now().millisecondsSinceEpoch,
    });

    expect(await CacheLocal.lire('fil'), isNull);
  });

  test('la purge efface tout le cache', () async {
    await CacheLocal.ecrire('fil', [1]);
    await CacheLocal.ecrire('artisans', [2]);

    // Sur un téléphone partagé, le cache d'un compte ne doit pas rester
    // visible du suivant.
    await CacheLocal.viderTout();

    expect(await CacheLocal.lire('fil'), isNull);
    expect(await CacheLocal.lire('artisans'), isNull);
  });

  test('la date d’enregistrement est conservée', () async {
    await CacheLocal.ecrire('fil', [1]);

    final entree = await CacheLocal.lire('fil');

    expect(entree, isNotNull);
    expect(
      DateTime.now().difference(entree!.enregistreLe).inSeconds,
      lessThan(5),
    );
  });
}
