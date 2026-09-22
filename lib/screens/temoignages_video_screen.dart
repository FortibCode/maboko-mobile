import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

import '../core/theme/maboko_theme.dart';
import '../core/widgets/etats.dart';

/// Mes témoignages vidéos (§5.1.7).
///
/// Le client filme un retour d'expérience sur un artisan : 30 secondes qui
/// valent mieux qu'un long commentaire écrit. Les vidéos restent sur le
/// téléphone tant qu'elles ne sont pas publiées manuellement.
class TemoignagesVideoScreen extends StatefulWidget {
  const TemoignagesVideoScreen({super.key});

  @override
  State<TemoignagesVideoScreen> createState() => _TemoignagesVideoScreenState();
}

class _TemoignagesVideoScreenState extends State<TemoignagesVideoScreen> {
  static const _cleVideos = 'temoignages_videos';

  List<TemoignageVideo> _videos = const [];
  bool _chargement = true;
  bool _enregistrementEnCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getStringList(_cleVideos) ?? [];

    if (!mounted) return;
    setState(() {
      _videos = brut
          .map(TemoignageVideo.depuisChaine)
          .whereType<TemoignageVideo>()
          .toList()
        ..sort((a, b) => b.enregistreLe.compareTo(a.enregistreLe));
      _chargement = false;
    });
  }

  Future<void> _enregistrer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cleVideos,
      _videos.map((v) => v.versChaine()).toList(),
    );
  }

  Future<void> _filmer() async {
    setState(() => _enregistrementEnCours = true);

    try {
      final fichier = await ImagePicker().pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 60),
      );

      if (fichier == null) {
        setState(() => _enregistrementEnCours = false);
        return;
      }

      final titre = await _demanderTitre();
      if (titre == null || titre.trim().isEmpty) {
        setState(() => _enregistrementEnCours = false);
        return;
      }

      final video = TemoignageVideo(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        titre: titre.trim(),
        cheminFichier: fichier.path,
        enregistreLe: DateTime.now(),
      );

      setState(() {
        _videos = [video, ..._videos];
        _enregistrementEnCours = false;
      });
      await _enregistrer();
    } catch (_) {
      if (!mounted) return;
      setState(() => _enregistrementEnCours = false);
      _informer('Impossible d’enregistrer la vidéo sur cet appareil.',
          MabokoCouleurs.danger);
    }
  }

  Future<String?> _demanderTitre() {
    final controleur = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Titre du témoignage'),
        content: TextField(
          controller: controleur,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 60,
          decoration: const InputDecoration(
            hintText: 'Ex. : Réparation de ma toiture',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controleur.text),
            child: const Text('Valider',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _lire(TemoignageVideo video) async {
    final fichier = File(video.cheminFichier);
    if (!await fichier.exists()) {
      if (!mounted) return;
      _informer('La vidéo n’est plus disponible sur cet appareil.',
          MabokoCouleurs.danger);
      return;
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _LecteurVideo(video: video)),
    );
  }

  Future<void> _supprimer(TemoignageVideo video) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce témoignage ?'),
        content: const Text('La vidéo restera sur votre téléphone, mais elle '
            'sera retirée de cette liste.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Retirer',
                style: TextStyle(color: MabokoCouleurs.danger)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() => _videos = _videos.where((v) => v.id != video.id).toList());
    await _enregistrer();
  }

  void _informer(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: couleur),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Mes témoignages vidéos'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _enregistrementEnCours ? null : _filmer,
        backgroundColor: MabokoCouleurs.secondaire,
        icon: _enregistrementEnCours
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
              )
            : const Icon(Icons.videocam_rounded, color: Colors.white),
        label: const Text('Filmer',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: _chargement
          ? const ChargementEnCours()
          : _videos.isEmpty
              ? _vide()
              : _liste(),
    );
  }

  Widget _vide() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 60),
        EtatVide(
          icone: Icons.videocam_off_outlined,
          titre: 'Aucun témoignage vidéo',
          message: 'Filmez un retour d’expérience sur un artisan : 30 '
              'secondes qui valent mieux qu’un long commentaire. '
              'Les vidéos restent sur votre téléphone.',
        ),
      ],
    );
  }

  Widget _liste() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _videos.length + 1,
      itemBuilder: (contexte, i) {
        if (i == 0) return _encadre();

        final video = _videos[i - 1];

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.bordureMaboko),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: MabokoCouleurs.secondaire.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.play_circle_outline_rounded,
                  color: MabokoCouleurs.secondaire, size: 26),
            ),
            title: Text(
              video.titre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                _dateLisible(video.enregistreLe),
                style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko),
              ),
            ),
            onTap: () => _lire(video),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: MabokoCouleurs.danger, size: 20),
              tooltip: 'Retirer',
              onPressed: () => _supprimer(video),
            ),
          ),
        );
      },
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
          const Icon(Icons.info_outline_rounded, size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Les vidéos sont enregistrées sur votre téléphone. Elles ne '
              'sont publiées nulle part tant que vous ne le demandez pas '
              'explicitement.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: context.texteSecondaireMaboko),
            ),
          ),
        ],
      ),
    );
  }

  String _dateLisible(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inMinutes < 1) return 'à l’instant';
    if (difference.inHours < 1) return 'il y a ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'il y a ${difference.inHours} h';
    if (difference.inDays == 1) return 'hier';
    if (difference.inDays < 7) return 'il y a ${difference.inDays} jours';

    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];
    return '${date.day} ${mois[date.month - 1]} ${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Modèle
