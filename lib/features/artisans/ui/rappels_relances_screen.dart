import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';

/// Rappels et relances (§5.2).
///
/// L'artisan note ce qu'il ne doit pas oublier : rappeler un client,
/// relancer un devis sans réponse, passer prendre un matériau, honorer un
/// rendez-vous. Chaque rappel peut être coché une fois fait.
class RappelsRelancesScreen extends StatefulWidget {
  const RappelsRelancesScreen({super.key});

  @override
  State<RappelsRelancesScreen> createState() => _RappelsRelancesScreenState();
}

class _RappelsRelancesScreenState extends State<RappelsRelancesScreen> {
  static const _cleRappels = 'artisan_rappels';

  List<Rappel> _rappels = const [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getStringList(_cleRappels) ?? [];

    final liste = <Rappel>[];
    for (final element in brut) {
      final r = Rappel.depuisChaine(element);
      if (r != null) liste.add(r);
    }
    // Tri : non faits d'abord, puis par date d'échéance croissante.
    liste.sort((a, b) {
      if (a.fait != b.fait) return a.fait ? 1 : -1;
      if (a.echeance != null && b.echeance != null) {
        return a.echeance!.compareTo(b.echeance!);
      }
      return b.creeLe.compareTo(a.creeLe);
    });

    if (!mounted) return;
    setState(() {
      _rappels = liste;
      _chargement = false;
    });
  }

