import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';

/// Calculateur de devis (§5.2).
///
/// L'artisan compose un devis : prestation, quantité, main d'œuvre,
/// matériaux, déplacement. Le total se calcule en direct. Les devis sont
/// conservés sur le téléphone, puis copiés dans un message ou une
/// conversation.
class CalculateurDevisScreen extends StatefulWidget {
  const CalculateurDevisScreen({super.key});

  @override
  State<CalculateurDevisScreen> createState() => _CalculateurDevisScreenState();
}

class _CalculateurDevisScreenState extends State<CalculateurDevisScreen> {
  static const _cleDevis = 'artisan_devis_sauvegardes';

  List<Devis> _devisSauvegardes = const [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getStringList(_cleDevis) ?? [];

    // Parsing explicite : map().whereType() pose un problème de typage
    // sur certaines versions du SDK.
    final liste = <Devis>[];
    for (final element in brut) {
      final devis = Devis.depuisChaine(element);
      if (devis != null) liste.add(devis);
    }
    liste.sort((a, b) => b.modifieLe.compareTo(a.modifieLe));

    if (!mounted) return;
    setState(() {
      _devisSauvegardes = liste;
      _chargement = false;
    });
  }

  Future<void> _sauvegarder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cleDevis,
      _devisSauvegardes.map((d) => d.versChaine()).toList(),
    );
  }

  Future<void> _nouveauDevis() async {
    final devis = await showModalBottomSheet<Devis>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditeurDevis(),
    );

    if (devis == null) return;

    setState(() => _devisSauvegardes = [devis, ..._devisSauvegardes]);
    await _sauvegarder();

    if (!mounted) return;
    _informer('Devis enregistré.', MabokoCouleurs.succes);
  }

  Future<void> _modifier(Devis devis) async {
    final modifie = await showModalBottomSheet<Devis>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditeurDevis(existant: devis),
    );

    if (modifie == null) return;

    setState(() {
      final i = _devisSauvegardes.indexWhere((d) => d.id == devis.id);
      if (i != -1) _devisSauvegardes[i] = modifie;
      _devisSauvegardes.sort((a, b) => b.modifieLe.compareTo(a.modifieLe));
    });
    await _sauvegarder();
  }

  Future<void> _supprimer(Devis devis) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce devis ?'),
        content: Text('« ${devis.titre} » sera définitivement retiré.'),
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

    setState(() => _devisSauvegardes =
        _devisSauvegardes.where((d) => d.id != devis.id).toList());
    await _sauvegarder();
  }

  Future<void> _copier(Devis devis) async {
    await Clipboard.setData(ClipboardData(text: devis.textePartageable()));
    if (!mounted) return;
    _informer('Devis copié. Collez-le où vous voulez.', MabokoCouleurs.succes);
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
        title: const Text('Calculateur de devis'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nouveauDevis,
        backgroundColor: MabokoCouleurs.secondaire,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Nouveau devis',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _chargement
          ? const ChargementEnCours()
          : _devisSauvegardes.isEmpty
              ? _vide()
              : _liste(),
    );
  }

  Widget _vide() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 60),
        EtatVide(
          icone: Icons.calculate_outlined,
          titre: 'Aucun devis',
          message: 'Composez un devis en quelques secondes : prestation, '
              'quantité, main d’œuvre, matériaux. Vous pourrez le copier '
              'dans une conversation.',
        ),
      ],
    );
  }

  Widget _liste() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _devisSauvegardes.length + 1,
      itemBuilder: (contexte, i) {
        if (i == 0) return _encadre();

        final devis = _devisSauvegardes[i - 1];
        return _carte(devis);
      },
    );
  }

  Widget _carte(Devis devis) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _modifier(devis),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        devis.titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      formaterFcfa(devis.total),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: MabokoCouleurs.secondaire,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                if (devis.client != null && devis.client!.isNotEmpty)
                  Text(
                    'Pour ${devis.client}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: context.texteSecondaireMaboko,
                    ),
                  ),
                const SizedBox(height: 8),
                Text(
                  devis.descriptionCourte(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: context.texteSecondaireMaboko,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      _dateLisible(devis.modifieLe),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: context.texteSecondaireMaboko,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          size: 18, color: MabokoCouleurs.secondaire),
                      tooltip: 'Copier le devis',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _copier(devis),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: MabokoCouleurs.danger),
                      tooltip: 'Supprimer',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _supprimer(devis),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _encadre() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.teinteMaboko,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Composez un devis clair pour votre client. Vous pourrez le '
              'copier et le coller dans votre conversation Maboko, WhatsApp '
              'ou SMS.',
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

  String _dateLisible(DateTime date) {
    final d = DateTime.now().difference(date);
    if (d.inMinutes < 1) return 'à l’instant';
    if (d.inHours < 1) return 'il y a ${d.inMinutes} min';
    if (d.inDays < 1) return 'il y a ${d.inHours} h';
    if (d.inDays == 1) return 'hier';
    if (d.inDays < 7) return 'il y a ${d.inDays} j';

    return '${date.day}/${date.month}/${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Modèle
// ---------------------------------------------------------------------------

class LigneDevis {
  const LigneDevis({
    required this.libelle,
    required this.quantite,
    required this.prixUnitaire,
    this.unite = '',
  });

  final String libelle;
  final double quantite;
  final double prixUnitaire;
  final String unite;

  double get total => quantite * prixUnitaire;

  String versChaine() => '$libelle~$quantite~$prixUnitaire~$unite';

  static LigneDevis? depuisChaine(String brut) {
    final m = brut.split('~');
    if (m.length < 4) return null;

    return LigneDevis(
      libelle: m[0],
      quantite: double.tryParse(m[1]) ?? 0,
      prixUnitaire: double.tryParse(m[2]) ?? 0,
      unite: m[3],
    );
  }
}

/// Devis sauvegardé, encodé en `id|titre|client|notes|lignes|deplacement|horodatage`.
class Devis {
  const Devis({
    required this.id,
    required this.titre,
    required this.lignes,
    required this.modifieLe,
    this.client,
    this.notes,
    this.deplacement = 0,
  });

  final String id;
  final String titre;
  final String? client;
  final String? notes;
  final List<LigneDevis> lignes;
  final double deplacement;
  final DateTime modifieLe;

  double get sousTotal => lignes.fold(0, (s, l) => s + l.total);
  double get total => sousTotal + deplacement;

  String descriptionCourte() {
    if (lignes.isEmpty) return 'Aucune ligne';
    if (lignes.length == 1) return lignes.first.libelle;
    return '${lignes.first.libelle} + ${lignes.length - 1} autre(s)';
  }

  String textePartageable() {
    final buffer = StringBuffer();
    buffer.writeln('DEVIS — $titre');
    if (client != null && client!.isNotEmpty) buffer.writeln('Client : $client');
    buffer.writeln('');
    for (final l in lignes) {
      final unite = l.unite.isEmpty ? '' : ' ${l.unite}';
      buffer.writeln(
          '• ${l.libelle} : ${l.quantite}$unite × ${formaterFcfa(l.prixUnitaire)} = ${formaterFcfa(l.total)}');
    }
    if (deplacement > 0) {
      buffer.writeln('• Déplacement : ${formaterFcfa(deplacement)}');
    }
    buffer.writeln('');
    buffer.writeln('TOTAL : ${formaterFcfa(total)}');
    if (notes != null && notes!.isNotEmpty) {
      buffer.writeln('');
      buffer.writeln('Notes : $notes');
    }
    buffer.writeln('');
    buffer.writeln('Devis établi via Maboko.');
    return buffer.toString();
  }

  String versChaine() {
    final lignesEncodees = lignes.map((l) => l.versChaine()).join('§');
    final titreSafe = titre.replaceAll('|', '&#124;').replaceAll('§', '&#167;');
    final clientSafe =
        (client ?? '').replaceAll('|', '&#124;').replaceAll('§', '&#167;');
    final notesSafe =
        (notes ?? '').replaceAll('|', '&#124;').replaceAll('§', '&#167;');

    return '$id|$titreSafe|$clientSafe|$notesSafe|$lignesEncodees|$deplacement|${modifieLe.millisecondsSinceEpoch}';
  }

  static Devis? depuisChaine(String brut) {
    final m = brut.split('|');
    if (m.length < 7) return null;

    // Parsing explicite des lignes : map().whereType() pose un problème
    // de typage sur certaines versions du SDK.
    final lignes = <LigneDevis>[];
    if (m[4].isNotEmpty) {
      for (final element in m[4].split('§')) {
        final ligne = LigneDevis.depuisChaine(element);
        if (ligne != null) lignes.add(ligne);
      }
    }

    return Devis(
      id: m[0],
      titre: m[1].replaceAll('&#124;', '|').replaceAll('&#167;', '§'),
      client: m[2].isEmpty
          ? null
          : m[2].replaceAll('&#124;', '|').replaceAll('&#167;', '§'),
      notes: m[3].isEmpty
          ? null
          : m[3].replaceAll('&#124;', '|').replaceAll('&#167;', '§'),
      lignes: lignes,
      deplacement: double.tryParse(m[5]) ?? 0,
      modifieLe: DateTime.fromMillisecondsSinceEpoch(int.tryParse(m[6]) ?? 0),
    );
  }
}

// ---------------------------------------------------------------------------
// Éditeur de devis (feuille du bas)
// ---------------------------------------------------------------------------

class _EditeurDevis extends StatefulWidget {
  const _EditeurDevis({this.existant});

  final Devis? existant;

  @override
  State<_EditeurDevis> createState() => _EditeurDevisState();
}

class _EditeurDevisState extends State<_EditeurDevis> {
  late final TextEditingController _titre;
  late final TextEditingController _client;
  late final TextEditingController _notes;
  late final TextEditingController _deplacement;

  final List<LigneDevis> _lignes = [];

  @override
  void initState() {
    super.initState();
    final e = widget.existant;

    _titre = TextEditingController(text: e?.titre ?? '');
    _client = TextEditingController(text: e?.client ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _deplacement = TextEditingController(
        text: e == null || e.deplacement == 0 ? '' : e.deplacement.toString());
    _lignes.addAll(e?.lignes ?? []);
  }

  @override
  void dispose() {
    _titre.dispose();
    _client.dispose();
    _notes.dispose();
    _deplacement.dispose();
    super.dispose();
  }

  double get _total {
    final d = double.tryParse(_deplacement.text.replaceAll(',', '.')) ?? 0;
    return _lignes.fold<double>(0, (s, l) => s + l.total) + d;
  }

  Future<void> _ajouterLigne() async {
    final ligne = await showDialog<LigneDevis>(
      context: context,
      builder: (_) => const _DialogueLigne(),
    );

    if (ligne == null) return;
    setState(() => _lignes.add(ligne));
  }

  void _retirerLigne(int index) {
    setState(() => _lignes.removeAt(index));
  }

  void _valider() {
    if (_titre.text.trim().isEmpty) {
      _informer('Donnez un titre à votre devis.', MabokoCouleurs.danger);
      return;
    }

    if (_lignes.isEmpty) {
      _informer('Ajoutez au moins une ligne.', MabokoCouleurs.danger);
      return;
    }

    final devis = Devis(
      id: widget.existant?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      titre: _titre.text.trim(),
      client: _client.text.trim().isEmpty ? null : _client.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      lignes: List.unmodifiable(_lignes),
      deplacement: double.tryParse(_deplacement.text.replaceAll(',', '.')) ?? 0,
      modifieLe: DateTime.now(),
    );

    Navigator.pop(context, devis);
  }

  void _informer(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: couleur),
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
              Text(
                widget.existant == null ? 'Nouveau devis' : 'Modifier le devis',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),

              TextField(
                controller: _titre,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration('Titre', Icons.title_rounded,
                    indice: 'Ex. : Réparation de toiture'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _client,
                textCapitalization: TextCapitalization.words,
                decoration: _decoration('Client (facultatif)',
                    Icons.person_outline_rounded),
              ),
              const SizedBox(height: 22),

              Row(
                children: [
                  const Text('Lignes',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _ajouterLigne,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Ajouter'),
                    style: TextButton.styleFrom(
                      foregroundColor: MabokoCouleurs.secondaire,
                    ),
                  ),
                ],
              ),
              if (_lignes.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Aucune ligne pour l’instant. Ajoutez une prestation, un '
                    'matériau, etc.',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.texteSecondaireMaboko,
                    ),
                  ),
                )
              else
                ...List.generate(_lignes.length, (i) {
                  final l = _lignes[i];
                  return Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.surfaceMaboko,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.bordureMaboko),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.libelle,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              const SizedBox(height: 3),
                              Text(
                                '${l.quantite}${l.unite.isEmpty ? '' : ' ${l.unite}'} × ${formaterFcfa(l.prixUnitaire)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.texteSecondaireMaboko,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formaterFcfa(l.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: MabokoCouleurs.secondaire,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _retirerLigne(i),
                        ),
                      ],
                    ),
                  );
                }),

              const SizedBox(height: 22),
              TextField(
                controller: _deplacement,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: _decoration('Déplacement (facultatif)',
                    Icons.directions_car_outlined,
                    indice: 'Montant en FCFA'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration('Notes (facultatif)',
                    Icons.notes_rounded,
                    indice: 'Délai, conditions...'),
              ),
              const SizedBox(height: 22),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: MabokoCouleurs.secondaire.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: MabokoCouleurs.secondaire.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Text('TOTAL',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    Text(
                      formaterFcfa(_total),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: MabokoCouleurs.secondaire,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _valider,
                  style: FilledButton.styleFrom(
                    backgroundColor: MabokoCouleurs.secondaire,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Enregistrer',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

// ---------------------------------------------------------------------------
// Dialogue d'ajout de ligne
// ---------------------------------------------------------------------------

class _DialogueLigne extends StatefulWidget {
  const _DialogueLigne();

  @override
  State<_DialogueLigne> createState() => _DialogueLigneState();
}

class _DialogueLigneState extends State<_DialogueLigne> {
  final _libelle = TextEditingController();
  final _quantite = TextEditingController(text: '1');
  final _prix = TextEditingController();
  String _unite = '';

  static const _unites = ['', 'm²', 'ml', 'u', 'forfait', 'heure', 'jour'];

  @override
  void dispose() {
    _libelle.dispose();
    _quantite.dispose();
    _prix.dispose();
    super.dispose();
  }

  void _valider() {
    if (_libelle.text.trim().isEmpty) return;
    final q = double.tryParse(_quantite.text.replaceAll(',', '.')) ?? 0;
    final p = double.tryParse(_prix.text.replaceAll(',', '.')) ?? 0;

    if (q <= 0 || p <= 0) return;

    Navigator.pop(
      context,
      LigneDevis(
        libelle: _libelle.text.trim(),
        quantite: q,
        prixUnitaire: p,
        unite: _unite,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Ajouter une ligne'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _libelle,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Désignation',
                hintText: 'Ex. : Pose de tôles',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantite,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(labelText: 'Quantité'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _unite,
                    decoration: const InputDecoration(labelText: 'Unité'),
                    items: _unites
                        .map((u) => DropdownMenuItem(
                            value: u, child: Text(u.isEmpty ? '—' : u)))
                        .toList(),
                    onChanged: (v) => setState(() => _unite = v ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _prix,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Prix unitaire (FCFA)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        TextButton(
          onPressed: _valider,
          child: const Text('Ajouter',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}