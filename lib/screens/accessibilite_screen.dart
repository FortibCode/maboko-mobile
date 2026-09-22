import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/maboko_theme.dart';

/// Accessibilité (§5.1.7).
///
/// Trois réglages qui changent réellement l'usage pour une personne
/// malvoyante, âgée, ou simplement dans le soleil : taille du texte,
/// contraste renforcé, et réduction des animations. Les préférences sont
/// locales au téléphone.
class AccessibiliteScreen extends StatefulWidget {
  const AccessibiliteScreen({super.key});

  @override
  State<AccessibiliteScreen> createState() => _AccessibiliteScreenState();
}

class _AccessibiliteScreenState extends State<AccessibiliteScreen> {
  static const _cleEchelleTexte = 'acces_echelle_texte';
  static const _cleContraste = 'acces_contraste_eleve';
  static const _cleReduireAnimations = 'acces_reduire_animations';
  static const _cleGras = 'acces_texte_gras';

  double _echelleTexte = 1.0;
  bool _contraste = false;
  bool _reduireAnimations = false;
  bool _gras = false;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _echelleTexte = prefs.getDouble(_cleEchelleTexte) ?? 1.0;
      _contraste = prefs.getBool(_cleContraste) ?? false;
      _reduireAnimations = prefs.getBool(_cleReduireAnimations) ?? false;
      _gras = prefs.getBool(_cleGras) ?? false;
      _chargement = false;
    });
  }

  Future<void> _enregistrer(String cle, Object valeur) async {
    final prefs = await SharedPreferences.getInstance();
    if (valeur is double) await prefs.setDouble(cle, valeur);
    if (valeur is bool) await prefs.setBool(cle, valeur);
  }

  Future<void> _reinitialiser() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Réinitialiser ?'),
        content: const Text('Tous les réglages d’accessibilité reviendront '
            'aux valeurs par défaut.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Réinitialiser', style: TextStyle(color: MabokoCouleurs.danger)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cleEchelleTexte);
    await prefs.remove(_cleContraste);
    await prefs.remove(_cleReduireAnimations);
    await prefs.remove(_cleGras);
    await _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Accessibilité'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Réinitialiser',
            onPressed: _reinitialiser,
          ),
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: MabokoCouleurs.secondaire))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _apercu(),
                const SizedBox(height: 22),
                _section('Taille du texte'),
                _curseurTaille(),
                const SizedBox(height: 22),
                _section('Lisibilité'),
                _bascule(
                  titre: 'Texte en gras',
                  sous: 'Épaissit légèrement toutes les polices pour mieux '
                      'distinguer les lettres.',
                  valeur: _gras,
                  onChanged: (v) {
                    setState(() => _gras = v);
                    _enregistrer(_cleGras, v);
                  },
                ),
                const SizedBox(height: 12),
                _bascule(
                  titre: 'Contraste élevé',
                  sous: 'Renforce les bordures et les séparations entre les '
                      'zones de l’écran.',
                  valeur: _contraste,
                  onChanged: (v) {
                    setState(() => _contraste = v);
                    _enregistrer(_cleContraste, v);
                  },
                ),
                const SizedBox(height: 22),
                _section('Animations'),
                _bascule(
                  titre: 'Réduire les animations',
                  sous: 'Désactive les transitions douces et les effets de '
                      'défilement. Utile si le mouvement vous gêne.',
                  valeur: _reduireAnimations,
                  onChanged: (v) {
                    setState(() => _reduireAnimations = v);
                    _enregistrer(_cleReduireAnimations, v);
                  },
                ),
                const SizedBox(height: 22),
                _encadre(),
              ],
            ),
    );
  }

  Widget _section(String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        titre,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.texteSecondaireMaboko,
          letterSpacing: .3,
        ),
      ),
    );
  }

  /// Aperçu en direct : on voit tout de suite l'effet des réglages sur du
  /// vrai texte, plutôt que de devoir revenir en arrière pour tester.
  Widget _apercu() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _contraste ? MabokoCouleurs.principale : context.bordureMaboko,
          width: _contraste ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aperçu',
            style: TextStyle(
              fontSize: 12 * _echelleTexte,
              fontWeight: FontWeight.w600,
              color: context.texteSecondaireMaboko,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Un menuisier peut réparer votre porte en une matinée.',
            style: TextStyle(
              fontSize: 15 * _echelleTexte,
              height: 1.4,
              fontWeight: _gras ? FontWeight.w600 : FontWeight.normal,
              color: _contraste
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: MabokoCouleurs.secondaire,
                  shape: BoxShape.circle,
                  border: _contraste ? Border.all(color: MabokoCouleurs.principale, width: 1.5) : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Élément cliquable',
                style: TextStyle(
                  fontSize: 13 * _echelleTexte,
                  fontWeight: _gras ? FontWeight.w600 : FontWeight.normal,
                  color: MabokoCouleurs.secondaire,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _curseurTaille() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('A', style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko)),
              const Spacer(),
              Text(
                _libelleEchelle(),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const Spacer(),
              Text('A', style: TextStyle(fontSize: 22, color: context.texteSecondaireMaboko)),
            ],
          ),
          Slider(
            value: _echelleTexte,
            min: 0.8,
            max: 1.6,
            divisions: 8,
            activeColor: MabokoCouleurs.secondaire,
            label: _libelleEchelle(),
            onChanged: (v) {
              setState(() => _echelleTexte = v);
              _enregistrer(_cleEchelleTexte, v);
            },
          ),
        ],
      ),
    );
  }

  String _libelleEchelle() {
    final pourcentage = (_echelleTexte * 100).round();

    if (pourcentage <= 90) return 'Petit';
    if (pourcentage <= 105) return 'Normal';
    if (pourcentage <= 125) return 'Grand';
    return 'Très grand';
  }

  Widget _bascule({
    required String titre,
    required String sous,
    required bool valeur,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre,
                    style: TextStyle(
                      fontWeight: _gras ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    )),
                const SizedBox(height: 3),
                Text(sous,
                    style: TextStyle(
                        fontSize: 12, height: 1.35, color: context.texteSecondaireMaboko)),
              ],
            ),
          ),
          Switch(
            value: valeur,
            onChanged: onChanged,
            activeThumbColor: MabokoCouleurs.secondaire,
          ),
        ],
      ),
    );
  }

  Widget _encadre() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.teinteMaboko,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ces réglages sont enregistrés sur cet appareil. Ils s’appliquent '
              'aux prochains écrans que vous ouvrirez. Les autres appareils '
              'gardent leurs propres préférences.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: context.texteSecondaireMaboko),
            ),
          ),
        ],
      ),
    );
  }
}