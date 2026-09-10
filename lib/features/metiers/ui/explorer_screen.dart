import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../../artisans/ui/artisans_par_metier_screen.dart';
import '../data/metier_repository.dart';
import '../models/metier.dart';
import 'visuel_metier.dart';

/// Écran « Explorer les métiers » (§5.1.5).
///
/// Remplace le libellé « Page Découvrir » : vue d'ensemble de l'intégralité
/// des métiers disponibles, avec une barre de recherche.
class ExplorerScreen extends StatefulWidget {
  const ExplorerScreen({super.key});

  @override
  State<ExplorerScreen> createState() => _ExplorerScreenState();
}

class _ExplorerScreenState extends State<ExplorerScreen> {
  static const _repository = MetierRepository();

  final TextEditingController _recherche = TextEditingController();

  List<Metier> _metiers = const [];

  /// Cinq métiers par page : la grille reste lisible et chaque carte garde
  /// assez de place, au lieu d'une liste interminable qu'on parcourt sans
  /// rien retenir.
  static const _parPage = 5;
  int _page = 1;
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final metiers = await _repository.lister();
      if (!mounted) return;
      setState(() {
        _metiers = metiers;
        _chargement = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    }
  }

  /// Le référentiel tient en mémoire : le filtre est appliqué localement,
  /// ce qui évite un aller-retour réseau à chaque frappe.
  List<Metier> get _resultats {
    final terme = _recherche.text.trim().toLowerCase();
    if (terme.isEmpty) return _metiers;

    return _metiers.where((m) => m.nom.toLowerCase().contains(terme)).toList();
  }

  int get _nbPages => (_resultats.length / _parPage).ceil().clamp(1, 9999);

  List<Metier> get _pageCourante {
    final debut = (_page - 1) * _parPage;
    if (debut >= _resultats.length) return const [];

    return _resultats.sublist(debut, (debut + _parPage).clamp(0, _resultats.length));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Explorer les métiers',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Trouvez le bon artisan, près de chez vous',
                style: TextStyle(color: context.texteSecondaireMaboko, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _recherche,
                onChanged: (_) => setState(() => _page = 1),
                decoration: InputDecoration(
                  hintText: 'Rechercher un métier…',
                  prefixIcon: const Icon(Icons.search, color: MabokoCouleurs.secondaire),
                  suffixIcon: _recherche.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(_recherche.clear),
                        ),
                  filled: true,
                  fillColor: context.surfaceMaboko,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _corps()),
      ],
    );
  }

  Widget _corps() {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null) {
      return EtatErreur(message: _erreur!, onReessayer: _charger);
    }

    final resultats = _resultats;

    if (resultats.isEmpty) {
      return EtatVide(
        icone: Icons.search_off_rounded,
        titre: 'Aucun métier trouvé',
        message: _recherche.text.isEmpty
            ? 'Le référentiel est vide pour le moment.'
            : 'Aucun métier ne correspond à « ${_recherche.text.trim()} ».',
      );
    }

    return RefreshIndicator(
      color: MabokoCouleurs.secondaire,
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
            ),
            itemCount: _pageCourante.length,
            itemBuilder: (context, index) => _CarteMetier(metier: _pageCourante[index]),
          ),
          if (_nbPages > 1) ...[
            const SizedBox(height: 20),
            _pagination(resultats.length),
          ],
        ],
      ),
    );
  }

  Widget _pagination(int total) {
    final debut = (_page - 1) * _parPage + 1;
    final fin = (debut + _pageCourante.length - 1).clamp(debut, total);

    return Column(
      children: [
        Text(
          '$debut–$fin sur $total métiers',
          style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _boutonPage(
              Icons.chevron_left_rounded,
              _page > 1 ? () => setState(() => _page--) : null,
            ),
            const SizedBox(width: 6),
            for (var n = 1; n <= _nbPages; n++) ...[
              _numeroPage(n),
              const SizedBox(width: 6),
            ],
            _boutonPage(
              Icons.chevron_right_rounded,
              _page < _nbPages ? () => setState(() => _page++) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _numeroPage(int n) {
    final actif = n == _page;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: actif ? null : () => setState(() => _page = n),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: actif ? MabokoCouleurs.secondaire : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko,
          ),
        ),
        child: Text(
          '$n',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: actif ? Colors.white : context.texteSecondaireMaboko,
          ),
        ),
      ),
    );
  }

  Widget _boutonPage(IconData icone, VoidCallback? action) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: action,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: context.bordureMaboko),
        ),
        child: Icon(
          icone,
          size: 20,
          color: action == null ? context.bordureMaboko : MabokoCouleurs.secondaire,
        ),
      ),
    );
  }

}

class _CarteMetier extends StatelessWidget {
  const _CarteMetier({required this.metier});

  final Metier metier;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArtisansParMetierScreen(
              slugMetier: metier.slug,
              titre: metier.nom,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.bordureMaboko),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VisuelMetier(metier: metier, taille: 46, rayon: 12, tailleIcone: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metier.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metier.nbArtisans == 0
                        ? 'Aucun artisan inscrit'
                        : '${metier.nbArtisans} artisan${metier.nbArtisans > 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 11.5, color: context.texteSecondaireMaboko),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
