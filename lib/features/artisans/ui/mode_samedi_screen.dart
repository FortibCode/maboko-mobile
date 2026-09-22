import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/maboko_theme.dart';

/// Mode samedi (§5.2).
///
/// Beaucoup d'artisans travaillent le samedi, jour où les clients sont
/// disponibles. Ce mode signale aux clients qu'ils peuvent solliciter
/// l'artisan ce jour-là, avec des horaires précis.
class ModeSamediScreen extends StatefulWidget {
  const ModeSamediScreen({super.key});

  @override
  State<ModeSamediScreen> createState() => _ModeSamediScreenState();
}

class _ModeSamediScreenState extends State<ModeSamediScreen> {
  static const _cleActif = 'mode_samedi_actif';
  static const _cleDebut = 'mode_samedi_debut';
  static const _cleFin = 'mode_samedi_fin';
  static const _cleDimanche = 'mode_samedi_dimanche';

  bool _actif = false;
  bool _inclureDimanche = false;
  TimeOfDay _debut = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _fin = const TimeOfDay(hour: 14, minute: 0);
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
      _actif = prefs.getBool(_cleActif) ?? false;
      _inclureDimanche = prefs.getBool(_cleDimanche) ?? false;
      _debut = _heureDepuisChaine(prefs.getString(_cleDebut)) ?? _debut;
      _fin = _heureDepuisChaine(prefs.getString(_cleFin)) ?? _fin;
      _chargement = false;
    });
  }

  Future<void> _enregistrer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cleActif, _actif);
    await prefs.setBool(_cleDimanche, _inclureDimanche);
    await prefs.setString(_cleDebut, _heureVersChaine(_debut));
    await prefs.setString(_cleFin, _heureVersChaine(_fin));
  }

  Future<void> _choisirHeure({required bool debut}) async {
    final choix = await showTimePicker(
      context: context,
      initialTime: debut ? _debut : _fin,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (choix == null) return;

    // Un intervalle cohérent : la fin ne peut pas précéder le début.
    if (debut) {
      if (choix.hour * 60 + choix.minute >= _fin.hour * 60 + _fin.minute) {
        _informer('L’heure de début doit précéder la fin.',
            MabokoCouleurs.danger);
        return;
      }
      setState(() => _debut = choix);
    } else {
      if (choix.hour * 60 + choix.minute <= _debut.hour * 60 + _debut.minute) {
        _informer('L’heure de fin doit suivre le début.',
            MabokoCouleurs.danger);
        return;
      }
      setState(() => _fin = choix);
    }

    await _enregistrer();
  }

  Future<void> _basculer(bool valeur) async {
    setState(() => _actif = valeur);
    await _enregistrer();

    if (!mounted) return;
    _informer(
      valeur
          ? 'Vous êtes maintenant disponible le samedi.'
          : 'Vous ne recevrez plus de demandes le samedi.',
      valeur ? MabokoCouleurs.succes : MabokoCouleurs.principale,
    );
  }

  Future<void> _basculerDimanche(bool valeur) async {
    setState(() => _inclureDimanche = valeur);
    await _enregistrer();
  }

  void _informer(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: couleur),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Mode samedi'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _chargement
          ? const Center(
              child: CircularProgressIndicator(color: MabokoCouleurs.secondaire),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _encadre(),
                const SizedBox(height: 20),
                _cartePrincipale(),
                if (_actif) ...[
                  const SizedBox(height: 22),
                  _section('Horaires du samedi'),
                  _carteHoraires(),
                  const SizedBox(height: 22),
                  _section('Options'),
                  _carteDimanche(),
                  const SizedBox(height: 22),
                  _encadreVisible(),
                ],
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

  Widget _cartePrincipale() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _actif
            ? MabokoCouleurs.succes.withValues(alpha: 0.10)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _actif ? MabokoCouleurs.succes : context.bordureMaboko,
          width: _actif ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _actif
                  ? MabokoCouleurs.succes.withValues(alpha: 0.18)
                  : context.bordureMaboko,
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Icon(
              _actif
                  ? Icons.work_rounded
                  : Icons.work_off_outlined,
              color: _actif ? MabokoCouleurs.succes : context.texteSecondaireMaboko,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _actif
                      ? 'Disponible le samedi'
                      : 'Non disponible le samedi',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.bold,
                    color: _actif ? MabokoCouleurs.succes : context.texteFortMaboko,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _actif
                      ? 'Les clients peuvent vous solliciter.'
                      : 'Activez pour recevoir des demandes le samedi.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: context.texteSecondaireMaboko,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _actif,
            onChanged: _basculer,
            activeThumbColor: MabokoCouleurs.succes,
          ),
        ],
      ),
    );
  }

  Widget _carteHoraires() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Column(
        children: [
          _ligneHoraire(
            titre: 'Début',
            heure: _debut,
            icone: Icons.wb_twilight_rounded,
            onTap: () => _choisirHeure(debut: true),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ligneHoraire(
            titre: 'Fin',
            heure: _fin,
            icone: Icons.nights_stay_outlined,
            onTap: () => _choisirHeure(debut: false),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.schedule_rounded,
                    size: 18, color: context.texteSecondaireMaboko),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Plage : ${_formatHeure(_debut)} → ${_formatHeure(_fin)} '
                    '(${_dureeHeures()} h)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.texteSecondaireMaboko,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ligneHoraire({
    required String titre,
    required TimeOfDay heure,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icone, size: 20, color: MabokoCouleurs.secondaire),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: MabokoCouleurs.secondaire.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatHeure(heure),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: MabokoCouleurs.secondaire,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.edit_outlined,
                  size: 16, color: context.texteSecondaireMaboko),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carteDimanche() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inclure le dimanche',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  'Vous serez aussi joignable le dimanche, mêmes horaires.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: context.texteSecondaireMaboko,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _inclureDimanche,
            onChanged: _basculerDimanche,
            activeThumbColor: MabokoCouleurs.succes,
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
          const Icon(Icons.info_outline_rounded,
              size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Le samedi est le jour où les clients sont les plus disponibles. '
              'Beaucoup d’artisans refusent des missions faute d’être '
              'joignables ce jour-là : ce mode vous évite d’en perdre.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: context.texteSecondaireMaboko,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _encadreVisible() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: MabokoCouleurs.succes.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MabokoCouleurs.succes.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.visibility_outlined,
              size: 20, color: MabokoCouleurs.succes),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _inclureDimanche
                  ? 'Votre fiche indique : « Disponible samedi et dimanche '
                      'de ${_formatHeure(_debut)} à ${_formatHeure(_fin)} ».'
                  : 'Votre fiche indique : « Disponible le samedi de '
                      '${_formatHeure(_debut)} à ${_formatHeure(_fin)} ».',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: context.texteSecondaireMaboko,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers horaires
  // ---------------------------------------------------------------------------

  String _formatHeure(TimeOfDay heure) =>
      '${heure.hour.toString().padLeft(2, '0')}h'
      '${heure.minute.toString().padLeft(2, '0')}';

  int _dureeHeures() {
    final minutes =
        (_fin.hour * 60 + _fin.minute) - (_debut.hour * 60 + _debut.minute);
    return (minutes / 60).round();
  }

  String _heureVersChaine(TimeOfDay heure) =>
      '${heure.hour}:${heure.minute}';

  TimeOfDay? _heureDepuisChaine(String? chaine) {
    if (chaine == null) return null;
    final morceaux = chaine.split(':');
    if (morceaux.length != 2) return null;

    final h = int.tryParse(morceaux[0]);
    final m = int.tryParse(morceaux[1]);
    if (h == null || m == null) return null;

    return TimeOfDay(hour: h, minute: m);
  }
}