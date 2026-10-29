import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as rec;

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/temps_reel/canal_reverb.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/choix_photo.dart';
import '../../../core/widgets/etats.dart';
import '../data/messagerie_repository.dart';
import '../models/conversation.dart';
import 'audio_io_stub.dart' if (dart.library.io) 'audio_io_native.dart';
import 'conversations_screen.dart' show horodatageCourt;

/// Fil d'une conversation (§5.1.9) avec support des messages vocaux.
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  static const _repository = MessagerieRepository();

  static const _intervalleSansTempsReel = Duration(seconds: 5);
  static const _intervalleAvecTempsReel = Duration(seconds: 45);

  final TextEditingController _saisie = TextEditingController();
  final ScrollController _defilement = ScrollController();

  Timer? _minuterie;
  CanalReverb? _canal;
  List<MessageChat> _messages = const [];
  bool _chargement = true;
  bool _envoiEnCours = false;
  String? _erreur;

  // ── Enregistrement audio ────────────────────────────────────────────
  final rec.AudioRecorder _enregistreur = rec.AudioRecorder();
  bool _enregistrementEnCours = false;
  int _secondesEnregistrees = 0;
  Timer? _chronoEnregistrement;

  @override
  void initState() {
    super.initState();
    _charger(premiereFois: true);
    _brancherTempsReel();

    _minuterie = Timer.periodic(
      AppConfig.tempsReelDisponible ? _intervalleAvecTempsReel : _intervalleSansTempsReel,
      (_) => _charger(),
    );

    _saisie.addListener(_rafraichirBoutons);
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    _chronoEnregistrement?.cancel();
    _canal?.fermer();
    _enregistreur.dispose();
    _saisie.removeListener(_rafraichirBoutons);
    _saisie.dispose();
    _defilement.dispose();
    super.dispose();
  }

  void _rafraichirBoutons() {
    if (mounted) setState(() {});
  }

  void _brancherTempsReel() {
    if (!AppConfig.tempsReelDisponible) return;

    final canal = CanalReverb(nomCanal: 'conversation.${widget.conversation.id}');
    _canal = canal;

    canal.evenements.listen((evenement) {
      if (evenement.nom != 'message.envoye' || !mounted) return;

      final charge = evenement.donnees['message'];
      if (charge is! Map<String, dynamic>) return;

      final message = MessageChat.depuisJson(charge, moiId: _moiId);

      if (_messages.any((m) => m.id == message.id)) return;

      setState(() => _messages = [message, ..._messages]);
      _repository.marquerLu(widget.conversation.id);
    });

    canal.connecter();
  }

  int? get _moiId {
    for (final message in _messages) {
      if (message.deMoi) return message.expediteurId;
    }
    return null;
  }

  Future<void> _charger({bool premiereFois = false}) async {
    try {
      final messages = await _repository.messages(widget.conversation.id);
      if (!mounted) return;

      final aChange = messages.length != _messages.length ||
          (messages.isNotEmpty && _messages.isNotEmpty && messages.first.id != _messages.first.id);

      if (aChange || premiereFois) {
        setState(() {
          _messages = messages;
          _chargement = false;
          _erreur = null;
        });
      }

      if (premiereFois || aChange) {
        await _repository.marquerLu(widget.conversation.id);
      }
    } on ApiException catch (e) {
      if (!mounted || !premiereFois) return;
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    }
  }

  // ── Enregistrement audio ────────────────────────────────────────────

  Future<void> _demarrerEnregistrement() async {
    if (_enregistrementEnCours || _envoiEnCours) return;

    final permission = await _enregistreur.hasPermission();
    if (!permission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autorisez le microphone pour envoyer un message vocal.'),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );
      return;
    }

    final dossier = await getTemporaryDirectory();
    final chemin = '${dossier.path}/vocal_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _enregistreur.start(
      const rec.RecordConfig(
        encoder: rec.AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
      ),
      path: chemin,
    );

    setState(() {
      _enregistrementEnCours = true;
      _secondesEnregistrees = 0;
    });

    _chronoEnregistrement = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondesEnregistrees++);

      if (_secondesEnregistrees >= 180) {
        _arreterEtEnvoyer();
      }
    });
  }

  Future<void> _arreterEtEnvoyer() async {
    if (!_enregistrementEnCours) return;

    _chronoEnregistrement?.cancel();
    final chemin = await _enregistreur.stop();

    setState(() {
      _enregistrementEnCours = false;
      _secondesEnregistrees = 0;
    });

    if (chemin == null) return;

    setState(() => _envoiEnCours = true);

    try {
      final fichier = await _lireFichierAudio(chemin);
      if (fichier == null) throw Exception('Fichier audio illisible.');

      final base64Audio = 'data:${fichier.mime};base64,${base64Encode(fichier.octets)}';

      final message = await _repository.envoyerAudio(
        widget.conversation.id,
        base64Audio,
      );

      if (!mounted) return;
      setState(() {
        _messages = [message, ..._messages];
        _envoiEnCours = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _envoiEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _envoiEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'envoyer le message vocal."),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );
    }
  }

  Future<void> _annulerEnregistrement() async {
    if (!_enregistrementEnCours) return;

    _chronoEnregistrement?.cancel();
    await _enregistreur.stop();

    setState(() {
      _enregistrementEnCours = false;
      _secondesEnregistrees = 0;
    });
  }

  Future<_AudioPrepare?> _lireFichierAudio(String chemin) async {
    final octets = await lireFichierAudio(chemin);
    if (octets == null) return null;

    final extension = chemin.split('.').last.toLowerCase();
    final mime = switch (extension) {
      'm4a' || 'mp4' || 'aac' => 'audio/mp4',
      'mp3' => 'audio/mpeg',
      'ogg' || 'opus' => 'audio/ogg',
      'webm' => 'audio/webm',
      'wav' => 'audio/wav',
      _ => 'audio/mp4',
    };

    return _AudioPrepare(mime, octets);
  }

  // ── Envoi photo ─────────────────────────────────────────────────────

  Future<void> _envoyerPhoto() async {
    if (_envoiEnCours || _enregistrementEnCours) return;

    final photo = await choisirPhoto(context);
    if (photo == null || !mounted) return;

    await _envoyer(media: photo);
  }

  Future<void> _envoyer({String? media}) async {
    final contenu = _saisie.text.trim();
    if ((contenu.isEmpty && media == null) || _envoiEnCours) return;

    setState(() => _envoiEnCours = true);
    _saisie.clear();

    try {
      final message =
          await _repository.envoyer(widget.conversation.id, contenu, media: media);
      if (!mounted) return;
      setState(() {
        _messages = [message, ..._messages];
        _envoiEnCours = false;
      });
      _defilement.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _envoiEnCours = false;
        _saisie.text = contenu;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final interlocuteur = widget.conversation.interlocuteur;

    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: Colors.white24,
              backgroundImage: interlocuteur.avatarUrl?.isNotEmpty == true
                  ? NetworkImage(interlocuteur.avatarUrl!)
                  : null,
              child: interlocuteur.avatarUrl?.isNotEmpty == true
                  ? null
                  : Icon(
                      widget.conversation.estSupport
                          ? Icons.support_agent_rounded
                          : Icons.handyman_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                interlocuteur.nomComplet,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _corps()),
          _enregistrementEnCours ? _barreEnregistrement() : _barreSaisie(),
        ],
      ),
    );
  }

  Widget _corps() {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null && _messages.isEmpty) {
      return EtatErreur(message: _erreur!, onReessayer: () => _charger(premiereFois: true));
    }

    if (_messages.isEmpty) {
      return const EtatVide(
        icone: Icons.waving_hand_outlined,
        titre: 'Démarrez la conversation',
        message: 'Présentez votre besoin en quelques mots pour obtenir une réponse rapide.',
      );
    }

    return ListView.builder(
      controller: _defilement,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      itemCount: _messages.length,
      itemBuilder: (context, i) => _bulle(_messages[i]),
    );
  }

  Widget _bulle(MessageChat message) {
    final deMoi = message.deMoi;

    return Align(
      alignment: deMoi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: deMoi ? MabokoCouleurs.secondaire : context.surfaceMaboko,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(deMoi ? 16 : 4),
            bottomRight: Radius.circular(deMoi ? 4 : 16),
          ),
          border: deMoi ? null : Border.all(color: context.bordureMaboko),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.estAudio && message.mediaUrl != null)
              _LecteurAudio(
                url: message.mediaUrl!,
                surFondColore: deMoi,
              ),
            if (message.estImage && message.mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(message.mediaUrl!, fit: BoxFit.cover),
              ),
            if (message.contenu != null && message.contenu!.isNotEmpty)
              Text(
                message.contenu!,
                style: TextStyle(
                  fontSize: 14.5,
                  height: 1.4,
                  color: deMoi ? Colors.white : MabokoCouleurs.principale,
                ),
              ),
            const SizedBox(height: 3),
            Text(
              horodatageCourt(message.envoyeLe),
              style: TextStyle(
                fontSize: 10,
                color: deMoi ? Colors.white70 : context.texteSecondaireMaboko,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barreSaisie() {
    final champVide = _saisie.text.trim().isEmpty;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 8, 8),
        decoration: BoxDecoration(
          color: context.surfaceMaboko,
          border: Border(top: BorderSide(color: context.bordureMaboko)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _saisie,
                maxLines: 4,
                minLines: 1,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Votre message…',
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Joindre une photo',
              onPressed: _envoiEnCours ? null : _envoyerPhoto,
              icon: Icon(
                Icons.photo_camera_outlined,
                color: _envoiEnCours
                    ? context.texteSecondaireMaboko
                    : MabokoCouleurs.secondaire,
              ),
            ),
            if (_envoiEnCours)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: MabokoCouleurs.secondaire,
                  ),
                ),
              )
            else if (champVide)
              // 👇 ICÔNE CORRIGÉE ICI 👇
              IconButton(
                tooltip: 'Enregistrer un message vocal',
                onPressed: _demarrerEnregistrement,
                icon: const Icon(
                  Icons.mic, // Utilisation de l'icône standard, compatible partout
                  size: 26, 
                  color: MabokoCouleurs.secondaire,
                ),
              )
            else
              IconButton(
                tooltip: 'Envoyer',
                onPressed: () => _envoyer(),
                icon: const Icon(
                  Icons.send_rounded, 
                  size: 26,
                  color: MabokoCouleurs.secondaire,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _barreEnregistrement() {
    final minutes = (_secondesEnregistrees ~/ 60).toString().padLeft(1, '0');
    final secondes = (_secondesEnregistrees % 60).toString().padLeft(2, '0');

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: MabokoCouleurs.danger.withValues(alpha: 0.08),
          border: Border(top: BorderSide(color: context.bordureMaboko)),
        ),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Annuler',
              onPressed: _annulerEnregistrement,
              icon: const Icon(Icons.close_rounded, color: MabokoCouleurs.danger),
            ),
            Expanded(
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record,
                      size: 12, color: MabokoCouleurs.danger),
                  const SizedBox(width: 8),
                  Text(
                    'Enregistrement  $minutes:$secondes',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: MabokoCouleurs.danger,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Envoyer',
              onPressed: _arreterEtEnvoyer,
              icon: const Icon(Icons.send_rounded, color: MabokoCouleurs.secondaire),
            ),
          ],
        ),
      ),
    );
  }
}

