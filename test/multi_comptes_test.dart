import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maboko_mobile/features/compte/data/comptes_repository.dart';
import 'package:maboko_mobile/features/compte/ui/nouveau_profil_screen.dart';

void main() {
  test('un compte se lit au format de l API', () {
    final compte = CompteFamille.depuisJson({
      'id': 7,
      'nom': 'Mama',
      'prenom': 'Couture',
      'avatarUrl': null,
      'role': 'artisan',
      'estPrincipal': false,
      'estActif': true,
      'suspendu': false,
      'notificationsNonLues': 4,
    });

    expect(compte.nomComplet, 'Couture Mama');
    expect(compte.estActif, isTrue);
    expect(compte.notificationsNonLues, 4);
  });

  test('la session renvoyee par l API garde jeton et utilisateur', () {
    final session = SessionCompte.depuisJson({
      'token': '12|abc',
      'user': {'id': 7, 'nom': 'Mama', 'role': 'artisan'},
    });

    expect(session.jeton, '12|abc');
    expect(session.utilisateur['id'], 7);
  });

  testWidgets('le nouveau profil exige un nom', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: NouveauProfilScreen()));

    await tester.tap(find.text('Suivant'));
    await tester.pump();

    expect(find.text('Choisissez un nom de profil.'), findsOneWidget);
  });
}
