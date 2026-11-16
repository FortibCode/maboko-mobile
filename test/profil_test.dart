import 'package:flutter_test/flutter_test.dart';
import 'package:maboko_mobile/features/compte/data/profil_repository.dart';

void main() {
  test('le profil lit le matricule renvoye par l API', () {
    final profil = ProfilUtilisateur.depuisJson({
      'id': 42,
      'nom': 'Mbemba',
      'role': 'artisan',
      'matricule': 'MBK-ART-00042',
    });

    expect(profil.matricule, 'MBK-ART-00042');
  });

  test('sans matricule, la carte ne s affiche pas', () {
    final profil = ProfilUtilisateur.depuisJson({'id': 1, 'nom': 'X', 'role': 'client'});

    expect(profil.matricule, isNull);
  });
}
