import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';

/// Caisse à outils — fournisseurs (§5.2).
///
/// L'artisan garde ici ses fournisseurs de matériaux : nom, contact,
/// spécialité, adresse. Utile pour commander rapidement sans chercher un
/// numéro dans son téléphone.
class CaisseAOutilsScreen extends StatefulWidget {
  const CaisseAOutilsScreen({super.key});

  @override
  State<CaisseAOutilsScreen> createState() => _CaisseAOutilsScreenState();
}

class _CaisseAOutilsScreenState extends State<CaisseAOutilsScreen> {
  static const _cleFournisseurs = 'artisan_fournisseurs';

  List<Fournisseur> _fournisseurs = const [];
  String? _recherche;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getStringList(_cleFournisseurs) ?? [];

    final liste = <Fournisseur>[];
    for (final element in brut) {
      final f = Fournisseur.depuisChaine(element);
      if (f != null) liste.add(f);
    }
    liste.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));

    if (!mounted) return;
    setState(() {
      _fournisseurs = liste;
      _chargement = false;
    });
  }

  Future<void> _enregistrer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cleFournisseurs,
      _fournisseurs.map((f) => f.versChaine()).toList(),
    );
  }

  Future<void> _ajouter() async {
    final f = await showModalBottomSheet<Fournisseur>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditeurFournisseur(),
    );

    if (f == null) return;

    setState(() => _fournisseurs = [..._fournisseurs, f]
      ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase())));
    await _enregistrer();
  }

  Future<void> _modifier(Fournisseur fournisseur) async {
    final modifie = await showModalBottomSheet<Fournisseur>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditeurFournisseur(existant: fournisseur),
    );

    if (modifie == null) return;

    setState(() {
      final i = _fournisseurs.indexWhere((f) => f.id == fournisseur.id);
      if (i != -1) _fournisseurs[i] = modifie;
      _fournisseurs.sort(
          (a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
    });
    await _enregistrer();
  }

  Future<void> _supprimer(Fournisseur fournisseur) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce fournisseur ?'),
        content: Text('« ${fournisseur.nom} » sera définitivement retiré.'),
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

    setState(() =>
        _fournisseurs = _fournisseurs.where((f) => f.id != fournisseur.id).toList());
    await _enregistrer();
  }

  Future<void> _appeler(Fournisseur f) async {
    final uri = Uri(scheme: 'tel', path: f.telephone);
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      _informer('Impossible de lancer l’appel.', MabokoCouleurs.danger);
    }
  }

  Future<void> _whatsapp(Fournisseur f) async {
    final numero = f.telephone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$numero');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      _informer('Impossible d’ouvrir WhatsApp.', MabokoCouleurs.danger);
    }
  }

  void _informer(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: couleur),
    );
  }

  List<Fournisseur> get _fournisseursFiltres {
    final q = _recherche?.trim().toLowerCase();
    if (q == null || q.isEmpty) return _fournisseurs;

    return _fournisseurs.where((f) {
      return f.nom.toLowerCase().contains(q) ||
          (f.specialite?.toLowerCase().contains(q) ?? false) ||
          (f.adresse?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Caisse à outils'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        backgroundColor: MabokoCouleurs.secondaire,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Fournisseur',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _chargement
          ? const ChargementEnCours()
          : _fournisseurs.isEmpty
              ? _vide()
              : Column(
                  children: [
                    _barreRecherche(),
                    Expanded(child: _liste()),
                  ],
                ),
    );
  }

  Widget _barreRecherche() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: (v) => setState(() => _recherche = v),
        decoration: InputDecoration(
          hintText: 'Rechercher un fournisseur, une spécialité...',
          prefixIcon: Icon(Icons.search_rounded,
              size: 20, color: context.texteSecondaireMaboko),
          suffixIcon: _recherche?.isNotEmpty == true
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => setState(() => _recherche = null),
                )
              : null,
          filled: true,
          fillColor: context.surfaceMaboko,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.bordureMaboko),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: context.bordureMaboko),
          ),
        ),
      ),
    );
  }

  Widget _vide() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 60),
        EtatVide(
          icone: Icons.construction_outlined,
          titre: 'Aucun fournisseur',
          message: 'Ajoutez vos fournisseurs de matériaux : nom, numéro, '
              'spécialité. Vous les aurez sous la main pour commander.',
        ),
      ],
    );
  }

  Widget _liste() {
    final liste = _fournisseursFiltres;

    if (liste.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          EtatVide(
            icone: Icons.search_off_rounded,
            titre: 'Aucun résultat',
            message: 'Aucun fournisseur ne correspond à « $_recherche ».',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: liste.length + 1,
      itemBuilder: (contexte, i) {
        if (i == 0) return _encadre();
        return _carte(liste[i - 1]);
      },
    );
  }

  Widget _carte(Fournisseur f) {
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
          onTap: () => _modifier(f),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          MabokoCouleurs.secondaire.withValues(alpha: 0.12),
                      child: Text(
                        _initiales(f.nom),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: MabokoCouleurs.secondaire,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (f.specialite != null && f.specialite!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                f.specialite!,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: MabokoCouleurs.secondaire,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          size: 18, color: MabokoCouleurs.danger),
                      tooltip: 'Supprimer',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _supprimer(f),
                    ),
                  ],
                ),
                if (f.adresse != null && f.adresse!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 14, color: context.texteSecondaireMaboko),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          f.adresse!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.texteSecondaireMaboko,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _appeler(f),
                        icon: const Icon(Icons.phone_rounded, size: 16),
                        label: const Text('Appeler',
                            style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MabokoCouleurs.secondaire,
                          side: BorderSide(color: context.bordureMaboko),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _whatsapp(f),
                        icon: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 16),
                        label: const Text('WhatsApp',
                            style: TextStyle(fontSize: 13)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF25D366),
                          side: const BorderSide(color: Color(0xFF25D366)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
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
              'Gardez vos fournisseurs à portée de main. Appelez ou écrivez '
              'sur WhatsApp en un geste, sans chercher dans vos contacts.',
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

  String _initiales(String nom) {
    final p = nom.trim().split(RegExp(r'\s+'));
    if (p.isEmpty) return '?';
    if (p.length == 1) return p.first[0].toUpperCase();
    return '${p.first[0]}${p.last[0]}'.toUpperCase();
  }
}

