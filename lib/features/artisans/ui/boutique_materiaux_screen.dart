import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';

/// Boutique matériaux (§5.1.7 et §5.2).
///
/// Annuaire local des commerces de matériaux : quincailleries, dépôts de
/// bois, magasins de peinture. L'utilisateur cherche par nom, spécialité
/// ou quartier, puis appelle ou écrit en un geste.
///
/// Même écran côté client et côté artisan : les deux cherchent les mêmes
/// commerces pour les mêmes raisons.
class BoutiqueMateriauxScreen extends StatefulWidget {
  const BoutiqueMateriauxScreen({super.key});

  @override
  State<BoutiqueMateriauxScreen> createState() => _BoutiqueMateriauxScreenState();
}

class _BoutiqueMateriauxScreenState extends State<BoutiqueMateriauxScreen> {
  static const _cleBoutiques = 'boutiques_materiaux_locales';

  List<Boutique> _boutiques = const [];
  String? _recherche;
  String? _filtreCategorie;
  bool _chargement = true;

  /// Catégories proposées en filtre rapide.
  static const _categories = [
    'Bois & menuiserie',
    'Quincaillerie',
    'Peinture',
    'Plomberie',
    'Électricité',
    'Maçonnerie',
    'Toiture',
  ];

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getStringList(_cleBoutiques) ?? [];

