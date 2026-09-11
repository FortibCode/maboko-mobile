import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../core/theme/maboko_theme.dart';
import '../core/widgets/carte_pressable.dart';
import '../core/widgets/choix_photo.dart';
import '../core/widgets/etats.dart';
import '../core/widgets/visionneuse_photo.dart';
import '../features/compte/data/profil_repository.dart';
import '../features/fil/data/fil_repository.dart';
import '../features/fil/models/publication.dart';

/// Portfolio de réalisations de l'artisan (§5.2.3).
///
/// L'écran précédent était une simulation : il ajoutait une entrée écrite en
/// dur — titre fixe, logo de l'application en guise de photo — à une liste
/// gardée en mémoire, puis annonçait « Réalisation ajoutée avec succès ».
/// Rien n'était envoyé au serveur, donc rien n'était visible par un client.
///
/// Les réalisations sont désormais les publications de l'artisan : les mêmes
/// que le fil affiche, et que la fiche artisan montre aux clients.
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  static const _fil = FilRepository();

  List<Publication>? _realisations;
  String? _erreur;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      final profil = await const ProfilRepository().moi();
      final publications = await _fil.publications(artisanId: profil.id);
      if (!mounted) return;
      setState(() => _realisations = publications);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    }
  }

  Future<void> _ajouter() async {
    final photo = await choisirPhoto(context);
    if (photo == null || !mounted) return;

    final description = await _demanderDescription();
    if (description == null || !mounted) return;

    setState(() => _envoi = true);

    try {
      await _fil.publier(
        metier: 'realisation',
        description: description,
        medias: [photo],
      );
      await _charger();
      if (!mounted) return;
      setState(() => _envoi = false);
      _informer('Réalisation publiée. Elle est visible sur votre profil.', MabokoCouleurs.succes);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _envoi = false);
      _informer(e.message, MabokoCouleurs.danger);
    }
  }

  Future<String?> _demanderDescription() {
    final champ = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (contexte) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Décrivez cette réalisation'),
        content: TextField(
          controller: champ,
          autofocus: true,
          maxLines: 3,
          maxLength: 300,
          decoration: const InputDecoration(
            hintText: 'Ex : réfection complète d’une toiture à Bacongo.',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexte), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MabokoCouleurs.secondaire),
            onPressed: () {
              final texte = champ.text.trim();
              // L'API exige une description : sans elle, la publication
              // partirait pour être refusée.
              if (texte.isEmpty) return;
              Navigator.pop(contexte, texte);
            },
            child: const Text('Publier'),
          ),
        ],
      ),
    );
  }

  Future<void> _supprimer(Publication realisation) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (contexte) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Retirer cette réalisation ?'),
        content: const Text('Elle disparaîtra de votre profil et du fil d’actualité.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexte, false), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MabokoCouleurs.danger),
            onPressed: () => Navigator.pop(contexte, true),
            child: const Text('Retirer'),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      await _fil.supprimerPublication(realisation.id);
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      _informer(e.message, MabokoCouleurs.danger);
    }
  }

  void _informer(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: couleur),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mon portfolio'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _envoi ? null : _ajouter,
        backgroundColor: MabokoCouleurs.secondaire,
        icon: _envoi
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: Text(
          _envoi ? 'Publication…' : 'Ajouter',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
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
        children: [const SizedBox(height: 60), EtatErreur(message: _erreur!, onReessayer: _charger)],
      );
    }

    if (_realisations == null) return const ChargementEnCours();

    if (_realisations!.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 50),
          EtatVide(
            icone: Icons.photo_library_outlined,
            titre: 'Votre portfolio est vide',
            message: 'Ajoutez une photo de vos travaux : elle apparaîtra sur votre profil, '
                'et les clients pourront juger votre savoir-faire avant de vous contacter.',
          ),
        ],
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: _realisations!.length,
      itemBuilder: (contexte, i) => ApparitionDecalee(
        rang: i,
        child: _carte(_realisations![i]),
      ),
    );
  }

  Widget _apercu(String? url) {
    if (url == null) {
      return Container(
        color: MabokoCouleurs.bordure.withValues(alpha: 0.4),
        child: Icon(Icons.image_outlined, color: context.texteSecondaireMaboko),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (contexte, erreur, trace) => Container(
        color: MabokoCouleurs.bordure.withValues(alpha: 0.4),
        child: Icon(Icons.broken_image_outlined, color: context.texteSecondaireMaboko),
      ),
    );
  }

  Widget _carte(Publication realisation) {
    final apercu = realisation.medias.isEmpty ? null : realisation.medias.first;

    // L'appui ouvrait la demande de suppression : la seule action possible
    // sur sa propre realisation etait de l'effacer, sans meme pouvoir la
    // regarder en grand. Le retrait passe desormais par un bouton dedie.
    return CartePressable(
      echelle: 0.97,
      onTap: apercu == null
          ? null
          : () => VisionneusePhoto.ouvrir(
                context,
                urls: realisation.medias,
                legende: realisation.description,
              ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _apercu(apercu),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => _supprimer(realisation),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.delete_outline_rounded,
                              size: 17, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                realisation.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