// ---------------------------------------------------------------------------
// Modèle
// ---------------------------------------------------------------------------

/// Fournisseur encodé en `id|nom|telephone|specialite|adresse|notes`.
class Fournisseur {
  const Fournisseur({
    required this.id,
    required this.nom,
    required this.telephone,
    this.specialite,
    this.adresse,
    this.notes,
  });

  final String id;
  final String nom;
  final String telephone;
  final String? specialite;
  final String? adresse;
  final String? notes;

  String versChaine() {
    String s(String? v) => (v ?? '').replaceAll('|', '&#124;');
    return '$id|${s(nom)}|${s(telephone)}|${s(specialite)}|${s(adresse)}|${s(notes)}';
  }

  static Fournisseur? depuisChaine(String brut) {
    final m = brut.split('|');
    if (m.length < 6) return null;

    String d(String s) => s.replaceAll('&#124;', '|');

    return Fournisseur(
      id: m[0],
      nom: d(m[1]),
      telephone: d(m[2]),
      specialite: m[3].isEmpty ? null : d(m[3]),
      adresse: m[4].isEmpty ? null : d(m[4]),
      notes: m[5].isEmpty ? null : d(m[5]),
    );
  }
}

// ---------------------------------------------------------------------------
// Éditeur
// ---------------------------------------------------------------------------

class _EditeurFournisseur extends StatefulWidget {
  const _EditeurFournisseur({this.existant});

  final Fournisseur? existant;

  @override
  State<_EditeurFournisseur> createState() => _EditeurFournisseurState();
}

class _EditeurFournisseurState extends State<_EditeurFournisseur> {
  late final TextEditingController _nom;
  late final TextEditingController _tel;
  late final TextEditingController _spec;
  late final TextEditingController _adresse;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    final e = widget.existant;
    _nom = TextEditingController(text: e?.nom ?? '');
    _tel = TextEditingController(text: e?.telephone ?? '');
    _spec = TextEditingController(text: e?.specialite ?? '');
    _adresse = TextEditingController(text: e?.adresse ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _nom.dispose();
    _tel.dispose();
    _spec.dispose();
    _adresse.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _valider() {
    if (_nom.text.trim().isEmpty) {
      _info('Indiquez le nom du fournisseur.');
      return;
    }
    if (_tel.text.trim().length < 6) {
      _info('Indiquez un numéro de téléphone valide.');
      return;
    }

    Navigator.pop(
      context,
      Fournisseur(
        id: widget.existant?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        nom: _nom.text.trim(),
        telephone: _tel.text.trim(),
        specialite:
            _spec.text.trim().isEmpty ? null : _spec.text.trim(),
        adresse: _adresse.text.trim().isEmpty ? null : _adresse.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      ),
    );
  }

  void _info(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: MabokoCouleurs.danger),
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
                widget.existant == null
                    ? 'Nouveau fournisseur'
                    : 'Modifier le fournisseur',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nom,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Nom', Icons.store_outlined,
                    indice: 'Ex. : Quincaillerie du Plateau'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tel,
                keyboardType: TextInputType.phone,
                decoration: _dec('Téléphone', Icons.phone_outlined,
                    indice: 'Ex. : +242 06 123 45 67'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _spec,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Spécialité (facultatif)',
                    Icons.category_outlined,
                    indice: 'Ex. : Bois, quincaillerie, peinture'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _adresse,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Adresse (facultatif)', Icons.place_outlined,
                    indice: 'Ex. : avenue de la Paix'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Notes (facultatif)', Icons.notes_rounded,
                    indice: 'Horaires, remises, contact...'),
              ),
              const SizedBox(height: 22),
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

  InputDecoration _dec(String libelle, IconData icone, {String? indice}) {
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