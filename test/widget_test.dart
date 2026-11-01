// Test de l'ecran d'ouverture de Maboko.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

//  L'importation relative évite les erreurs si le nom du package change
import 'package:maboko_mobile/main.dart'; 

void main() {
  testWidgets('Splash screen rendering test', (WidgetTester tester) async {
    // Initialise l'application MabokoApp et génère le premier frame
    await tester.pumpWidget(const MabokoApp());

    // Le logo (qui porte le nom et la devise) et le titre sont affichés
    expect(find.text("Bienvenue"), findsOneWidget);
    expect(
      find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == 'assets/images/maboko_logo.png'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 4));
  });
}