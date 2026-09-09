import 'package:flutter/material.dart';

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

  List<Publication> _publications = const [];
  List<StoryItem> _stories = const [];
  bool _chargement = true;
  String? _erreur;

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
      setState(() {
        _publications = resultats[0] as List<Publication>;
        _stories = resultats[1] as List<StoryItem>;
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
                    backgroundColor: MabokoCouleurs.surface,
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
      color: MabokoCouleurs.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: MabokoCouleurs.fond,
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
              style: const TextStyle(fontSize: 12, color: MabokoCouleurs.texteSecondaire),
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
          color: MabokoCouleurs.fond,
          child: const Center(
            child: CircularProgressIndicator(color: MabokoCouleurs.secondaire, strokeWidth: 2),
          ),
        );
      },
      errorBuilder: (_, __, ___) => Container(
        height: 320,
        color: MabokoCouleurs.fond,
        child: const Icon(Icons.broken_image_outlined, size: 40, color: MabokoCouleurs.bordure),
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
