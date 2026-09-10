import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/moyen_paiement_repository.dart';

/// Moyens de paiement enregistrés (§5.1.10).
class MoyensPaiementScreen extends StatefulWidget {
  const MoyensPaiementScreen({super.key});

  @override
  State<MoyensPaiementScreen> createState() => _MoyensPaiementScreenState();
}

class _MoyensPaiementScreenState extends State<MoyensPaiementScreen> {
  static const _depot = MoyenPaiementRepository();

  List<MoyenPaiement>? _moyens;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      final liste = await _depot.lister();
      if (!mounted) return;
      setState(() => _moyens = liste);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    }
  }

  Future<void> _ajouter() async {
    final ajoute = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (contexte) => const _FormulaireMoyen(),
    );

    if (ajoute == true) await _charger();
  }

  Future<void> _definirParDefaut(MoyenPaiement moyen) async {
    if (moyen.parDefaut) return;

    try {
      await _depot.definirParDefaut(moyen.id);
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      _informer(e.message, MabokoCouleurs.danger);
    }
  }

  Future<void> _retirer(MoyenPaiement moyen) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (contexte) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Retirer ce moyen de paiement ?'),
        content: Text('${moyen.nomOperateur} · ${moyen.telephoneMasque}'),
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
      await _depot.retirer(moyen.id);
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
      appBar: AppBar(
        title: const Text('Moyens de paiement'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouter,
        backgroundColor: MabokoCouleurs.secondaire,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ajouter', style: TextStyle(color: Colors.white)),
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

    if (_moyens == null) return const ChargementEnCours();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      children: [
        // Le rassurer explicitement : beaucoup hésitent à enregistrer un
        // numéro de paiement sans savoir ce qui en est fait.
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: MabokoCouleurs.succes.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield_outlined, color: MabokoCouleurs.succes, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Seuls l’opérateur et le numéro sont conservés. Chaque paiement '
                  'doit être confirmé sur votre téléphone avec votre code secret.',
                  style: TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (_moyens!.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 40),
            child: EtatVide(
              icone: Icons.account_balance_wallet_outlined,
              titre: 'Aucun moyen enregistré',
              message: 'Ajoutez votre numéro Mobile Money pour ne plus le saisir à chaque paiement.',
            ),
          )
        else
          ..._moyens!.map(_carte),
      ],
    );
  }

  Widget _carte(MoyenPaiement moyen) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: moyen.parDefaut
              ? MabokoCouleurs.secondaire
              : MabokoCouleurs.accent.withValues(alpha: 0.2),
          width: moyen.parDefaut ? 1.6 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        onTap: () => _definirParDefaut(moyen),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: MabokoCouleurs.secondaire.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.smartphone_rounded, color: MabokoCouleurs.secondaire),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                moyen.libelle?.isNotEmpty == true ? moyen.libelle! : moyen.nomOperateur,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
              ),
            ),
            if (moyen.parDefaut) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: MabokoCouleurs.secondaire,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Par défaut',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            '${moyen.nomOperateur} · ${moyen.telephoneMasque}',
            style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: MabokoCouleurs.danger),
          tooltip: 'Retirer',
          onPressed: () => _retirer(moyen),
        ),
      ),
    );
  }
}

/// Formulaire d'ajout, en feuille glissante.
class _FormulaireMoyen extends StatefulWidget {
  const _FormulaireMoyen();

  @override
  State<_FormulaireMoyen> createState() => _FormulaireMoyenState();
}

class _FormulaireMoyenState extends State<_FormulaireMoyen> {
  final _telephone = TextEditingController();
  final _libelle = TextEditingController();
  String _operateur = 'airtel';
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _telephone.dispose();
    _libelle.dispose();
    super.dispose();
  }

  /// Aligne la saisie sur le format attendu par l'API : +242 suivi de 06, 05
  /// ou 04 puis sept chiffres.
  String _formater(String saisie) {
    final propre = saisie.replaceAll(RegExp(r'\s+'), '').trim();
    if (propre.startsWith('+242')) return propre;
    if (propre.startsWith('242')) return '+$propre';
    if (propre.startsWith('0')) return '+242$propre';

    return propre.isEmpty ? propre : '+2420$propre';
  }

  Future<void> _enregistrer() async {
    final numero = _formater(_telephone.text);

    if (!RegExp(r'^\+2420[456]\d{7}$').hasMatch(numero)) {
      setState(() => _erreur = 'Numéro congolais attendu : 06, 05 ou 04 suivi de 7 chiffres.');

      return;
    }

    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      await const MoyenPaiementRepository().ajouter(
        operateur: _operateur,
        telephone: numero,
        libelle: _libelle.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.bordureMaboko,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Ajouter un moyen de paiement',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _choixOperateur('airtel', 'Airtel Money')),
                const SizedBox(width: 10),
                Expanded(child: _choixOperateur('mtn', 'MTN Mobile Money')),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _telephone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Numéro Mobile Money',
                hintText: '06 42 90 000',
                prefixIcon: Icon(Icons.smartphone_rounded),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _libelle,
              decoration: const InputDecoration(
                labelText: 'Nom (facultatif)',
                hintText: 'Ex : mon numéro principal',
                prefixIcon: Icon(Icons.label_outline_rounded),
                border: OutlineInputBorder(),
              ),
            ),

            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(
                _erreur!,
                style: const TextStyle(color: MabokoCouleurs.danger, fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _envoi ? null : _enregistrer,
                child: _envoi
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Enregistrer'),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _choixOperateur(String valeur, String libelle) {
    final actif = _operateur == valeur;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _operateur = valeur),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: actif ? MabokoCouleurs.secondaire.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko,
            width: actif ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              actif ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: actif ? MabokoCouleurs.secondaire : context.texteSecondaireMaboko,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                libelle,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: actif ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
