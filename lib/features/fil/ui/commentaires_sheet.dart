import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/fil_repository.dart';
import '../models/publication.dart';

/// Commentaires d'une publication.
///
/// Renvoie le nombre de commentaires ajoutés pendant la session, pour que le
/// fil mette son compteur à jour sans tout recharger.
class CommentairesSheet extends StatefulWidget {
  const CommentairesSheet({super.key, required this.publication});

  final Publication publication;

  @override
  State<CommentairesSheet> createState() => _CommentairesSheetState();
}

class _CommentairesSheetState extends State<CommentairesSheet> {
  static const _repository = FilRepository();

  final TextEditingController _saisie = TextEditingController();

  List<Commentaire> _commentaires = const [];
  bool _chargement = true;
  bool _envoiEnCours = false;
  int _ajoutes = 0;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _saisie.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final commentaires = await _repository.commentaires(widget.publication.id);
      if (!mounted) return;
      setState(() {
        _commentaires = commentaires;
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

  Future<void> _envoyer() async {
    final contenu = _saisie.text.trim();
    if (contenu.isEmpty) return;

    setState(() => _envoiEnCours = true);

    try {
      final commentaire = await _repository.commenter(widget.publication.id, contenu);
      if (!mounted) return;
      setState(() {
        _commentaires = [commentaire, ..._commentaires];
        _ajoutes++;
        _envoiEnCours = false;
        _saisie.clear();
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _envoiEnCours = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (deja, _) {
        // Fermeture par glissement : le compteur du fil doit être mis à jour
        // comme si l'on avait utilisé la croix.
        if (!deja) Navigator.pop(context, _ajoutes);
      },
      child: Padding(
        // Laisse la place au clavier lorsqu'il s'ouvre.
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: context.teinteMaboko,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: context.bordureMaboko,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Row(
                children: [
                  const SizedBox(width: 48),
                  const Expanded(
                    child: Text(
                      'Commentaires',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    child: IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context, _ajoutes),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Divider(height: 1),
              Expanded(child: _liste()),
              _barreSaisie(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _liste() {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null) return EtatErreur(message: _erreur!, onReessayer: _charger);

    if (_commentaires.isEmpty) {
      return const EtatVide(
        icone: Icons.chat_bubble_outline,
        titre: 'Aucun commentaire',
        message: 'Soyez le premier à réagir à cette réalisation.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _commentaires.length,
      itemBuilder: (context, i) {
        final commentaire = _commentaires[i];

        return ListTile(
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: context.surfaceMaboko,
            backgroundImage: commentaire.auteurAvatar?.isNotEmpty == true
                ? NetworkImage(commentaire.auteurAvatar!)
                : null,
            child: commentaire.auteurAvatar?.isNotEmpty == true
                ? null
                : const Icon(Icons.person, size: 18, color: MabokoCouleurs.secondaire),
          ),
          title: Text(
            commentaire.auteurNom,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            commentaire.contenu,
            style: TextStyle(fontSize: 13.5, height: 1.4, color: context.texteFortMaboko),
          ),
        );
      },
    );
  }

  Widget _barreSaisie() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        decoration: BoxDecoration(
          color: context.surfaceMaboko,
          border: Border(top: BorderSide(color: context.bordureMaboko)),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _saisie,
                maxLength: 1000,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _envoyer(),
                decoration: const InputDecoration(
                  hintText: 'Écrire un commentaire…',
                  counterText: '',
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              onPressed: _envoiEnCours ? null : _envoyer,
              icon: _envoiEnCours
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MabokoCouleurs.secondaire),
                    )
                  : const Icon(Icons.send_rounded, color: MabokoCouleurs.secondaire),
            ),
          ],
        ),
      ),
    );
  }
}
