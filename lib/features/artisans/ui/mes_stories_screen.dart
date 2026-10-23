import 'package:flutter/material.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/widgets/etats.dart';
import '../../../core/widgets/choix_photo.dart'; // 👈 Nécessaire pour choisir une photo

class MesStoriesScreen extends StatefulWidget {
  const MesStoriesScreen({super.key});

  @override
  State<MesStoriesScreen> createState() => _MesStoriesScreenState();
}

class _MesStoriesScreenState extends State<MesStoriesScreen> {
  List<dynamic>? _stories;
  String? _erreur;
  bool _envoiEnCours = false; // Pour afficher le loader pendant l'envoi

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);
    try {
      // Adapte l'appel avec ton ApiClient ou Repository
      final reponse = await const ApiClient().get('/stories/me');
      setState(() => _stories = reponse['data']);
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    }
  }

  // 📸 FONCTION POUR PUBLIER UNE STORY
  Future<void> _publierStory() async {
    // Ouvre la galerie ou l'appareil photo
    final photo = await choisirPhoto(context);
    if (photo == null || !mounted) return;

    setState(() => _envoiEnCours = true);

    try {
      // ⚠️ ÉTAPE IMPORTANTE : Upload de l'image
      // Si `choisirPhoto` te renvoie un fichier (XFile), il faut d'abord l'envoyer
      // sur ton serveur pour obtenir une URL. 
      // Si tu as un service comme ProfilRepository().enregistrerPhoto(photo), utilise-le.
      
      // Ici, je simule que `photo` est déjà une URL (à adapter selon ton code !)
      final String urlImage = photo.toString(); 

      // Envoi de l'URL à l'API Stories
      await const ApiClient().post('/stories', {
        'media_url': urlImage,
        'type': 'image',
      });

      await _charger(); // Recharge la liste pour afficher la nouvelle story

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Story publiée ! Elle disparaîtra dans 2 heures.'),
          backgroundColor: MabokoCouleurs.succes,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la publication : $e'),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _envoiEnCours = false);
    }
  }

  Future<void> _supprimerStory(int id) async {
    try {
      await const ApiClient().delete('/stories/$id');
      await _charger();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story supprimée'), backgroundColor: MabokoCouleurs.succes),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la suppression'), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

  void _voirVues(int storyId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StoryVuesScreen(storyId: storyId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes stories'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
      ),
      // 🚀 BOUTON FLOTTANT POUR AJOUTER UNE STORY
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _envoiEnCours ? null : _publierStory,
        backgroundColor: MabokoCouleurs.secondaire,
        icon: _envoiEnCours
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.add_a_photo, color: Colors.white),
        label: Text(
          _envoiEnCours ? 'Publication...' : 'Publier',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _erreur != null
          ? EtatErreur(message: _erreur!, onReessayer: _charger)
          : _stories == null
              ? const ChargementEnCours()
              : _stories!.isEmpty
                  ? const EtatVide(
                      titre: 'Aucune story active',
                      message: 'Clique sur le bouton "Publier" en bas à droite pour ajouter ta première story. Elle durera 2 heures.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), // Marge en bas pour le bouton
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _stories!.length,
                      itemBuilder: (context, index) {
                        final story = _stories![index];
                        return GestureDetector(
                          onTap: () => _voirVues(story['id']),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.grey.shade300,
                              image: story['media_url'] != null
                                  ? DecorationImage(
                                      image: NetworkImage(story['media_url']),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.white),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black45,
                                    ),
                                    onPressed: () => _supprimerStory(story['id']),
                                  ),
                                ),
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.remove_red_eye, color: Colors.white, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${story['vues_count'] ?? 0}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}

// --- L'écran des vues ---
class StoryVuesScreen extends StatefulWidget {
  final int storyId;
  const StoryVuesScreen({super.key, required this.storyId});

  @override
  State<StoryVuesScreen> createState() => _StoryVuesScreenState();
}

class _StoryVuesScreenState extends State<StoryVuesScreen> {
  List<dynamic>? _vues;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    try {
      final reponse = await const ApiClient().get('/stories/${widget.storyId}/vues');
      setState(() => _vues = reponse['data']);
    } on ApiException catch (e) {
      setState(() => _erreur = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vues de la story'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
      ),
      body: _erreur != null
          ? EtatErreur(message: _erreur!, onReessayer: _charger)
          : _vues == null
              ? const ChargementEnCours()
              : _vues!.isEmpty
                  ? const EtatVide(titre: 'Aucune vue', message: 'Personne n\'a encore vu cette story.')
                  : ListView.separated(
                      itemCount: _vues!.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final vue = _vues![index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: vue['avatarUrl'] != null
                                ? NetworkImage(vue['avatarUrl'])
                                : null,
                            child: vue['avatarUrl'] == null ? const Icon(Icons.person) : null,
                          ),
                          title: Text('${vue['prenom']} ${vue['nom']}'.trim()),
                          trailing: const Icon(Icons.remove_red_eye, size: 16, color: Colors.grey),
                        );
                      },
                    ),
    );
  }
}