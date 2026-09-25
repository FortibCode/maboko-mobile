import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../core/theme/maboko_theme.dart';
import '../core/widgets/etats.dart';
import '../core/widgets/visionneuse_photo.dart';
import '../features/artisans/ui/artisan_profile_screen.dart';
import '../features/fil/data/fil_repository.dart';
import '../features/fil/models/publication.dart';

/// Musée du savoir-faire (§5.1.7).
///
/// Galerie des plus belles réalisations des artisans Maboko : photos,
/// filtres par métier, et accès direct à la fiche de chaque artisan.
///
/// Sert d'inspiration avant de contacter un artisan — là où le fil
/// d'actualité raconte le quotidien, le musée expose le travail abouti.
class MuseeSavoirFaireScreen extends StatefulWidget {
  const MuseeSavoirFaireScreen({super.key});

  @override
  State<MuseeSavoirFaireScreen> createState() => _MuseeSavoirFaireScreenState();
}

class _MuseeSavoirFaireScreenState extends State<MuseeSavoirFaireScreen> {
  static const _filDepot = FilRepository();

  List<Publication>? _publications;
  String? _filtreMetier;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      final publications = await _filDepot.publications();
      if (!mounted) return;
      setState(() => _publications = publications);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    }
  }

  /// Toutes les publications avec au moins un média (photo).
  List<Publication> get _avecPhoto =>
      (_publications ?? []).where((p) => p.medias.isNotEmpty).toList();

  /// Métiers uniques présents dans les publications.
  List<String> get _metiersDisponibles {
    final set = <String>{};
    for (final p in _avecPhoto) {
      final m = p.auteur.metier;
      if (m != null && m.trim().isNotEmpty) set.add(m.trim());
    }
    final liste = set.toList()..sort();
    return liste;
  }

  List<Publication> get _publicationsFiltrees {
    final toutes = _avecPhoto;
    if (_filtreMetier == null) return toutes;
    return toutes.where((p) => p.auteur.metier == _filtreMetier).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Musée du savoir-faire'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: MabokoCouleurs.secondaire,
        onRefresh: _charger,
        child: _corps(),
      ),
    );
  }

  Widget _corps() {
    if (_erreur != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          EtatErreur(message: _erreur!, onReessayer: _charger),
        ],
      );
    }

    if (_publications == null) return const ChargementEnCours();

    if (_avecPhoto.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 60),
          EtatVide(
            icone: Icons.museum_outlined,
            titre: 'Aucune œuvre à exposer',
            message: 'Les réalisations des artisans apparaîtront ici '
                'au fur et à mesure de leurs publications.',
          ),
        ],
      );
    }

    final filtrees = _publicationsFiltrees;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _encadre(),
        const SizedBox(height: 18),
        _filtresMetiers(),
        const SizedBox(height: 18),
        if (filtrees.isEmpty) _aucunResultat() else _grille(filtrees),
      ],
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
          const Icon(Icons.museum_outlined,
              size: 22, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Les plus belles réalisations des artisans Maboko. '
              'Touchez une photo pour l’agrandir, ou l’artisan pour voir sa fiche.',
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

  Widget _filtresMetiers() {
    final metiers = _metiersDisponibles;
    if (metiers.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _puceMetier(null, 'Tout'),
          ...metiers.map((m) => _puceMetier(m, m)),
        ],
      ),
    );
  }

  Widget _puceMetier(String? valeur, String libelle) {
    final actif = _filtreMetier == valeur;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(libelle),
        selected: actif,
        showCheckmark: false,
        onSelected: (_) => setState(() => _filtreMetier = valeur),
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

  Widget _aucunResultat() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: EtatVide(
        icone: Icons.search_off_rounded,
        titre: 'Aucune œuvre dans ce métier',
        message: 'Essayez un autre filtre ou revenez plus tard.',
      ),
    );
  }

  Widget _grille(List<Publication> publications) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: publications.length,
      itemBuilder: (contexte, i) => _carte(publications[i]),
    );
  }

  Widget _carte(Publication publication) {
    final photo = publication.premierMedia;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // Tap sur la carte : ouvre la visionneuse de photos.
        onTap: photo == null
            ? null
            : () => VisionneusePhoto.ouvrir(
                  context,
                  urls: publication.medias,
                  legende: publication.description,
                ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: photo == null
                  ? Container(
                      color: context.bordureMaboko,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        publication.description,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    )
                  : Image.network(
                      photo,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    publication.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // L'auteur est cliquable : ouvre sa fiche artisan.
                  GestureDetector(
                    onTap: () => _ouvrirFiche(publication),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundColor: context.bordureMaboko,
                          backgroundImage: publication.auteur.avatarUrl != null &&
                                  publication.auteur.avatarUrl!.isNotEmpty
                              ? NetworkImage(publication.auteur.avatarUrl!)
                              : null,
                          child: publication.auteur.avatarUrl == null ||
                                  publication.auteur.avatarUrl!.isEmpty
                              ? const Icon(Icons.person,
                                  size: 11, color: MabokoCouleurs.secondaire)
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            publication.auteur.nomComplet,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: MabokoCouleurs.secondaire,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirFiche(Publication publication) {
    final artisanId = publication.auteur.id;
    if (artisanId <= 0) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanProfileScreen(artisanId: artisanId),
      ),
    );
  }
}