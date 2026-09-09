import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/demande_repository.dart';
import '../models/demande.dart';

/// Détail d'une demande de devis et actions du cycle de vie.
///
/// Les boutons proposés dépendent du rôle et du statut : l'artisan accepte,
/// démarre et termine ; le client annule ou note. L'API applique les mêmes
/// règles côté serveur — l'interface ne fait que les refléter.
class DemandeDetailScreen extends StatefulWidget {
  const DemandeDetailScreen({super.key, required this.demandeId, required this.estArtisan});

  final int demandeId;
  final bool estArtisan;

  @override
  State<DemandeDetailScreen> createState() => _DemandeDetailScreenState();
}

class _DemandeDetailScreenState extends State<DemandeDetailScreen> {
  static const _repository = DemandeRepository();

  Demande? _demande;
  bool _chargement = true;
  bool _actionEnCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final demande = await _repository.detail(widget.demandeId);
      if (!mounted) return;
      setState(() {
        _demande = demande;
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

  Future<void> _agir(Future<Demande> Function() action, String succes) async {
    setState(() => _actionEnCours = true);

    try {
      final demande = await action();
      if (!mounted) return;
      setState(() {
        _demande = demande;
        _actionEnCours = false;
      });
      _informer(succes, MabokoCouleurs.succes);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionEnCours = false);
      _informer(e.message, MabokoCouleurs.danger);
    }
  }

  void _informer(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: couleur),
    );
  }

  // ------------------------------------------------------------------
  // Actions
  // ------------------------------------------------------------------

  Future<void> _accepter() async {
    final montant = await _demanderMontant(
      titre: 'Proposer un montant',
      message: 'Le client verra ce montant avant de confirmer.',
      valeurInitiale: _demande?.budgetEstime,
    );

    if (montant == null) return;

    await _agir(
      () => _repository.accepter(widget.demandeId, montant),
      'Mission acceptée.',
    );
  }

  Future<void> _refuser() async {
    final motif = await _demanderTexte(
      titre: 'Refuser la mission',
      message: 'Expliquer votre refus aide le client à mieux cibler sa prochaine demande.',
      indice: 'Motif (facultatif)',
    );

    if (motif == null) return;

    await _agir(
      () => _repository.refuser(widget.demandeId, motif: motif.isEmpty ? null : motif),
      'Mission refusée.',
    );
  }

  Future<void> _terminer() async {
    final montant = await _demanderMontant(
      titre: 'Clôturer l’intervention',
      message: 'Indiquez le montant réellement facturé.',
      valeurInitiale: _demande?.montantPropose,
    );

    if (montant == null) return;

    await _agir(
      () => _repository.terminer(widget.demandeId, montantFinal: montant),
      'Intervention terminée.',
    );
  }

  Future<void> _annuler() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la demande ?'),
        content: const Text('L’artisan en sera informé. Cette action est définitive.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Revenir')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Annuler la demande', style: TextStyle(color: MabokoCouleurs.danger)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    await _agir(() => _repository.annuler(widget.demandeId), 'Demande annulée.');
  }

  Future<void> _noter() async {
    final resultat = await showDialog<({int note, String commentaire})>(
      context: context,
      builder: (context) => const _DialogueNotation(),
    );

    if (resultat == null) return;

    setState(() => _actionEnCours = true);

    try {
      await _repository.noter(
        widget.demandeId,
        note: resultat.note,
        commentaire: resultat.commentaire,
      );
      if (!mounted) return;
      _informer('Merci, votre avis est publié.', MabokoCouleurs.succes);
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _actionEnCours = false);
      _informer(e.message, MabokoCouleurs.danger);
    }
  }

  // ------------------------------------------------------------------
  // Saisies
  // ------------------------------------------------------------------

  Future<double?> _demanderMontant({
    required String titre,
    required String message,
    double? valeurInitiale,
  }) async {
    final controleur = TextEditingController(
      text: valeurInitiale == null ? '' : valeurInitiale.round().toString(),
    );

    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 13, color: MabokoCouleurs.texteSecondaire)),
            const SizedBox(height: 14),
            TextField(
              controller: controleur,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Montant',
                suffixText: 'FCFA',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Revenir')),
          ElevatedButton(
            onPressed: () {
              final valeur = double.tryParse(controleur.text.replaceAll(' ', ''));
              if (valeur != null && valeur >= 0) Navigator.pop(context, valeur);
            },
            style: ElevatedButton.styleFrom(backgroundColor: MabokoCouleurs.secondaire),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<String?> _demanderTexte({
    required String titre,
    required String message,
    required String indice,
  }) async {
    final controleur = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 13, color: MabokoCouleurs.texteSecondaire)),
            const SizedBox(height: 14),
            TextField(
              controller: controleur,
              maxLines: 3,
              decoration: InputDecoration(labelText: indice, border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Revenir')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controleur.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: MabokoCouleurs.danger),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // Rendu
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabokoCouleurs.fond,
      appBar: AppBar(
        title: const Text('Détail de la demande'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: _demande == null ? null : _barreActions(_demande!),
      body: _corps(),
    );
  }

  Widget _corps() {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null) return EtatErreur(message: _erreur!, onReessayer: _charger);

    final demande = _demande!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                demande.titre,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            PastilleStatut(statut: demande.statut),
          ],
        ),
        const SizedBox(height: 16),
        _bloc(
          titre: 'Le besoin',
          enfant: Text(demande.description, style: const TextStyle(height: 1.5, fontSize: 14)),
        ),
        if (demande.photos.isNotEmpty) ...[
          const SizedBox(height: 14),
          _bloc(
            titre: 'Photos',
            enfant: SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: demande.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    demande.photos[i],
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 92,
                      height: 92,
                      color: MabokoCouleurs.fond,
                      child: const Icon(Icons.broken_image_outlined, color: MabokoCouleurs.bordure),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),
        _bloc(
          titre: 'Intervention',
          enfant: Column(
            children: [
              _ligne(Icons.place_outlined, 'Adresse', demande.adresse),
              if (demande.metier != null) _ligne(Icons.handyman_outlined, 'Métier', demande.metier!),
              if (demande.dateSouhaitee != null)
                _ligne(Icons.event_outlined, 'Date souhaitée', demande.dateSouhaitee!),
              _ligne(
                widget.estArtisan ? Icons.person_outline : Icons.handyman_outlined,
                widget.estArtisan ? 'Client' : 'Artisan',
                (widget.estArtisan ? demande.clientNom : demande.artisanNom) ?? '—',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _bloc(
          titre: 'Montants',
          enfant: Column(
            children: [
              _ligne(Icons.savings_outlined, 'Budget du client', formaterFcfa(demande.budgetEstime)),
              _ligne(Icons.request_quote_outlined, 'Devis proposé', formaterFcfa(demande.montantPropose)),
              if (demande.montantFinal != null)
                _ligne(Icons.check_circle_outline, 'Montant facturé', formaterFcfa(demande.montantFinal)),
            ],
          ),
        ),
        if (demande.motifRefus != null && demande.motifRefus!.isNotEmpty) ...[
          const SizedBox(height: 14),
          _bloc(
            titre: 'Motif',
            enfant: Text(demande.motifRefus!, style: const TextStyle(fontSize: 13.5, height: 1.5)),
          ),
        ],
      ],
    );
  }

  Widget _bloc({required String titre, required Widget enfant}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MabokoCouleurs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MabokoCouleurs.bordure),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          enfant,
        ],
      ),
    );
  }

  Widget _ligne(IconData icone, String libelle, String valeur) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 17, color: MabokoCouleurs.secondaire),
          const SizedBox(width: 10),
          SizedBox(
            width: 118,
            child: Text(
              libelle,
              style: const TextStyle(fontSize: 13, color: MabokoCouleurs.texteSecondaire),
            ),
          ),
          Expanded(
            child: Text(
              valeur,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  /// Actions disponibles selon le rôle et le statut. Rien ne s'affiche
  /// lorsqu'aucune action n'est possible, plutôt qu'un bouton inerte.
  Widget? _barreActions(Demande demande) {
    final actions = <Widget>[];

    if (widget.estArtisan) {
      if (demande.statut == 'en_attente') {
        actions.addAll([
          _bouton('Refuser', _refuser, secondaire: true),
          _bouton('Accepter', _accepter),
        ]);
      } else if (demande.statut == 'acceptee') {
        actions.add(_bouton('Démarrer l’intervention', () => _agir(
              () => _repository.demarrer(widget.demandeId),
              'Intervention démarrée.',
            )));
      } else if (demande.statut == 'en_cours') {
        actions.add(_bouton('Terminer l’intervention', _terminer));
      }
    } else {
      if (!demande.estCloturee) {
        actions.add(_bouton('Annuler la demande', _annuler, secondaire: true));
      }
      if (demande.estTerminee) {
        actions.add(_bouton('Noter l’artisan', _noter));
      }
    }

    if (actions.isEmpty) return null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(child: actions[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _bouton(String libelle, VoidCallback action, {bool secondaire = false}) {
    if (secondaire) {
      return SizedBox(
        height: 50,
        child: OutlinedButton(
          onPressed: _actionEnCours ? null : action,
          style: OutlinedButton.styleFrom(
            foregroundColor: MabokoCouleurs.danger,
            side: const BorderSide(color: MabokoCouleurs.danger),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(libelle, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _actionEnCours ? null : action,
        style: ElevatedButton.styleFrom(
          backgroundColor: MabokoCouleurs.secondaire,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: _actionEnCours
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
              )
            : Text(libelle, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

/// Notation d'une intervention terminée (§2.2).
class _DialogueNotation extends StatefulWidget {
  const _DialogueNotation();

  @override
  State<_DialogueNotation> createState() => _DialogueNotationState();
}

class _DialogueNotationState extends State<_DialogueNotation> {
  int _note = 5;
  final _commentaire = TextEditingController();

  @override
  void dispose() {
    _commentaire.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Noter l’artisan'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre avis aide les prochains clients à choisir.',
            style: TextStyle(fontSize: 13, color: MabokoCouleurs.texteSecondaire),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                constraints: const BoxConstraints(),
                onPressed: () => setState(() => _note = i + 1),
                icon: Icon(
                  _note > i ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 34,
                  color: MabokoCouleurs.accent,
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _commentaire,
            maxLines: 3,
            maxLength: 1500,
            decoration: const InputDecoration(
              labelText: 'Commentaire (facultatif)',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Revenir')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, (note: _note, commentaire: _commentaire.text.trim())),
          style: ElevatedButton.styleFrom(backgroundColor: MabokoCouleurs.secondaire),
          child: const Text('Publier mon avis', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
