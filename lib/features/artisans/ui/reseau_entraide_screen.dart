import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';

/// Réseau d'entraide (§5.2).
///
/// Les artisans s'organisent entre eux : demander un coup de main sur un
/// chantier, prêter du matériel, partager un bon fournisseur. Ce sont des
/// petites annonces locales, utiles au quotidien.
class ReseauEntraideScreen extends StatefulWidget {
  const ReseauEntraideScreen({super.key});

  @override
  State<ReseauEntraideScreen> createState() => _ReseauEntraideScreenState();
}

class _ReseauEntraideScreenState extends State<ReseauEntraideScreen> {
  static const _cleAnnonces = 'reseau_entraide_annonces';

  List<Annonce> _annonces = const [];
  String? _filtreType;
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getStringList(_cleAnnonces) ?? [];

    final liste = <Annonce>[];
    for (final element in brut) {
      final a = Annonce.depuisChaine(element);
      if (a != null) liste.add(a);
    }
    liste.sort((a, b) => b.publieLe.compareTo(a.publieLe));

    if (!mounted) return;
    setState(() {
      _annonces = liste;
      _chargement = false;
    });
  }

  Future<void> _enregistrer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cleAnnonces,
      _annonces.map((a) => a.versChaine()).toList(),
    );
  }

  Future<void> _publier() async {
    final annonce = await showModalBottomSheet<Annonce>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditeurAnnonce(),
    );

    if (annonce == null) return;

    setState(() => _annonces = [annonce, ..._annonces]);
    await _enregistrer();
  }

  Future<void> _supprimer(Annonce annonce) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Retirer cette annonce ?'),
        content: Text('« ${annonce.titre} » sera retirée du réseau.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Retirer',
              style: TextStyle(color: MabokoCouleurs.danger),
            ),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() =>
        _annonces = _annonces.where((a) => a.id != annonce.id).toList());
    await _enregistrer();
  }

  List<Annonce> get _annoncesFiltrees {
    if (_filtreType == null) return _annonces;
    return _annonces.where((a) => a.type.name == _filtreType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Réseau d’entraide'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _publier,
        backgroundColor: MabokoCouleurs.secondaire,
        icon: const Icon(Icons.campaign_rounded, color: Colors.white),
        label: const Text(
          'Publier',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _chargement
          ? const ChargementEnCours()
          : _annonces.isEmpty
              ? _vide()
              : Column(
                  children: [
                    _filtres(),
                    Expanded(child: _liste()),
                  ],
                ),
    );
  }

  Widget _filtres() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _puceType(null, 'Toutes'),
          ...TypeAnnonce.values.map((t) => _puceType(t.name, '${t.emoji} ${t.libelle}')),
        ],
      ),
    );
  }

  Widget _puceType(String? valeur, String libelle) {
    final actif = _filtreType == valeur;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: FilterChip(
        label: Text(libelle),
        selected: actif,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filtreType = valeur),
        backgroundColor: context.surfaceMaboko,
        selectedColor: MabokoCouleurs.secondaire.withValues(alpha: 0.15),
        side: BorderSide(
          color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko,
        ),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
          color: actif ? MabokoCouleurs.secondaire : context.texteFortMaboko,
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
          icone: Icons.groups_outlined,
          titre: 'Aucune annonce',
          message: 'Publiez une demande de coup de main, proposez du matériel '
              'à prêter, ou partagez un bon fournisseur.',
        ),
      ],
    );
  }

  Widget _liste() {
    final liste = _annoncesFiltrees;

    if (liste.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 40),
          EtatVide(
            icone: Icons.search_off_rounded,
            titre: 'Aucune annonce dans cette catégorie',
            message: 'Essayez un autre filtre ou publiez une annonce.',
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

  Widget _carte(Annonce a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: a.type.couleur.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(a.type.emoji, style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        a.type.libelle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: a.type.couleur,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Retirer',
                  onPressed: () => _supprimer(a),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              a.titre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (a.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                a.description,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: context.texteSecondaireMaboko,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.person_outline_rounded,
                    size: 13, color: context.texteSecondaireMaboko),
                const SizedBox(width: 4),
                Text(
                  a.auteur,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.texteSecondaireMaboko,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (a.quartier != null && a.quartier!.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Icon(Icons.place_outlined,
                      size: 13, color: context.texteSecondaireMaboko),
                  const SizedBox(width: 4),
                  Text(
                    a.quartier!,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.texteSecondaireMaboko,
                    ),
                  ),
                ],
                const Spacer(),
                Text(
                  _dateLisible(a.publieLe),
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
          const Icon(Icons.handshake_outlined,
              size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Le réseau d’entraide, c’est vous. Demandez un coup de main, '
              'prêtez votre matériel, partagez une bonne adresse.',
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

enum TypeAnnonce {
  coupDeMain('Coup de main', '🤝', Color(0xFF2A6FB0)),
  pretMateriel('Prêt de matériel', '🔧', Color(0xFF6A4CA8)),
  bonPlan('Bon plan', '💡', Color(0xFFE08B14)),
  echange('Échange', '🔄', Color(0xFF2E7D32));

  const TypeAnnonce(this.libelle, this.emoji, this.couleur);

  final String libelle;
  final String emoji;
  final Color couleur;
}

/// Annonce encodée en `id|type|titre|description|auteur|quartier|horodatage`.
class Annonce {
  const Annonce({
    required this.id,
    required this.type,
    required this.titre,
    required this.description,
    required this.auteur,
    required this.publieLe,
    this.quartier,
  });

  final String id;
  final TypeAnnonce type;
  final String titre;
  final String description;
  final String auteur;
  final String? quartier;
  final DateTime publieLe;

  String versChaine() {
    String s(String v) => v.replaceAll('|', '&#124;');
    return '$id|${type.name}|${s(titre)}|${s(description)}|${s(auteur)}|${s(quartier ?? '')}|${publieLe.millisecondsSinceEpoch}';
  }

  static Annonce? depuisChaine(String brut) {
    final m = brut.split('|');
    if (m.length < 7) return null;

    String d(String s) => s.replaceAll('&#124;', '|');

    final type = TypeAnnonce.values.firstWhere(
      (t) => t.name == m[1],
      orElse: () => TypeAnnonce.coupDeMain,
    );

    return Annonce(
      id: m[0],
      type: type,
      titre: d(m[2]),
      description: d(m[3]),
      auteur: d(m[4]),
      quartier: m[5].isEmpty ? null : d(m[5]),
      publieLe: DateTime.fromMillisecondsSinceEpoch(int.tryParse(m[6]) ?? 0),
    );
  }
}

// ---------------------------------------------------------------------------
// Éditeur
// ---------------------------------------------------------------------------

class _EditeurAnnonce extends StatefulWidget {
  const _EditeurAnnonce();

  @override
  State<_EditeurAnnonce> createState() => _EditeurAnnonceState();
}

class _EditeurAnnonceState extends State<_EditeurAnnonce> {
  final _titre = TextEditingController();
  final _description = TextEditingController();
  final _auteur = TextEditingController();
  final _quartier = TextEditingController();

  TypeAnnonce _type = TypeAnnonce.coupDeMain;

  @override
  void dispose() {
    _titre.dispose();
    _description.dispose();
    _auteur.dispose();
    _quartier.dispose();
    super.dispose();
  }

  void _valider() {
    if (_titre.text.trim().isEmpty) {
      _info('Donnez un titre à votre annonce.');
      return;
    }
    if (_auteur.text.trim().isEmpty) {
      _info('Indiquez votre nom pour qu’on puisse vous répondre.');
      return;
    }

    Navigator.pop(
      context,
      Annonce(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        type: _type,
        titre: _titre.text.trim(),
        description: _description.text.trim(),
        auteur: _auteur.text.trim(),
        quartier: _quartier.text.trim().isEmpty ? null : _quartier.text.trim(),
        publieLe: DateTime.now(),
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
              const Text(
                'Publier une annonce',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TypeAnnonce.values.map((t) {
                  final actif = _type == t;
                  return FilterChip(
                    label: Text('${t.emoji} ${t.libelle}'),
                    selected: actif,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _type = t),
                    backgroundColor: context.surfaceMaboko,
                    selectedColor: t.couleur.withValues(alpha: 0.18),
                    side: BorderSide(
                      color: actif ? t.couleur : context.bordureMaboko,
                      width: actif ? 1.5 : 1,
                    ),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: actif ? FontWeight.bold : FontWeight.normal,
                      color: actif ? t.couleur : context.texteFortMaboko,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _titre,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Titre', Icons.title_rounded,
                    indice: 'Ex. : Cherche aide électricien samedi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Description', Icons.notes_rounded,
                    indice: 'Détaillez votre demande, les conditions, le lieu...'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _auteur,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Votre nom', Icons.person_outline_rounded),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quartier,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Quartier (facultatif)', Icons.place_outlined,
                    indice: 'Ex. : Bacongo'),
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
                  child: const Text('Publier',
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