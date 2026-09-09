import 'package:flutter_test/flutter_test.dart';
import 'package:maboko_mobile/core/theme/maboko_theme.dart';

void main() {
  group('Formatage des montants', () {
    test('les milliers sont séparés par une espace', () {
      expect(formaterFcfa(195000), '195 000 FCFA');
      expect(formaterFcfa(1500), '1 500 FCFA');
      expect(formaterFcfa(500), '500 FCFA');
      expect(formaterFcfa(1234567), '1 234 567 FCFA');
    });

    test('un montant absent s’affiche par un tiret', () {
      expect(formaterFcfa(null), '—');
    });

    test('les décimales sont arrondies', () {
      expect(formaterFcfa(1499.6), '1 500 FCFA');
    });
  });

  group('Libellés de statut', () {
    test('chaque statut de l’API a un libellé lisible', () {
      const statuts = ['en_attente', 'acceptee', 'en_cours', 'terminee', 'refusee', 'annulee'];

      for (final statut in statuts) {
        final libelle = MabokoCouleurs.libelleStatut(statut);
        expect(libelle, isNot(statut), reason: 'Le statut « $statut » n’est pas traduit.');
        expect(libelle, isNot(contains('_')));
      }
    });
  });
}