    final liste = <Boutique>[];
    for (final element in brut) {
      final b = Boutique.depuisChaine(element);
      if (b != null) liste.add(b);
    }
    liste.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));

    if (!mounted) return;
    setState(() {
      _boutiques = liste;
      _chargement = false;
    });
  }

  Future<void> _enregistrer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cleBoutiques,
      _boutiques.map((b) => b.versChaine()).toList(),
    );
  }

  Future<void> _ajouter() async {
    final b = await showModalBottomSheet<Boutique>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _EditeurBoutique(),
    );

    if (b == null) return;

    setState(() {
      _boutiques = [..._boutiques, b]
        ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
    });
    await _enregistrer();
  }

  Future<void> _modifier(Boutique boutique) async {
    final modifiee = await showModalBottomSheet<Boutique>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditeurBoutique(existant: boutique),
    );

    if (modifiee == null) return;

    setState(() {
      final i = _boutiques.indexWhere((b) => b.id == boutique.id);
      if (i != -1) _boutiques[i] = modifiee;
      _boutiques.sort(
          (a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
    });
    await _enregistrer();
  }

  Future<void> _supprimer(Boutique boutique) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Retirer cette boutique ?'),
        content: Text('« ${boutique.nom} » sera retirée de la liste.'),
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
        _boutiques = _boutiques.where((b) => b.id != boutique.id).toList());
    await _enregistrer();
  }

  Future<void> _appeler(Boutique b) async {
    final uri = Uri(scheme: 'tel', path: b.telephone);
    if (!await launchUrl(uri)) {
      if (!mounted) return;
      _informer('Impossible de lancer l’appel.', MabokoCouleurs.danger);
    }
  }

  Future<void> _whatsapp(Boutique b) async {
    final numero = b.telephone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$numero');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      _informer('Impossible d’ouvrir WhatsApp.', MabokoCouleurs.danger);
    }
  }

  Future<void> _itineraire(Boutique b) async {
    if (b.latitude == null || b.longitude == null) {
      _informer('Position GPS non renseignée.', MabokoCouleurs.accent);
      return;
    }

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${b.latitude},${b.longitude}',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      _informer('Impossible d’ouvrir le plan.', MabokoCouleurs.danger);
    }
  }

  void _informer(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: couleur),
    );
  }

  List<Boutique> get _boutiquesFiltrees {
    var liste = _boutiques;

    if (_filtreCategorie != null) {
      liste = liste.where((b) => b.categorie == _filtreCategorie).toList();
    }

    final q = _recherche?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      liste = liste.where((b) {
        return b.nom.toLowerCase().contains(q) ||
            (b.quartier?.toLowerCase().contains(q) ?? false) ||
            (b.notes?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return liste;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Boutique matériaux'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        backgroundColor: MabokoCouleurs.secondaire,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Ajouter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _chargement
          ? const ChargementEnCours()
          : _boutiques.isEmpty
              ? _vide()
              : Column(
                  children: [
                    _barreRecherche(),
                    _filtresCategories(),
                    Expanded(child: _liste()),
                  ],
                ),
    );
  }

  Widget _barreRecherche() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: TextField(
        onChanged: (v) => setState(() => _recherche = v),
        decoration: InputDecoration(
          hintText: 'Rechercher une boutique, un quartier...',
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

  Widget _filtresCategories() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _puceCategorie(null, 'Toutes'),
          ..._categories.map((c) => _puceCategorie(c, c)),
        ],
      ),
    );
  }

  Widget _puceCategorie(String? valeur, String libelle) {
    final actif = _filtreCategorie == valeur;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: FilterChip(
        label: Text(libelle),
        selected: actif,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filtreCategorie = valeur),
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
          icone: Icons.storefront_outlined,
          titre: 'Aucune boutique enregistrée',
          message: 'Ajoutez les commerces de matériaux où vous vous '
              'approvisionnez : quincaillerie, dépôt de bois, peinture. '
              'Vous les aurez sous la main.',
        ),
      ],
    );
  }

  Widget _liste() {
    final liste = _boutiquesFiltrees;

    if (liste.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 40),
          EtatVide(
            icone: Icons.search_off_rounded,
            titre: 'Aucun résultat',
            message: _filtreCategorie != null
                ? 'Aucune boutique dans « $_filtreCategorie ».'
                : 'Aucune boutique ne correspond à votre recherche.',
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

  Widget _carte(Boutique b) {
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
          onTap: () => _modifier(b),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            MabokoCouleurs.secondaire.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _iconeCategorie(b.categorie),
                        color: MabokoCouleurs.secondaire,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            b.nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          if (b.categorie != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                b.categorie!,
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
                      tooltip: 'Retirer',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _supprimer(b),
                    ),
                  ],
                ),
                if (b.quartier != null && b.quartier!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 14, color: context.texteSecondaireMaboko),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          b.quartier!,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.texteSecondaireMaboko,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (b.notes != null && b.notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    b.notes!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: context.texteSecondaireMaboko,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _appeler(b),
                        icon: const Icon(Icons.phone_rounded, size: 15),
                        label: const Text('Appeler',
                            style: TextStyle(fontSize: 12.5)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MabokoCouleurs.secondaire,
                          side: BorderSide(color: context.bordureMaboko),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _whatsapp(b),
                        icon: const Icon(Icons.chat_bubble_outline_rounded,
                            size: 15),
                        label: const Text('WhatsApp',
                            style: TextStyle(fontSize: 12.5)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF25D366),
                          side: const BorderSide(color: Color(0xFF25D366)),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _itineraire(b),
                        icon: const Icon(Icons.map_outlined, size: 15),
                        label: const Text('Plan',
                            style: TextStyle(fontSize: 12.5)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: MabokoCouleurs.accent,
                          side: const BorderSide(color: MabokoCouleurs.accent),
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
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
              'Vos adresses de matériaux au même endroit. Appelez pour '
              'vérifier le stock, écrivez sur WhatsApp, ou ouvrez le plan.',
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

  IconData _iconeCategorie(String? categorie) {
    return switch (categorie) {
      'Bois & menuiserie' => Icons.carpenter_outlined,
      'Quincaillerie' => Icons.hardware_outlined,
      'Peinture' => Icons.format_paint_outlined,
      'Plomberie' => Icons.plumbing_outlined,
      'Électricité' => Icons.electrical_services_outlined,
      'Maçonnerie' => Icons.foundation_outlined,
      'Toiture' => Icons.roofing_outlined,
      _ => Icons.storefront_outlined,
    };
  }
}

// ---------------------------------------------------------------------------
// Modèle
// ---------------------------------------------------------------------------

/// Boutique encodée en `id|nom|telephone|categorie|quartier|notes|lat|lng`.
class Boutique {
  const Boutique({
    required this.id,
    required this.nom,
    required this.telephone,
    this.categorie,
    this.quartier,
    this.notes,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String nom;
  final String telephone;
  final String? categorie;
  final String? quartier;
  final String? notes;
  final double? latitude;
  final double? longitude;

  String versChaine() {
    String s(String? v) => (v ?? '').replaceAll('|', '&#124;');
    return '$id|${s(nom)}|${s(telephone)}|${s(categorie)}|${s(quartier)}|${s(notes)}|${latitude ?? ''}|${longitude ?? ''}';
  }

  static Boutique? depuisChaine(String brut) {
    final m = brut.split('|');
    if (m.length < 8) return null;

    String d(String s) => s.replaceAll('&#124;', '|');

    return Boutique(
      id: m[0],
      nom: d(m[1]),
      telephone: d(m[2]),
      categorie: m[3].isEmpty ? null : d(m[3]),
      quartier: m[4].isEmpty ? null : d(m[4]),
      notes: m[5].isEmpty ? null : d(m[5]),
      latitude: m[6].isEmpty ? null : double.tryParse(m[6]),
      longitude: m[7].isEmpty ? null : double.tryParse(m[7]),
    );
  }
}

// ---------------------------------------------------------------------------
// Éditeur
// ---------------------------------------------------------------------------

class _EditeurBoutique extends StatefulWidget {
  const _EditeurBoutique({this.existant});

  final Boutique? existant;

  @override
  State<_EditeurBoutique> createState() => _EditeurBoutiqueState();
}

class _EditeurBoutiqueState extends State<_EditeurBoutique> {
  late final TextEditingController _nom;
  late final TextEditingController _tel;
  late final TextEditingController _quartier;
  late final TextEditingController _notes;

  String? _categorie;

  static const _categories = [
    'Bois & menuiserie',
    'Quincaillerie',
    'Peinture',
    'Plomberie',
    'Électricité',
    'Maçonnerie',
    'Toiture',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existant;
    _nom = TextEditingController(text: e?.nom ?? '');
    _tel = TextEditingController(text: e?.telephone ?? '');
    _quartier = TextEditingController(text: e?.quartier ?? '');
    _notes = TextEditingController(text: e?.notes ?? '');
    _categorie = e?.categorie;
  }

  @override
  void dispose() {
    _nom.dispose();
    _tel.dispose();
    _quartier.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _valider() {
    if (_nom.text.trim().isEmpty) {
      _info('Indiquez le nom de la boutique.');
      return;
    }
    if (_tel.text.trim().length < 6) {
      _info('Indiquez un numéro de téléphone valide.');
      return;
    }

    Navigator.pop(
      context,
      Boutique(
        id: widget.existant?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        nom: _nom.text.trim(),
        telephone: _tel.text.trim(),
        categorie: _categorie,
        quartier:
            _quartier.text.trim().isEmpty ? null : _quartier.text.trim(),
        notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        latitude: widget.existant?.latitude,
        longitude: widget.existant?.longitude,
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
                    ? 'Nouvelle boutique'
                    : 'Modifier la boutique',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _nom,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Nom', Icons.storefront_outlined,
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
              DropdownButtonFormField<String>(
                initialValue: _categorie,
                decoration: _dec('Catégorie (facultatif)',
                    Icons.category_outlined),
                items: [
                  const DropdownMenuItem(value: null, child: Text('—')),
                  ..._categories.map(
                    (c) => DropdownMenuItem(value: c, child: Text(c)),
                  ),
                ],
                onChanged: (v) => setState(() => _categorie = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quartier,
                textCapitalization: TextCapitalization.words,
                decoration: _dec('Quartier (facultatif)', Icons.place_outlined,
                    indice: 'Ex. : Bacongo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: _dec('Notes (facultatif)', Icons.notes_rounded,
                    indice: 'Horaires, contact, spécialités...'),
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