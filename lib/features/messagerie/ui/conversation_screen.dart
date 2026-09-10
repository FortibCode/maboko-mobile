import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/temps_reel/canal_reverb.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/choix_photo.dart';
import '../../../core/widgets/etats.dart';
import '../data/messagerie_repository.dart';
import '../models/conversation.dart';
import 'conversations_screen.dart' show horodatageCourt;

/// Fil d'une conversation (§5.1.9).
///
/// Les messages arrivent par le canal privé Reverb : le délai d'affichage
/// tient alors la seconde, comme l'exige le §7.2. Une interrogation
/// périodique reste active en filet — lente quand le temps réel fonctionne,
/// rapprochée quand il est indisponible (compilation sans clé Reverb, ou
/// réseau qui bloque les WebSockets).
class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.conversation});

  final Conversation conversation;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  static const _repository = MessagerieRepository();

  /// Sans temps réel, l'interrogation doit être rapprochée pour rester
  /// utilisable ; avec, elle n'est qu'un filet de sécurité.
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

  @override
  void initState() {
    super.initState();
    _charger(premiereFois: true);
    _brancherTempsReel();

    _minuterie = Timer.periodic(
      AppConfig.tempsReelDisponible ? _intervalleAvecTempsReel : _intervalleSansTempsReel,
      (_) => _charger(),
    );
  }

  @override
  void dispose() {
    _minuterie?.cancel();
    _canal?.fermer();
    _saisie.dispose();
    _defilement.dispose();
    super.dispose();
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

      // Le message que l'on vient d'envoyer revient aussi par le canal :
      // il est déjà affiché, inutile de le dupliquer.
      if (_messages.any((m) => m.id == message.id)) return;

      setState(() => _messages = [message, ..._messages]);
      _repository.marquerLu(widget.conversation.id);
    });

    canal.connecter();
  }

  /// Identifiant du compte connecté, déduit du premier message que l'API a
  /// marqué comme étant de nous. Le canal temps réel, lui, ne connaît pas son
  /// destinataire et ne peut donc pas fournir « deMoi ».
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

      // Ne redessine que si quelque chose a changé : sinon l'écran clignote
      // toutes les cinq secondes.
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

  /// Envoi d'une photo dans la conversation.
  ///
  /// Le bouton n'existait pas : on pouvait recevoir une image, jamais en
  /// joindre une — alors qu'un chantier se decrit surtout en photos.
  Future<void> _envoyerPhoto() async {
    if (_envoiEnCours) return;

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
        // Le texte est rendu à l'utilisateur : rien n'est perdu.
        _saisie.text = contenu;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

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
          _barreSaisie(),
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
      // Le fil part du bas : les messages les plus récents sont sous les yeux.
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
            if (message.mediaUrl != null)
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
              icon: Icon(Icons.photo_camera_outlined,
                  color: _envoiEnCours
                      ? context.texteSecondaireMaboko
                      : MabokoCouleurs.secondaire),
            ),
            IconButton(
              onPressed: _envoiEnCours ? null : () => _envoyer(),
              icon: _envoiEnCours
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: MabokoCouleurs.secondaire),
                    )
                  : const Icon(Icons.send_rounded, color: MabokoCouleurs.secondaire),
            ),
          ],
        ),
      ),
    );
  }
}
