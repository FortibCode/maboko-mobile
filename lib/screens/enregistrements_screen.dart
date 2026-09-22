import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/maboko_theme.dart';
import '../core/widgets/etats.dart';

/// Mes enregistrements (§5.1.7).
///
/// Le client garde ici ce qu'il veut retrouver plus tard : artisans vus,
/// publications mises de côté, recherches sauvegardées. Trois onglets pour
/// ne pas mélanger les natures.
class EnregistrementsScreen extends StatefulWidget {
  const EnregistrementsScreen({super.key});

  @override
  State<EnregistrementsScreen> createState() => _EnregistrementsScreenState();
}

class _EnregistrementsScreenState extends State<EnregistrementsScreen>
    with SingleTickerProviderStateMixin {
  static const _cleArtisans = 'enregistres_artisans';
  static const _clePublications = 'enregistres_publications';
  static const _cleRecherches = 'enregistres_recherches';

  late final TabController _onglets = TabController(length: 3, vsync: this);

  List<String> _artisans = const [];
  List<String> _publications = const [];
  List<String> _recherches = const [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _onglets.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _artisans = prefs.getStringList(_cleArtisans) ?? [];
      _publications = prefs.getStringList(_clePublications) ?? [];
      _recherches = prefs.getStringList(_cleRecherches) ?? [];
      _chargement = false;
    });
  }

  Future<void> _retirer(String cle, String element) async {
    final prefs = await SharedPreferences.getInstance();
    final liste = prefs.getStringList(cle) ?? [];
    liste.remove(element);
    await prefs.setStringList(cle, liste);

    await _charger();
  }

  Future<void> _vider(String cle, String libelle) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Vider « $libelle » ?'),
        content: const Text('Tous les éléments de cette liste seront retirés. '
            'Cette action est irréversible.'),
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

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(cle);
    await _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Mes enregistrements'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _onglets,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Artisans'),
            Tab(text: 'Publications'),
            Tab(text: 'Recherches'),
          ],
        ),
      ),
      body: _chargement
          ? const ChargementEnCours()
          : TabBarView(
              controller: _onglets,
              children: [
                _liste(
                  elements: _artisans,
                  cle: _cleArtisans,
                  libelle: 'artisans enregistrés',
                  icone: Icons.handyman_outlined,
                  messageVide: 'Enregistrez un artisan depuis sa fiche pour '
                      'le retrouver ici.',
                ),
                _liste(
                  elements: _publications,
                  cle: _clePublications,
                  libelle: 'publications enregistrées',
                  icone: Icons.bookmark_border_rounded,
                  messageVide: 'Enregistrez une publication depuis le fil pour '
                      'la relire plus tard.',
                ),
                _liste(
                  elements: _recherches,
                  cle: _cleRecherches,
                  libelle: 'recherches sauvegardées',
                  icone: Icons.search_rounded,
                  messageVide: 'Sauvegardez une recherche pour la relancer en '
                      'un geste.',
                ),
              ],
            ),
    );
  }

  Widget _liste({
    required List<String> elements,
    required String cle,
    required String libelle,
    required IconData icone,
    required String messageVide,
  }) {
    if (elements.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          EtatVide(icone: icone, titre: 'Aucun $libelle', message: messageVide),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                '${elements.length} élément${elements.length > 1 ? 's' : ''}',
                style: TextStyle(fontSize: 13, color: context.texteSecondaireMaboko),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _vider(cle, libelle),
                icon: const Icon(Icons.delete_sweep_outlined, size: 18),
                label: const Text('Tout vider'),
                style: TextButton.styleFrom(foregroundColor: MabokoCouleurs.danger),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: elements.length,
            itemBuilder: (contexte, i) => _carte(elements[i], cle),
          ),
        ),
      ],
    );
  }

  Widget _carte(String element, String cle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: const Icon(Icons.bookmark_rounded, color: MabokoCouleurs.secondaire, size: 20),
        title: Text(
          element,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close_rounded, size: 20),
          tooltip: 'Retirer',
          onPressed: () => _retirer(cle, element),
        ),
      ),
    );
  }
}