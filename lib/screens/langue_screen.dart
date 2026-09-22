import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/maboko_theme.dart';

/// Choix de la langue (§5.1.7).
///
/// L'application est en français pour l'instant. L'anglais est annoncé comme
/// « bientôt disponible » plutôt que laissé cliquable sans effet : un bouton
/// qui ne répond pas est pire qu'une absence.
///
/// La préférence est enregistrée localement. Elle sera lue au démarrage par
/// le `MaterialApp` pour appliquer la bonne locale.
class LangueScreen extends StatefulWidget {
  const LangueScreen({super.key});

  @override
  State<LangueScreen> createState() => _LangueScreenState();
}

class _LangueScreenState extends State<LangueScreen> {
  static const _cleLangue = 'langue_app';

  String _langue = 'fr';
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
      _langue = prefs.getString(_cleLangue) ?? 'fr';
      _chargement = false;
    });
  }

  Future<void> _choisir(String code) async {
    if (code != 'fr') {
      // L'anglais est prévu mais pas encore traduit. On informe plutôt que
      // de basculer sur une interface qui resterait en français.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L’anglais sera disponible dans une prochaine version.'),
          backgroundColor: MabokoCouleurs.accent,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cleLangue, code);

    if (!mounted) return;
    setState(() => _langue = code);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Langue enregistrée. Redémarrez l’application pour '
            'appliquer partout.'),
        backgroundColor: MabokoCouleurs.succes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Langue'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: MabokoCouleurs.secondaire))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _encadre(context),
                const SizedBox(height: 20),
                _section(context, 'Choisir la langue de l’application'),
                _carte(
                  context,
                  code: 'fr',
                  drapeau: '🇫🇷',
                  nom: 'Français',
                  sous: 'Langue actuelle',
                  disponible: true,
                ),
                const SizedBox(height: 10),
                _carte(
                  context,
                  code: 'en',
                  drapeau: '🇬🇧',
                  nom: 'English',
                  sous: 'Bientôt disponible',
                  disponible: false,
                ),
              ],
            ),
    );
  }

  Widget _section(BuildContext context, String titre) {
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

  Widget _carte(
    BuildContext context, {
    required String code,
    required String drapeau,
    required String nom,
    required String sous,
    required bool disponible,
  }) {
    final actif = _langue == code;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: disponible ? () => _choisir(code) : null,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko,
              width: actif ? 1.5 : 1,
            ),
          ),
          child: Opacity(
            opacity: disponible ? 1 : 0.55,
            child: Row(
              children: [
                Text(drapeau, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nom,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          )),
                      const SizedBox(height: 3),
                      Text(
                        sous,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.texteSecondaireMaboko,
                        ),
                      ),
                    ],
                  ),
                ),
                if (actif)
                  const Icon(Icons.check_circle_rounded,
                      color: MabokoCouleurs.secondaire, size: 24)
                else if (!disponible)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.bordureMaboko,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'À venir',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: context.texteSecondaireMaboko,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _encadre(BuildContext context) {
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
          const Icon(Icons.language_rounded, size: 22, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Maboko est utilisé au Congo et au-delà. La version anglaise '
              'arrive dans une prochaine mise à jour pour les utilisateurs '
              'hors zone francophone.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: context.texteSecondaireMaboko),
            ),
          ),
        ],
      ),
    );
  }
}