// ---------------------------------------------------------------------------

/// Référence d'un témoignage vidéo, encodée en `id|titre|chemin|horodatage`.
class TemoignageVideo {
  const TemoignageVideo({
    required this.id,
    required this.titre,
    required this.cheminFichier,
    required this.enregistreLe,
  });

  final String id;
  final String titre;
  final String cheminFichier;
  final DateTime enregistreLe;

  String versChaine() =>
      '$id|${titre.replaceAll('|', '&#124;')}|$cheminFichier|${enregistreLe.millisecondsSinceEpoch}';

  static TemoignageVideo? depuisChaine(String brut) {
    final morceaux = brut.split('|');
    if (morceaux.length < 4) return null;

    return TemoignageVideo(
      id: morceaux[0],
      titre: morceaux[1].replaceAll('&#124;', '|'),
      cheminFichier: morceaux[2],
      enregistreLe: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(morceaux[3]) ?? 0,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lecteur vidéo
// ---------------------------------------------------------------------------

class _LecteurVideo extends StatefulWidget {
  const _LecteurVideo({required this.video});

  final TemoignageVideo video;

  @override
  State<_LecteurVideo> createState() => _LecteurVideoState();
}

class _LecteurVideoState extends State<_LecteurVideo> {
  late final VideoPlayerController _controleur;
  bool _pret = false;

  @override
  void initState() {
    super.initState();
    _controleur = VideoPlayerController.file(File(widget.video.cheminFichier))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _pret = true);
        _controleur.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _pret = false);
      });
  }

  @override
  void dispose() {
    _controleur.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.video.titre),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: _pret
            ? AspectRatio(
                aspectRatio: _controleur.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    VideoPlayer(_controleur),
                    VideoProgressIndicator(
                      _controleur,
                      allowScrubbing: true,
                      colors: const VideoProgressColors(
                        playedColor: MabokoCouleurs.secondaire,
                        bufferedColor: Colors.white38,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                    _boutonLecture(),
                  ],
                ),
              )
            : const CircularProgressIndicator(color: MabokoCouleurs.secondaire),
      ),
    );
  }

  Widget _boutonLecture() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ValueListenableBuilder(
        valueListenable: _controleur,
        builder: (context, value, _) => IconButton(
          iconSize: 48,
          color: Colors.white,
          icon: Icon(value.isPlaying
              ? Icons.pause_circle_filled_rounded
              : Icons.play_circle_filled_rounded),
          onPressed: () {
            setState(() {
              value.isPlaying ? _controleur.pause() : _controleur.play();
            });
          },
        ),
      ),
    );
  }
}