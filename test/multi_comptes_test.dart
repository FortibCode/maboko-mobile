import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:maboko_mobile/core/network/api_client.dart';
import 'package:maboko_mobile/core/network/api_exception.dart';
import 'package:maboko_mobile/features/compte/data/comptes_repository.dart';
import 'package:maboko_mobile/features/compte/ui/associer_compte_screen.dart';
import 'package:maboko_mobile/features/compte/ui/nouveau_profil_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('format de l API', () {
    test('un compte se lit avec sa specialite et son etat', () {
      final compte = CompteFamille.depuisJson({
        'id': 7,
        'nom': 'Mama',
        'prenom': 'Couture',
        'role': 'artisan',
        'specialite': 'Couturière',
        'estPrincipal': false,
        'estActif': true,
        'archive': false,
        'notificationsNonLues': 4,
      });

      expect(compte.nomComplet, 'Couture Mama');
      expect(compte.specialiteAffichable, 'Couturière');
      expect(compte.estActif, isTrue);
      expect(compte.notificationsNonLues, 4);
    });

    test('une fiche jamais completee n affiche pas de specialite', () {
      final compte = CompteFamille.depuisJson({'id': 1, 'nom': 'X', 'specialite': 'À compléter'});

      expect(compte.specialiteAffichable, isNull);
    });

    test('une session n est rendue que si l API en ouvre une', () {
      expect(SessionCompte.siPresente({'message': 'Compte retiré.'}), isNull);
      expect(
        SessionCompte.siPresente({'token': '9|x', 'user': {'id': 1}})?.jeton,
        '9|x',
      );
    });
  });

  test('le numero saisi pour une association suit la regle de la connexion', () {
    expect(AssocierCompteScreen.normaliserIdentifiant('061234567'), '+242061234567');
    expect(AssocierCompteScreen.normaliserIdentifiant(' 61234567 '), '+242061234567');
    expect(AssocierCompteScreen.normaliserIdentifiant('mama@exemple.cg'), 'mama@exemple.cg');
  });

  group('session expiree (401)', () {
    late bool sessionExpiree;

    setUp(() {
      sessionExpiree = false;
      ApiClient.onSessionExpiree = () => sessionExpiree = true;
    });

    tearDown(() => ApiClient.onSessionExpiree = null);

    test('un jeton revoque efface la session locale', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'ancien'});
      final client = ApiClient(client: MockClient((_) async => http.Response('{}', 401)));

      await expectLater(client.get('/user'), throwsA(isA<ApiException>()));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
      expect(sessionExpiree, isTrue);
    });

    test('une requete partie avec le jeton d un compte quitte n efface pas la nouvelle session', () async {
      SharedPreferences.setMockInitialValues({'auth_token': 'compte-a'});
      final client = ApiClient(client: MockClient((_) async {
        // Changement de compte pendant que la requete etait en route.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', 'compte-b');
        return http.Response('{}', 401);
      }));

      await expectLater(client.get('/notifications'), throwsA(isA<ApiException>()));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'compte-b');
      expect(sessionExpiree, isFalse);
    });
  });

  testWidgets('le nouveau compte exige un nom', (tester) async {
    // Écran haut : tout le formulaire tient sans défiler.
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: NouveauProfilScreen()));

    await tester.tap(find.text('Créer le compte'));
    await tester.pump();

    expect(find.text('Choisissez un nom pour ce compte.'), findsOneWidget);
  });
}