  Future<void> _enregistrer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cleRappels,
      _rappels.map((r) => r.versChaine()).toList(),
    );
  }

  Future<void> _ajouter() async {
    final rappel = await showModalBottomSheet<Rappel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditeurRappel(),
    );

    if (rappel == null) return;

    setState(() => _rappels = [rappel, ..._rappels]);
    await _charger();
    await _enregistrer();
  }

  Future<void> _basculer(Rappel rappel) async {
    final index = _rappels.indexWhere((r) => r.id == rappel.id);
    if (index == -1) return;

    final misAJour = rappel.copierAvec(fait: !rappel.fait);

    setState(() {
      _rappels = [
        ..._rappels.sublist(0, index),
        misAJour,
        ..._rappels.sublist(index + 1),
      ];
    });
    await _charger();
    await _enregistrer();
  }

  Future<void> _supprimer(Rappel rappel) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce rappel ?'),
        content: Text('« ${rappel.titre} » sera définitivement retiré.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: MabokoCouleurs.danger),
            ),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() => _rappels = _rappels.where((r) => r.id != rappel.id).toList());
    await _enregistrer();
  }

  @override
  Widget build(BuildContext context) {
    final restants = _rappels.where((r) => !r.fait).length;

    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Rappels et relances'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        backgroundColor: MabokoCouleurs.secondaire,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nouveau rappel',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _chargement
          ? const ChargementEnCours()
          : _rappels.isEmpty
              ? _vide()
              : Column(
                  children: [
                    if (restants > 0) _compteur(restants),
                    Expanded(child: _liste()),
                  ],
                ),
    );
  }

  Widget _vide() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 60),
        EtatVide(
          icone: Icons.checklist_rounded,
          titre: 'Aucun rappel',
          message: 'Notez ici ce que vous ne devez pas oublier : rappeler un '
              'client, relancer un devis, passer prendre un matériau.',
        ),
      ],
    );
  }

  Widget _compteur(int restants) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: MabokoCouleurs.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active_outlined,
              size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              restants == 1
                  ? '1 rappel en attente'
                  : '$restants rappels en attente',
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9A6A0F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _liste() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _rappels.length,
      itemBuilder: (contexte, i) => _carte(_rappels[i]),
    );
  }

  Widget _carte(Rappel rappel) {
    final enRetard = !rappel.fait &&
        rappel.echeance != null &&
        rappel.echeance!.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enRetard
              ? MabokoCouleurs.danger.withValues(alpha: 0.5)
              : context.bordureMaboko,
          width: enRetard ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _basculer(rappel),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Case à cocher
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    rappel.fait
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: rappel.fait
                        ? MabokoCouleurs.succes
                        : context.texteSecondaireMaboko,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rappel.titre,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          decoration: rappel.fait
                              ? TextDecoration.lineThrough
                              : null,
                          color: rappel.fait
                              ? context.texteSecondaireMaboko
                              : context.texteFortMaboko,
                        ),
                      ),
                      if (rappel.details != null && rappel.details!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          rappel.details!,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: context.texteSecondaireMaboko,
                          ),
                        ),
                      ],
                      if (rappel.echeance != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              enRetard
                                  ? Icons.warning_amber_rounded
                                  : Icons.schedule_rounded,
                              size: 13,
                              color: enRetard
                                  ? MabokoCouleurs.danger
                                  : context.texteSecondaireMaboko,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _dateEcheance(rappel.echeance!),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: enRetard ? FontWeight.bold : FontWeight.normal,
                                color: enRetard
                                    ? MabokoCouleurs.danger
                                    : context.texteSecondaireMaboko,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Supprimer',
                  onPressed: () => _supprimer(rappel),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dateEcheance(DateTime date) {
    final maintenant = DateTime.now();
    final aujourdHui = DateTime(maintenant.year, maintenant.month, maintenant.day);
    final jour = DateTime(date.year, date.month, date.day);
    final diff = jour.difference(aujourdHui).inDays;

    final heure =
        '${date.hour.toString().padLeft(2, '0')}h${date.minute.toString().padLeft(2, '0')}';

    if (diff < 0) return 'En retard · ${-diff} j (${heure})';
    if (diff == 0) return 'Aujourd’hui à $heure';
    if (diff == 1) return 'Demain à $heure';
    if (diff < 7) return 'Dans $diff jours ($heure)';

    const mois = [
      'janv.', 'févr.', 'mars', 'avril', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    return 'Le ${date.day} ${mois[date.month - 1]} à $heure';
  }
}

// ---------------------------------------------------------------------------
// Modèle
// ---------------------------------------------------------------------------

/// Rappel encodé en `id|titre|details|echeanceMillis|fait|creationMillis`.
class Rappel {
  const Rappel({
    required this.id,
    required this.titre,
    required this.creeLe,
    this.details,
    this.echeance,
    this.fait = false,
  });

  final String id;
  final String titre;
  final String? details;
  final DateTime? echeance;
  final bool fait;
  final DateTime creeLe;

  Rappel copierAvec({bool? fait, String? titre, String? details, DateTime? echeance}) {
    return Rappel(
      id: id,
      titre: titre ?? this.titre,
      details: details ?? this.details,
      echeance: echeance ?? this.echeance,
      fait: fait ?? this.fait,
      creeLe: creeLe,
    );
  }

  String versChaine() {
    final t = titre.replaceAll('|', '&#124;');
    final d = (details ?? '').replaceAll('|', '&#124;');

    return '$id|$t|$d|${echeance?.millisecondsSinceEpoch ?? ''}|$fait|${creeLe.millisecondsSinceEpoch}';
  }

  static Rappel? depuisChaine(String brut) {
    final m = brut.split('|');
    if (m.length < 6) return null;

    return Rappel(
      id: m[0],
      titre: m[1].replaceAll('&#124;', '|'),
      details: m[2].isEmpty ? null : m[2].replaceAll('&#124;', '|'),
      echeance: m[3].isEmpty
          ? null
          : DateTime.fromMillisecondsSinceEpoch(int.tryParse(m[3]) ?? 0),
      fait: m[4] == 'true',
      creeLe: DateTime.fromMillisecondsSinceEpoch(int.tryParse(m[5]) ?? 0),
    );
  }
}

// ---------------------------------------------------------------------------
// Éditeur de rappel
// ---------------------------------------------------------------------------

class _EditeurRappel extends StatefulWidget {
  const _EditeurRappel();

  @override
  State<_EditeurRappel> createState() => _EditeurRappelState();
}

class _EditeurRappelState extends State<_EditeurRappel> {
  final _titre = TextEditingController();
  final _details = TextEditingController();

  DateTime? _echeance;

  @override
  void dispose() {
    _titre.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final maintenant = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _echeance ?? maintenant,
      firstDate: maintenant.subtract(const Duration(days: 1)),
      lastDate: maintenant.add(const Duration(days: 365)),
      locale: const Locale('fr', 'FR'),
    );

    if (date == null) return;

    if (!mounted) return;
    final heure = await showTimePicker(
      context: context,
      initialTime: _echeance != null
          ? TimeOfDay.fromDateTime(_echeance!)
          : const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );

    if (heure == null) return;

    setState(() {
      _echeance = DateTime(
        date.year,
        date.month,
        date.day,
        heure.hour,
        heure.minute,
      );
    });
  }

  void _valider() {
    if (_titre.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Donnez un titre à votre rappel.'),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      Rappel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        titre: _titre.text.trim(),
        details: _details.text.trim().isEmpty ? null : _details.text.trim(),
        echeance: _echeance,
        creeLe: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final basClavier = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: basClavier),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.bordureMaboko,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Nouveau rappel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _titre,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  'Titre',
                  Icons.title_rounded,
                  indice: 'Ex. : Rappeler le client de Bacongo',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _details,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration(
                  'Détails (facultatif)',
                  Icons.notes_rounded,
                  indice: 'Numéro, devis à relancer, adresse...',
                ),
              ),
              const SizedBox(height: 12),
              _carteEcheance(),
              const SizedBox(height: 22),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _valider,
                  style: FilledButton.styleFrom(
                    backgroundColor: MabokoCouleurs.secondaire,
                    foregroundColor: Colors.white,
                    shape:
                        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Enregistrer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carteEcheance() {
    final aEcheance = _echeance != null;

    return Material(
      color: context.surfaceMaboko,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _choisirDate,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: aEcheance ? MabokoCouleurs.secondaire : context.bordureMaboko,
              width: aEcheance ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.event_rounded,
                color: aEcheance
                    ? MabokoCouleurs.secondaire
                    : context.texteSecondaireMaboko,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aEcheance ? 'Échéance' : 'Ajouter une échéance (facultatif)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: aEcheance
                            ? MabokoCouleurs.secondaire
                            : context.texteFortMaboko,
                      ),
                    ),
                    if (aEcheance) ...[
                      const SizedBox(height: 3),
                      Text(
                        _formatEcheance(_echeance!),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: context.texteSecondaireMaboko,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (aEcheance)
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _echeance = null),
                )
              else
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: context.texteSecondaireMaboko),
            ],
          ),
        ),
      ),
    );
  }

  String _formatEcheance(DateTime d) {
    const mois = [
      'janv.', 'févr.', 'mars', 'avril', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];
    final heure =
        '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
    return '${d.day} ${mois[d.month - 1]} ${d.year} · $heure';
  }

  InputDecoration _decoration(String libelle, IconData icone,
      {String? indice}) {
    return InputDecoration(
      labelText: libelle,
      hintText: indice,
      prefixIcon: Icon(icone, size: 20, color: MabokoCouleurs.secondaire),
      filled: true,
      fillColor: context.surfaceMaboko,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.bordureMaboko),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.bordureMaboko),
      ),
    );
  }
}