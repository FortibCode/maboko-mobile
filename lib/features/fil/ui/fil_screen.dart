import 'package:flutter/material.dart';

import '../../../core/cache/cache_local.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/fil_repository.dart';
import '../models/publication.dart';
import 'commentaires_sheet.dart';

/// Fil d'actualité (§5.1.4) : stories des artisans suivis, publications de
/// leurs dernières réalisations, likes et commentaires.
///
/// Les deux publications affichées jusqu'ici étaient écrites en dur dans le
/// code source ; tout vient désormais de l'API.
class FilScreen extends StatefulWidget {
  const FilScreen({super.key, this.enTete});

  /// Bandeau optionnel affiché au-dessus du fil (logo, recherche).
  final Widget? enTete;

  @override
  State<FilScreen> createState() => _FilScreenState();
}

class _FilScreenState extends State<FilScreen> {
  static const _repository = FilRepository();

  static const _cleCache = 'fil';

  List<Publication> _publications = const [];
  List<StoryItem> _stories = const [];
  bool _chargement = true;
  String? _erreur;

  /// Renseignée lorsque le contenu affiché vient du cache : l'utilisateur
  /// doit savoir qu'il ne regarde pas l'état actuel.
  DateTime? _horsLigneDepuis;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      // Les deux appels partent ensemble : le fil ne doit pas attendre
      // les stories pour s'afficher.
      final resultats = await Future.wait([
        _repository.publications(),
        _repository.stories(),
      ]);

      if (!mounted) return;

      final publications = resultats[0] as List<Publication>;

      setState(() {
        _publications = publications;
        _stories = resultats[1] as List<StoryItem>;
        _chargement = false;
        _horsLigneDepuis = null;
      });