/// Résultat de la préparation d'un fichier audio : type MIME et octets.
class _AudioPrepare {
  const _AudioPrepare(this.mime, this.octets);

  final String mime;
  final Uint8List octets;
}

/// Lecteur audio intégré à une bulle.
class _LecteurAudio extends StatefulWidget {
  const _LecteurAudio({required this.url, required this.surFondColore});

  final String url;
  final bool surFondColore;

  @override
  State<_LecteurAudio> createState() => _LecteurAudioState();
}

class _LecteurAudioState extends State<_LecteurAudio> {
  late final AudioPlayer _lecteur;
  bool _enLecture = false;
  Duration _duree = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _lecteur = AudioPlayer();

    _lecteur.playerStateStream.listen((etat) {
      if (!mounted) return;
      setState(() => _enLecture = etat.playing);
    });

    _lecteur.durationStream.listen((d) {
      if (!mounted || d == null) return;
      setState(() => _duree = d);
    });

    _lecteur.positionStream.listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });

    _charger();
  }

  Future<void> _charger() async {
    try {
      await _lecteur.setUrl(widget.url);
    } catch (_) {
      // URL invalide ou réseau.
    }
  }

  @override
  void dispose() {
    _lecteur.dispose();
    super.dispose();
  }

  Future<void> _basculerLecture() async {
    if (_enLecture) {
      await _lecteur.pause();
    } else {
      if (_lecteur.processingState == ProcessingState.completed) {
        await _lecteur.seek(Duration.zero);
      }
      await _lecteur.play();
    }
  }

  String _formatDuree(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final secondes = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$secondes';
  }

  @override
  Widget build(BuildContext context) {
    final couleur = widget.surFondColore ? Colors.white : MabokoCouleurs.secondaire;
    final couleurFond = widget.surFondColore
        ? Colors.white.withValues(alpha: 0.2)
        : MabokoCouleurs.secondaire.withValues(alpha: 0.1);

    final progression = _duree.inMilliseconds == 0
        ? 0.0
        : _position.inMilliseconds / _duree.inMilliseconds;

    return Container(
      constraints: const BoxConstraints(minWidth: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: _basculerLecture,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: couleurFond,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _enLecture ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: couleur,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progression.clamp(0.0, 1.0),
                    minHeight: 3,
                    backgroundColor: couleurFond,
                    valueColor: AlwaysStoppedAnimation(couleur),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _enLecture || _position > Duration.zero
                      ? _formatDuree(_position)
                      : _formatDuree(_duree),
                  style: TextStyle(
                    fontSize: 11,
                    color: couleur,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}