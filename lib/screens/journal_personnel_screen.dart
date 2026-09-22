import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/maboko_theme.dart';
import '../core/widgets/etats.dart';

/// Mon journal personnel (§5.1.7).
///
/// Le client note ce qu'il veut : un artisan à rappeler, un devis à comparer,
/// l'état d'un chantier. Stocké uniquement sur le téléphone — ce sont des
/// notes personnelles, elles n'ont aucune raison de partir au serveur.
class JournalPersonnelScreen extends StatefulWidget {
  const JournalPersonnelScreen({super.key});

  @override
  State<JournalPersonnelScreen> createState() => _JournalPersonnelScreenState();
}

class _JournalPersonnelScreenState extends State<JournalPersonnelScreen> {
  static const _cleNotes = 'journal_personnel_notes';

  List<NoteJournal> _notes = const [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getStringList(_cleNotes) ?? [];

    if (!mounted) return;
    setState(() {
      _notes = brut.map(NoteJournal.depuisChaine).whereType<NoteJournal>().toList()
        ..sort((a, b) => b.modifieLe.compareTo(a.modifieLe));
      _chargement = false;
    });
  }

  Future<void> _enregistrer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_cleNotes, _notes.map((n) => n.versChaine()).toList());
  }

  Future<void> _creer() async {
    final note = await _ouvrirEditeur(null);
    if (note == null) return;

    setState(() => _notes.insert(0, note));
    await _enregistrer();
  }

  Future<void> _modifier(NoteJournal note) async {
    final modifiee = await _ouvrirEditeur(note);
    if (modifiee == null) return;

    setState(() {
      final index = _notes.indexWhere((n) => n.id == note.id);
      if (index != -1) _notes[index] = modifiee;
      _notes.sort((a, b) => b.modifieLe.compareTo(a.modifieLe));
    });
    await _enregistrer();
  }

  Future<NoteJournal?> _ouvrirEditeur(NoteJournal? existante) {
    return showModalBottomSheet<NoteJournal>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditeurNote(existante: existante),
    );
  }

  Future<void> _supprimer(NoteJournal note) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette note ?'),
        content: Text('« ${note.titre} » sera définitivement supprimée.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: MabokoCouleurs.danger)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() => _notes.removeWhere((n) => n.id == note.id));
    await _enregistrer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Mon journal personnel'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creer,
        backgroundColor: MabokoCouleurs.secondaire,
        icon: const Icon(Icons.edit_rounded, color: Colors.white),
        label: const Text('Nouvelle note',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _chargement
          ? const ChargementEnCours()
          : _notes.isEmpty
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
          icone: Icons.menu_book_outlined,
          titre: 'Votre journal est vide',
          message: 'Notez ici ce que vous voulez retenir : un artisan à '
              'rappeler, un devis à comparer, l’état d’un chantier. '
              'Ces notes restent sur votre téléphone.',
        ),
      ],
    );
  }

  Widget _liste() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _notes.length + 1,
      itemBuilder: (contexte, i) {
        if (i == 0) return _encadre();

        final note = _notes[i - 1];

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
              onTap: () => _modifier(note),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            note.titre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 20, color: MabokoCouleurs.danger),
                          tooltip: 'Supprimer',
                          onPressed: () => _supprimer(note),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    if (note.contenu.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note.contenu,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.45,
                          color: context.texteSecondaireMaboko,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 13, color: context.texteSecondaireMaboko),
                        const SizedBox(width: 4),
                        Text(
                          _dateLisible(note.modifieLe),
                          style: TextStyle(
                            fontSize: 11.5,
                            color: context.texteSecondaireMaboko,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
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
          const Icon(Icons.lock_outline_rounded, size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Vos notes restent sur votre téléphone. Elles ne sont ni '
              'synchronisées, ni visibles de l’équipe Maboko.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: context.texteSecondaireMaboko),
            ),
          ),
        ],
      ),
    );
  }

  String _dateLisible(DateTime date) {
    final maintenant = DateTime.now();
    final difference = maintenant.difference(date);

    if (difference.inMinutes < 1) return 'à l’instant';
    if (difference.inHours < 1) return 'il y a ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'il y a ${difference.inHours} h';
    if (difference.inDays == 1) return 'hier';
    if (difference.inDays < 7) return 'il y a ${difference.inDays} jours';

    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];

    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Modèle
// ---------------------------------------------------------------------------

/// Note du journal, encodée en `id|titre|contenu|horodatage`.
class NoteJournal {
  const NoteJournal({
    required this.id,
    required this.titre,
    required this.contenu,
    required this.modifieLe,
  });

  final String id;
  final String titre;
  final String contenu;
  final DateTime modifieLe;

  String versChaine() =>
      '$id|${_echapper(titre)}|${_echapper(contenu)}|${modifieLe.millisecondsSinceEpoch}';

  static NoteJournal? depuisChaine(String brut) {
    final morceaux = brut.split('|');
    if (morceaux.length < 4) return null;

    return NoteJournal(
      id: morceaux[0],
      titre: _desechapper(morceaux[1]),
      contenu: _desechapper(morceaux[2]),
      modifieLe: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(morceaux[3]) ?? 0,
      ),
    );
  }

  // Le séparateur `|` ne doit pas apparaître dans le contenu, sinon il casse
  // le découpage. On le remplace par son code ASCII.
  static String _echapper(String texte) => texte.replaceAll('|', '&#124;');
  static String _desechapper(String texte) => texte.replaceAll('&#124;', '|');
}

// ---------------------------------------------------------------------------
// Éditeur de note (feuille du bas)
// ---------------------------------------------------------------------------

class _EditeurNote extends StatefulWidget {
  const _EditeurNote({this.existante});

  final NoteJournal? existante;

  @override
  State<_EditeurNote> createState() => _EditeurNoteState();
}

class _EditeurNoteState extends State<_EditeurNote> {
  final _cleFormulaire = GlobalKey<FormState>();
  late final TextEditingController _titre;
  late final TextEditingController _contenu;

  @override
  void initState() {
    super.initState();
    _titre = TextEditingController(text: widget.existante?.titre ?? '');
    _contenu = TextEditingController(text: widget.existante?.contenu ?? '');
  }

  @override
  void dispose() {
    _titre.dispose();
    _contenu.dispose();
    super.dispose();
  }

  void _valider() {
    if (!_cleFormulaire.currentState!.validate()) return;

    Navigator.pop(
      context,
      NoteJournal(
        id: widget.existante?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        titre: _titre.text.trim(),
        contenu: _contenu.text.trim(),
        modifieLe: DateTime.now(),
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
        child: Form(
          key: _cleFormulaire,
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
                widget.existante == null ? 'Nouvelle note' : 'Modifier la note',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _titre,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 80,
                decoration: _decoration('Titre', Icons.title_rounded),
                validator: (v) => (v ?? '').trim().length < 2
                    ? 'Donnez un titre à votre note.'
                    : null,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _contenu,
                maxLines: 6,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration('Contenu (facultatif)', Icons.notes_rounded),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: FilledButton(
                  onPressed: _valider,
                  style: FilledButton.styleFrom(
                    backgroundColor: MabokoCouleurs.secondaire,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Enregistrer',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String libelle, IconData icone) {
    return InputDecoration(
      labelText: libelle,
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