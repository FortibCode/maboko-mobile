import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../artisans/ui/fiche_artisan_screen.dart';
import '../data/comptes_repository.dart';
import 'associer_compte_screen.dart';
import 'modifier_profil_screen.dart';
import 'nouveau_profil_screen.dart';
import 'selecteur_comptes.dart';

/// « Gérer mes comptes » : consulter, ajouter, associer, changer le compte
/// principal, retirer, réactiver ou supprimer.
///
/// Retirer un compte l'archive sans rien effacer ; la suppression définitive
/// est un parcours distinct, avec mot de passe et confirmation.
class GererComptesScreen extends StatefulWidget {
  const GererComptesScreen({super.key});

  @override
  State<GererComptesScreen> createState() => _GererComptesScreenState();
}

enum _Action { ouvrir, modifierProfil, modifierFiche, principal, retirer, supprimer }

class _GererComptesScreenState extends State<GererComptesScreen> {
  static const _depot = ComptesRepository();

  late Future<ListeComptes> _liste = _depot.lister();
  bool _operation = false;

  void _recharger() => setState(() => _liste = _depot.lister());

  void _informer(String message, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: erreur ? MabokoCouleurs.danger : MabokoCouleurs.succes,
    ));
  }

  /// Exécute une opération en bloquant les autres, et gère les erreurs API.
  Future<void> _executer(Future<void> Function() operation) async {
    setState(() => _operation = true);
    try {
      await operation();
    } on ApiException catch (e) {
      if (mounted) _informer(e.message, erreur: true);
    } finally {
      if (mounted) setState(() => _operation = false);
    }
  }

  /// Après archivage ou suppression du compte ouvert, l'API rend une session
  /// sur le compte principal : l'application s'y rouvre.
  Future<void> _suivre(SessionCompte? session, String message) async {
    if (!mounted) return;
    if (session != null) {
      await ouvrirSessionCompte(context, session);
      return;
    }
    _informer(message);
    _recharger();
  }

  Future<void> _agir(_Action action, CompteFamille compte) async {
    switch (action) {
      case _Action.ouvrir:
        await basculerVersCompte(context, compte);
      case _Action.modifierProfil:
        await Navigator.push(context, MaterialPageRoute(builder: (_) => const ModifierProfilScreen()));
        _recharger();
      case _Action.modifierFiche:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FicheArtisanScreen(modification: true)),
        );
        _recharger();
      case _Action.principal:
        final motDePasse = await _demanderMotDePasse(
          titre: 'Faire de « ${compte.nomComplet} » le compte principal ?',
          explication: 'Il portera la connexion de tous vos comptes, avec le même numéro, '
              'le même email et le même mot de passe.',
          action: 'Confirmer',
        );
        if (motDePasse == null) return;
        await _executer(() async {
          await _depot.definirPrincipal(compte.id, motDePasse: motDePasse);
          if (!mounted) return;
          _informer('« ${compte.nomComplet} » est votre compte principal.');
          _recharger();
        });
      case _Action.retirer:
        final confirme = await _confirmer(
          titre: 'Retirer « ${compte.nomComplet} » ?',
          explication: 'Il disparaît de vos comptes et ne reçoit plus de nouvelles demandes. '
              'Ses commandes, avis et messages sont conservés, et vous pourrez le réactiver.',
          action: 'Retirer',
        );
        if (!confirme) return;
        await _executer(() async {
          final session = await _depot.archiver(compte.id);
          await _suivre(session, 'Compte retiré. Ses données sont conservées.');
        });
      case _Action.supprimer:
        final motDePasse = await _demanderMotDePasse(
          titre: 'Supprimer définitivement « ${compte.nomComplet} » ?',
          explication: 'Ses informations personnelles, publications et pièces sont effacées. '
              'Les traces comptables sont conservées de façon anonyme. Cette action est irréversible.',
          action: 'Supprimer définitivement',
          danger: true,
        );
        if (motDePasse == null) return;
        await _executer(() async {
          final session = await _depot.supprimer(compte.id, motDePasse: motDePasse);
          await _suivre(session, 'Compte supprimé définitivement.');
        });
    }
  }

  Future<void> _reactiver(CompteFamille compte) => _executer(() async {
        await _depot.reactiver(compte.id);
        if (!mounted) return;
        _informer('« ${compte.nomComplet} » est de nouveau actif.');
        _recharger();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gérer mes comptes')),
      body: FutureBuilder<ListeComptes>(
        future: _liste,
        builder: (context, instantane) {
          if (instantane.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (instantane.hasError) {
            final erreur = instantane.error;
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(erreur is ApiException ? erreur.message : 'Comptes indisponibles.'),
                  TextButton(onPressed: _recharger, child: const Text('Réessayer')),
                ],
              ),
            );
          }

          final liste = instantane.data!;

          return AbsorbPointer(
            absorbing: _operation,
            child: RefreshIndicator(
              onRefresh: () async => _recharger(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  if (_operation) const LinearProgressIndicator(),
                  _titre('Vos comptes', '${liste.comptes.length} sur ${liste.maximum}'),
                  _carte([
                    for (final compte in liste.comptes)
                      LigneCompte(compte: compte, trailing: _menu(compte)),
                  ]),
                  const SizedBox(height: 16),
                  if (liste.peutAjouter) ...[
                    _bouton(Icons.add_rounded, 'Créer un nouveau compte', () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const NouveauProfilScreen()));
                      _recharger();
                    }),
                    const SizedBox(height: 10),
                    _bouton(Icons.link_rounded, 'Associer un compte existant', () async {
                      final associe = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(builder: (_) => const AssocierCompteScreen()),
                      );
                      if (associe == true && mounted) {
                        _informer('Compte rattaché.');
                        _recharger();
                      }
                    }),
                  ] else
                    Text(
                      'Vous avez atteint le maximum de ${liste.maximum} comptes actifs. '
                      'Retirez-en un pour en ajouter un autre.',
                      style: TextStyle(color: context.texteSecondaireMaboko),
                    ),
                  if (liste.archives.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    _titre('Comptes retirés', 'Données conservées'),
                    _carte([
                      for (final compte in liste.archives)
                        LigneCompte(
                          compte: compte,
                          trailing: TextButton(
                            onPressed: liste.peutAjouter ? () => _reactiver(compte) : null,
                            child: const Text('Réactiver'),
                          ),
                        ),
                    ]),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _menu(CompteFamille compte) {
    return PopupMenuButton<_Action>(
      tooltip: 'Actions',
      icon: compte.estActif
          ? const Icon(Icons.check_circle_rounded, color: MabokoCouleurs.secondaire)
          : const Icon(Icons.more_vert_rounded),
      onSelected: (action) => _agir(action, compte),
      itemBuilder: (_) => [
        if (!compte.estActif && !compte.suspendu)
          const PopupMenuItem(value: _Action.ouvrir, child: Text('Ouvrir ce compte')),
        // Les écrans de modification agissent sur le compte ouvert.
        if (compte.estActif) ...[
          const PopupMenuItem(value: _Action.modifierProfil, child: Text('Modifier le nom et la photo')),
          const PopupMenuItem(value: _Action.modifierFiche, child: Text('Modifier métiers et zone')),
        ],
        if (!compte.estPrincipal) ...[
          const PopupMenuItem(value: _Action.principal, child: Text('Définir comme compte principal')),
          const PopupMenuItem(value: _Action.retirer, child: Text('Retirer de mes comptes')),
          const PopupMenuItem(
            value: _Action.supprimer,
            child: Text('Supprimer définitivement', style: TextStyle(color: MabokoCouleurs.danger)),
          ),
        ],
      ],
    );
  }

  Widget _titre(String titre, String detail) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Row(
          children: [
            Text(titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(detail, style: TextStyle(color: context.texteSecondaireMaboko, fontSize: 12.5)),
          ],
        ),
      );

  Widget _carte(List<Widget> lignes) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: context.bordureMaboko),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(children: lignes),
      );

  Widget _bouton(IconData icone, String libelle, VoidCallback onPressed) => SizedBox(
        height: 48,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icone),
          label: Text(libelle),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          ),
        ),
      );

  Future<bool> _confirmer({required String titre, required String explication, required String action}) async {
    final reponse = await showDialog<bool>(
      context: context,
      builder: (contexte) => AlertDialog(
        title: Text(titre),
        content: Text(explication),
        actions: [
          TextButton(onPressed: () => Navigator.pop(contexte, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(contexte, true), child: Text(action)),
        ],
      ),
    );
    return reponse == true;
  }

  /// Opérations sensibles : le mot de passe de la personne est redemandé.
  Future<String?> _demanderMotDePasse({
    required String titre,
    required String explication,
    required String action,
    bool danger = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _DialogueMotDePasse(titre: titre, explication: explication, action: action, danger: danger),
    );
  }
}

class _DialogueMotDePasse extends StatefulWidget {
  const _DialogueMotDePasse({
    required this.titre,
    required this.explication,
    required this.action,
    required this.danger,
  });

  final String titre;
  final String explication;
  final String action;
  final bool danger;

  @override
  State<_DialogueMotDePasse> createState() => _DialogueMotDePasseState();
}

class _DialogueMotDePasseState extends State<_DialogueMotDePasse> {
  final _motDePasse = TextEditingController();

  @override
  void dispose() {
    _motDePasse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titre),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.explication),
          const SizedBox(height: 14),
          TextField(
            controller: _motDePasse,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Votre mot de passe', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: _motDePasse.text.isEmpty ? null : () => Navigator.pop(context, _motDePasse.text),
          style: widget.danger ? FilledButton.styleFrom(backgroundColor: MabokoCouleurs.danger) : null,
          child: Text(widget.action),
        ),
      ],
    );
  }
}
