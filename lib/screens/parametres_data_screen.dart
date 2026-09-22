import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/cache/cache_local.dart';
import '../core/theme/maboko_theme.dart';

/// Paramètres data du client (§5.1.7).
///
/// Contrôle ce que l'application télécharge et stocke : qualité des images,
/// lecture auto des vidéos, cache local. Utile quand on paie sa connexion
/// au méga et qu'on veut éviter de tout consommer en scrollant.
class ParametresDataScreen extends StatefulWidget {
  const ParametresDataScreen({super.key});

  @override
  State<ParametresDataScreen> createState() => _ParametresDataScreenState();
}

class _ParametresDataScreenState extends State<ParametresDataScreen> {
  static const _cleQualiteImages = 'data_qualite_images';
  static const _cleVideosAuto = 'data_videos_auto';
  static const _cleModeEconomie = 'data_mode_economie';
  static const _clePrechargement = 'data_prechargement';

  String _qualiteImages = 'moyenne';
  bool _videosAuto = false;
  bool _modeEconomie = false;
  bool _prechargement = true;
  bool _chargement = true;
  String _tailleCache = '…';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    final taille = await _calculerTailleCache();

    if (!mounted) return;
    setState(() {
      _qualiteImages = prefs.getString(_cleQualiteImages) ?? 'moyenne';
      _videosAuto = prefs.getBool(_cleVideosAuto) ?? false;
      _modeEconomie = prefs.getBool(_cleModeEconomie) ?? false;
      _prechargement = prefs.getBool(_clePrechargement) ?? true;
      _tailleCache = taille;
      _chargement = false;
    });
  }

  Future<String> _calculerTailleCache() async {
    try {
      final octets = await CacheLocal.taille();
      if (octets < 1024) return '$octets o';
      if (octets < 1024 * 1024) return '${(octets / 1024).toStringAsFixed(1)} Ko';
      return '${(octets / (1024 * 1024)).toStringAsFixed(1)} Mo';
    } catch (_) {
      return 'Inconnue';
    }
  }

  Future<void> _enregistrer(String cle, Object valeur) async {
    final prefs = await SharedPreferences.getInstance();
    if (valeur is String) await prefs.setString(cle, valeur);
    if (valeur is bool) await prefs.setBool(cle, valeur);
  }

  Future<void> _viderCache() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vider le cache ?'),
        content: const Text(
          'Les images et vidéos déjà téléchargées seront supprimées. '
          'Elles se rechargeront à la prochaine ouverture des écrans concernés.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vider', style: TextStyle(color: MabokoCouleurs.danger)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    await CacheLocal.viderTout();
    final taille = await _calculerTailleCache();
    if (!mounted) return;

    setState(() => _tailleCache = taille);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache vidé.'), backgroundColor: MabokoCouleurs.succes),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Paramètres data'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: MabokoCouleurs.secondaire))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _section('Images'),
                _choixQualite(),
                const SizedBox(height: 22),
                _section('Vidéos'),
                _bascule(
                  titre: 'Lecture automatique',
                  sous: 'Lancer les vidéos du fil dès qu’elles apparaissent.',
                  valeur: _videosAuto,
                  onChanged: (v) {
                    setState(() => _videosAuto = v);
                    _enregistrer(_cleVideosAuto, v);
                  },
                ),
                const SizedBox(height: 22),
                _section('Économie de données'),
                _bascule(
                  titre: 'Mode économie',
                  sous: 'Réduit la qualité des images et désactive les vidéos '
                      'automatiques quand le réseau est lent.',
                  valeur: _modeEconomie,
                  onChanged: (v) {
                    setState(() => _modeEconomie = v);
                    _enregistrer(_cleModeEconomie, v);
                  },
                ),
                const SizedBox(height: 22),
                _section('Cache'),
                _bascule(
                  titre: 'Précharger le fil',
                  sous: 'Garde les prochaines publications en mémoire pour un '
                      'défilement plus fluide.',
                  valeur: _prechargement,
                  onChanged: (v) {
                    setState(() => _prechargement = v);
                    _enregistrer(_clePrechargement, v);
                  },
                ),
                const SizedBox(height: 12),
                _ligneCache(),
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

  Widget _choixQualite() {
    const choix = [
      ('basse', 'Basse', 'Consomme le moins de données'),
      ('moyenne', 'Moyenne', 'Bon compromis qualité / data'),
      ('haute', 'Haute', 'Meilleure qualité, plus de data'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Column(
        children: choix.map((c) {
          final actif = _qualiteImages == c.$1;

          return RadioListTile<String>(
            value: c.$1,
            groupValue: _qualiteImages,
            onChanged: (v) {
              if (v == null) return;
              setState(() => _qualiteImages = v);
              _enregistrer(_cleQualiteImages, v);
            },
            activeColor: MabokoCouleurs.secondaire,
            title: Text(c.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: Text(c.$3, style: const TextStyle(fontSize: 12)),
            secondary: Icon(
              actif ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko,
              size: 20,
            ),
          );
        }).toList(),
      ),
    );
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
                Text(titre, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 3),
                Text(sous,
                    style: TextStyle(fontSize: 12, height: 1.35, color: context.texteSecondaireMaboko)),
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

  Widget _ligneCache() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Row(
        children: [
          Icon(Icons.storage_rounded, color: context.texteSecondaireMaboko, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cache local',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(_tailleCache,
                    style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko)),
              ],
            ),
          ),
          TextButton(
            onPressed: _viderCache,
            style: TextButton.styleFrom(foregroundColor: MabokoCouleurs.danger),
            child: const Text('Vider', style: TextStyle(fontWeight: FontWeight.bold)),
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
          const Icon(Icons.lightbulb_outline_rounded, size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Le mode économie est utile quand vous êtes en 3G ou que votre '
              'forfait approche de la limite. Vos préférences sont enregistrées '
              'sur cet appareil.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: context.texteSecondaireMaboko),
            ),
          ),
        ],
      ),
    );
  }
}