      await _mettreEnCache(publications);
    } on ApiException catch (e) {
      if (!mounted) return;

      // Réseau indisponible : plutôt qu'une page d'erreur, on montre le
      // dernier fil connu en le signalant (§7.2).
      final secours = await _lireCache();

      if (!mounted) return;

      setState(() {
        if (secours != null && _publications.isEmpty) {
          _publications = secours.publications;
          _horsLigneDepuis = secours.date;
          _erreur = null;
        } else {
          _erreur = e.message;
        }
        _chargement = false;
      });
    }
  }

  Future<void> _mettreEnCache(List<Publication> publications) async {
    await CacheLocal.ecrire(
      _cleCache,
      publications
          .map((p) => {
                'id': p.id,
                'auteur': {
                  'id': p.auteur.id,
                  'nomComplet': p.auteur.nomComplet,
                  'avatarUrl': p.auteur.avatarUrl,
                  'metier': p.auteur.metier,
                },
                'medias': p.medias,
                'description': p.description,
                'likesCount': p.likesCount,
                'commentsCount': p.commentsCount,
                'isLiked': p.isLiked,
                'publieLe': p.publieLe?.toIso8601String(),
              })
          .toList(),
    );
  }

  Future<({List<Publication> publications, DateTime date})?> _lireCache() async {
    final entree = await CacheLocal.lire(_cleCache);

    if (entree == null || entree.contenu is! List) return null;

    final publications = (entree.contenu as List)
        .map((p) => Publication.depuisJson(p as Map<String, dynamic>))
        .toList();

    return publications.isEmpty ? null : (publications: publications, date: entree.enregistreLe);
  }

  /// Le like s'applique tout de suite à l'écran, puis se confirme au serveur.
  /// En cas d'échec, l'affichage revient à son état précédent.
  Future<void> _basculerLike(Publication publication) async {
    final avant = (aime: publication.isLiked, compteur: publication.likesCount);

    setState(() {
      publication.isLiked = !avant.aime;
      publication.likesCount += avant.aime ? -1 : 1;
    });

    try {
      final resultat = await _repository.basculerLike(publication.id);
      if (!mounted) return;
      setState(() {
        publication.isLiked = resultat.aime;
        publication.likesCount = resultat.likesCount;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        publication.isLiked = avant.aime;
        publication.likesCount = avant.compteur;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

  Future<void> _ouvrirCommentaires(Publication publication) async {
    final ajoutes = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentairesSheet(publication: publication),
    );

    if (ajoutes != null && ajoutes > 0 && mounted) {
      setState(() => publication.commentsCount += ajoutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null && _publications.isEmpty) {
      return EtatErreur(message: _erreur!, onReessayer: _charger);
    }

    return RefreshIndicator(
      color: MabokoCouleurs.secondaire,
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          if (widget.enTete != null) widget.enTete!,
          if (_horsLigneDepuis != null) _bandeauHorsLigne(),
          if (_stories.isNotEmpty) _bandeauStories(),
          const Divider(height: 20, thickness: 0.5),
          if (_publications.isEmpty)
            const SizedBox(
              height: 320,
              child: EtatVide(
                icone: Icons.photo_library_outlined,
                titre: 'Le fil est encore vide',
                message: 'Suivez des artisans pour voir leurs réalisations '
                    'apparaître ici dès qu’ils publient.',
              ),
            )
          else
            ..._publications.map(_cartePublication),
        ],
      ),
    );
  }

  /// Signale que le contenu affiché n'est pas à jour.
  Widget _bandeauHorsLigne() {
    final ecart = DateTime.now().difference(_horsLigneDepuis!);
    final quand = ecart.inMinutes < 60
        ? 'il y a ${ecart.inMinutes} min'
        : 'il y a ${ecart.inHours} h';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: MabokoCouleurs.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded, size: 18, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hors connexion — fil enregistré $quand.',
              style: TextStyle(fontSize: 12.5, color: context.texteFortMaboko),
            ),
          ),
          TextButton(
            onPressed: _charger,
            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
            child: const Text('Réessayer', style: TextStyle(fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _bandeauStories() {
    return SizedBox(
      height: 96,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _stories.length,
        itemBuilder: (context, i) {
          final story = _stories[i];

          return Container(
            width: 72,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [MabokoCouleurs.accent, MabokoCouleurs.secondaire],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 27,
                    backgroundColor: context.surfaceMaboko,
                    backgroundImage: story.mediaUrl.isNotEmpty ? NetworkImage(story.mediaUrl) : null,
                    child: story.mediaUrl.isEmpty
                        ? const Icon(Icons.person, color: MabokoCouleurs.secondaire)
                        : null,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  story.auteur.nomComplet.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _cartePublication(Publication publication) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              backgroundImage: publication.auteur.avatarUrl?.isNotEmpty == true
                  ? NetworkImage(publication.auteur.avatarUrl!)
                  : null,
              child: publication.auteur.avatarUrl?.isNotEmpty == true
                  ? null
                  : const Icon(Icons.handyman_rounded, color: MabokoCouleurs.secondaire, size: 20),
            ),
            title: Text(
              publication.auteur.nomComplet,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            subtitle: Text(
              publication.auteur.metier ?? '',
              style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko),
            ),
          ),
          if (publication.premierMedia != null)
            _media(publication),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                _actionIcone(
                  icone: publication.isLiked ? Icons.favorite : Icons.favorite_border,
                  couleur: publication.isLiked ? Colors.red : MabokoCouleurs.principale,
                  valeur: publication.likesCount,
                  onTap: () => _basculerLike(publication),
                ),
                const SizedBox(width: 18),
                _actionIcone(
                  icone: Icons.chat_bubble_outline,
                  couleur: MabokoCouleurs.principale,
                  valeur: publication.commentsCount,
                  onTap: () => _ouvrirCommentaires(publication),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 14),
            child: Text(publication.description, style: const TextStyle(fontSize: 14, height: 1.4)),
          ),
        ],
      ),
    );
  }

  Widget _media(Publication publication) {
    if (publication.medias.length == 1) {
      return _image(publication.medias.first);
    }

    // Plusieurs photos : galerie horizontale, avec le rang de chacune.
    return SizedBox(
      height: 320,
      child: PageView.builder(
        itemCount: publication.medias.length,
        itemBuilder: (context, i) => Stack(
          fit: StackFit.expand,
          children: [
            _image(publication.medias[i]),
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${i + 1}/${publication.medias.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(String url) {
    return Image.network(
      url,
      height: 320,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, enfant, progression) {
        if (progression == null) return enfant;

        return Container(
          height: 320,
          color: context.teinteMaboko,
          child: const Center(
            child: CircularProgressIndicator(color: MabokoCouleurs.secondaire, strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        height: 320,
        color: context.teinteMaboko,
        child: Icon(Icons.broken_image_outlined, size: 40, color: context.bordureMaboko),
      ),
    );
  }

  Widget _actionIcone({
    required IconData icone,
    required Color couleur,
    required int valeur,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 22, color: couleur),
            if (valeur > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$valeur',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
