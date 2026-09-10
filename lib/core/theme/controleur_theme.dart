import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'maboko_theme.dart';

/// Bascule clair / sombre, mémorisée d'une session à l'autre.
///
/// Maboko s'ouvre en clair, quel que soit le réglage du téléphone : c'est la
/// charte de la marque, et un utilisateur dont l'appareil est en sombre
/// découvrait l'application dans des couleurs qu'il n'avait pas choisies. Le
/// mode sombre reste à un appui, et son choix est mémorisé.
class ControleurTheme extends ChangeNotifier {
  static const _cle = 'mode_theme';

  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  bool estSombre(BuildContext context) => switch (_mode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system =>
          MediaQuery.platformBrightnessOf(context) == Brightness.dark,
      };

  Future<void> charger() async {
    final prefs = await SharedPreferences.getInstance();
    final valeur = prefs.getString(_cle);

    _mode = switch (valeur) {
      'clair' => ThemeMode.light,
      'sombre' => ThemeMode.dark,
      // Rien de memorise : on ouvre en clair.
      _ => ThemeMode.light,
    };
    notifyListeners();
  }

  Future<void> basculer(BuildContext context) async {
    // Depuis « système », on bascule vers l'inverse de ce qui est affiché :
    // l'utilisateur voit le changement qu'il attendait du premier coup.
    _mode = estSombre(context) ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cle, _mode == ThemeMode.dark ? 'sombre' : 'clair');
  }
}

/// Palette sombre : les couleurs de la charte restent reconnaissables, seuls
/// les fonds et les textes s'inversent.
class MabokoThemes {
  const MabokoThemes._();

  static ThemeData get clair => ThemeData(
        brightness: Brightness.light,
        primaryColor: MabokoCouleurs.secondaire,
        scaffoldBackgroundColor: MabokoCouleurs.fond,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MabokoCouleurs.secondaire,
          primary: MabokoCouleurs.secondaire,
          surface: MabokoCouleurs.surface,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: MabokoCouleurs.surface,
          foregroundColor: MabokoCouleurs.principale,
          elevation: 0,
        ),
        cardColor: MabokoCouleurs.surface,
        dividerColor: MabokoCouleurs.bordure,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MabokoCouleurs.secondaire,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: MabokoCouleurs.secondaire),
        ),
      );

  static ThemeData get sombre => ThemeData(
        brightness: Brightness.dark,
        primaryColor: MabokoCouleurs.accent,
        scaffoldBackgroundColor: const Color(0xFF161210),
        colorScheme: ColorScheme.fromSeed(
          seedColor: MabokoCouleurs.secondaire,
          brightness: Brightness.dark,
          primary: MabokoCouleurs.accent,
          surface: const Color(0xFF221B17),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF221B17),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardColor: const Color(0xFF221B17),
        dividerColor: const Color(0xFF3A2E27),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: MabokoCouleurs.secondaire,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: MabokoCouleurs.accent),
        ),
      );
}
