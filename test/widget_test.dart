// This is a basic Flutter widget test for Maboko Mobile.
import 'package:flutter_test/flutter_test.dart';

//  L'importation relative évite les erreurs si le nom du package change
import 'package:maboko_mobile/main.dart'; 

void main() {
  testWidgets('Splash screen rendering test', (WidgetTester tester) async {
    // Initialise l'application MabokoApp et génère le premier frame
    await tester.pumpWidget(const MabokoApp());

    // Vérifie que les textes de bienvenue du SplashScreen sont bien affichés à l'écran
    expect(find.text("Bienvenue sur\nMaboko Mobile"), findsOneWidget);
    expect(find.text("Les mains qui font le Congo"), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
  });
}