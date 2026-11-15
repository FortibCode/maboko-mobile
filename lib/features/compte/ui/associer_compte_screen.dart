import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../data/comptes_repository.dart';
import 'selecteur_comptes.dart';

/// Rattache un compte artisan existant à ses comptes.
///
/// Deux preuves de propriété : le mot de passe de ce compte, puis un code
/// envoyé par SMS à son numéro. Une confirmation explicite précède le
/// rattachement ; les comptes ne fusionnent jamais.
class AssocierCompteScreen extends StatefulWidget {
  const AssocierCompteScreen({super.key});

  /// Même règle que l'écran de connexion : 06xxxxxxx devient +24206xxxxxxx.
  static String normaliserIdentifiant(String saisie) {
    final valeur = saisie.trim();
    if (RegExp(r'^0[456]\d{7}$').hasMatch(valeur)) return '+242$valeur';
    if (RegExp(r'^[456]\d{7}$').hasMatch(valeur)) return '+2420$valeur';
    return valeur;
  }

  @override
  State<AssocierCompteScreen> createState() => _AssocierCompteScreenState();
}

class _AssocierCompteScreenState extends State<AssocierCompteScreen> {
  static const _depot = ComptesRepository();

  final _identifiant = TextEditingController();
  final _motDePasse = TextEditingController();
  final _code = TextEditingController();

  DemandeAssociation? _demande;
  bool _confirme = false;
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _identifiant.dispose();
    _motDePasse.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _verifier() async {
    if (_identifiant.text.trim().isEmpty || _motDePasse.text.isEmpty) {
      setState(() => _erreur = 'Saisissez le numéro ou l’email du compte, et son mot de passe.');
      return;
    }

    await _envoyer(() async {
      final demande = await _depot.demanderAssociation(
        identifiant: AssocierCompteScreen.normaliserIdentifiant(_identifiant.text),
        motDePasse: _motDePasse.text,
      );
      setState(() => _demande = demande);
    });
  }

  Future<void> _rattacher() async {
    final demande = _demande!;

    await _envoyer(() async {
      await _depot.confirmerAssociation(compteId: demande.compte.id, code: _code.text.trim());
      if (mounted) Navigator.pop(context, true);
    });
  }

  Future<void> _envoyer(Future<void> Function() action) async {
    setState(() {
      _envoi = true;
      _erreur = null;
    });
    try {
      await action();
    } on ApiException catch (e) {
      if (mounted) setState(() => _erreur = e.message);
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demande = _demande;

    return Scaffold(
      appBar: AppBar(title: const Text('Associer un compte')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: demande == null ? _etapeIdentifiants() : _etapeConfirmation(demande),
        ),
      ),
    );
  }

  List<Widget> _etapeIdentifiants() => [
        Text(
          'Connectez-vous au compte artisan à rattacher. Un code sera envoyé à son numéro '
          'pour vérifier qu’il vous appartient.',
          style: TextStyle(color: context.texteSecondaireMaboko, height: 1.4),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _identifiant,
          keyboardType: TextInputType.emailAddress,
          decoration: _decoration('Numéro ou email du compte'),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _motDePasse,
          obscureText: true,
          decoration: _decoration('Mot de passe de ce compte'),
          onSubmitted: (_) => _envoi ? null : _verifier(),
        ),
        ..._erreurEtBouton('Continuer', _verifier),
      ];

  List<Widget> _etapeConfirmation(DemandeAssociation demande) => [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: context.bordureMaboko),
            borderRadius: BorderRadius.circular(18),
          ),
          child: LigneCompte(compte: demande.compte),
        ),
        const SizedBox(height: 18),
        Text(
          'Code envoyé au ${demande.telephoneMasque}.'
          '${demande.codeDeveloppement == null ? '' : ' (Développement : ${demande.codeDeveloppement})'}',
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: _decoration('Code à 6 chiffres'),
          onChanged: (_) => setState(() {}),
        ),
        CheckboxListTile(
          value: _confirme,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (valeur) => setState(() => _confirme = valeur ?? false),
          title: const Text(
            'Ce compte m’appartient. Je veux le rattacher à mes comptes : il se connectera '
            'désormais par mon compte principal, avec mon numéro et mon mot de passe.',
            style: TextStyle(fontSize: 13.5),
          ),
        ),
        ..._erreurEtBouton(
          'Rattacher ce compte',
          _confirme && _code.text.trim().length == 6 ? _rattacher : null,
        ),
      ];

  List<Widget> _erreurEtBouton(String libelle, VoidCallback? action) => [
        if (_erreur != null) ...[
          const SizedBox(height: 10),
          Text(_erreur!, style: const TextStyle(color: MabokoCouleurs.danger)),
        ],
        const SizedBox(height: 18),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: _envoi ? null : action,
            style: FilledButton.styleFrom(
              backgroundColor: MabokoCouleurs.secondaire,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            ),
            child: _envoi
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : Text(libelle, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ];

  InputDecoration _decoration(String libelle) => InputDecoration(
        labelText: libelle,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );
}
