import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../data/abonnement_repository.dart';
import '../models/plan.dart';

/// Souscription et paiement Mobile Money (§4.5).
///
/// Le paiement n'est pas immédiat : l'opérateur envoie une demande de
/// confirmation sur le téléphone du client. L'écran suit la transaction
/// jusqu'à son issue, sans laisser l'utilisateur devant un écran figé.
class PaiementSheet extends StatefulWidget {
  const PaiementSheet({super.key, required this.plan, required this.telephoneParDefaut});

  final Plan plan;
  final String? telephoneParDefaut;

  @override
  State<PaiementSheet> createState() => _PaiementSheetState();
}

class _PaiementSheetState extends State<PaiementSheet> {
  static const _repository = AbonnementRepository();
  static const _delaiSuivi = Duration(seconds: 4);
  static const _tentativesMax = 20;

  late final TextEditingController _telephone =
      TextEditingController(text: widget.telephoneParDefaut ?? '+242');

  String _periodicite = 'mensuel';
  String _operateur = 'mtn';
  bool _enCours = false;
  String? _etape;
  Timer? _suivi;
  int _tentatives = 0;

  @override
  void dispose() {
    _suivi?.cancel();
    _telephone.dispose();
    super.dispose();
  }

  double get _montant =>
      _periodicite == 'annuel' ? widget.plan.prixAnnuel : widget.plan.prixMensuel;

  Future<void> _souscrire() async {
    final telephone = _telephone.text.trim();

    if (!RegExp(r'^\+2420[456]\d{7}$').hasMatch(telephone)) {
      _informer('Numéro invalide : +242 suivi de 06, 05 ou 04 puis 7 chiffres.', MabokoCouleurs.danger);

      return;
    }

    setState(() {
      _enCours = true;
      _etape = 'Envoi de la demande à ${_operateur.toUpperCase()}…';
    });

    try {
      final resultat = await _repository.souscrire(
        plan: widget.plan.slug,
        periodicite: _periodicite,
        operateur: _operateur,
        telephone: telephone,
      );

      if (!mounted) return;

      final transaction = resultat.transaction;

      if (transaction == null || transaction.estReussie) {
        _terminer(reussi: true, message: resultat.message);

        return;
      }

      if (transaction.aEchoue) {
        _terminer(reussi: false, message: transaction.motifEchec ?? resultat.message);

        return;
      }

      // En attente : le client doit confirmer sur son téléphone.
      setState(() => _etape = 'Confirmez le paiement sur votre téléphone…');
      _lancerSuivi(transaction.reference);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _enCours = false;
        _etape = null;
      });
      _informer(e.message, MabokoCouleurs.danger);
    }
  }

  void _lancerSuivi(String reference) {
    _suivi?.cancel();
    _tentatives = 0;

    _suivi = Timer.periodic(_delaiSuivi, (minuterie) async {
      _tentatives++;

      if (_tentatives > _tentativesMax) {
        minuterie.cancel();
        if (!mounted) return;
        setState(() {
          _enCours = false;
          _etape = null;
        });
        _informer(
          'Sans réponse de l’opérateur. Votre abonnement s’activera dès la '
          'confirmation du paiement.',
          MabokoCouleurs.accent,
        );

        return;
      }

      try {
        final transaction = await _repository.suivre(reference);
        if (!mounted) return;

        if (transaction.estReussie) {
          minuterie.cancel();
          _terminer(reussi: true, message: 'Paiement confirmé, votre abonnement est actif.');
        } else if (transaction.aEchoue) {
          minuterie.cancel();
          _terminer(reussi: false, message: transaction.motifEchec ?? 'Le paiement a échoué.');
        }
      } on ApiException {
        // Une interrogation qui échoue n'interrompt pas le suivi : la
        // suivante réessaiera.
      }
    });
  }

  void _terminer({required bool reussi, required String message}) {
    _suivi?.cancel();
    Navigator.pop(context, (reussi: reussi, message: message));
  }

  void _informer(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: couleur),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: context.fondMaboko,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: context.bordureMaboko,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              'Souscrire à ${widget.plan.nom}',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 18),
            _choixPeriodicite(),
            const SizedBox(height: 18),
            const Text('Opérateur', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _carteOperateur('mtn', 'MTN MoMo')),
                const SizedBox(width: 10),
                Expanded(child: _carteOperateur('airtel', 'Airtel Money')),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _telephone,
              keyboardType: TextInputType.phone,
              enabled: !_enCours,
              decoration: InputDecoration(
                labelText: 'Numéro à débiter',
                hintText: '+242061234567',
                prefixIcon: const Icon(Icons.phone_android, color: MabokoCouleurs.secondaire),
                filled: true,
                fillColor: context.surfaceMaboko,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: context.bordureMaboko),
                ),
              ),
            ),
            if (_etape != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MabokoCouleurs.secondaire),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _etape!,
                      style: TextStyle(fontSize: 13, color: context.texteSecondaireMaboko),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enCours ? null : _souscrire,
                style: ElevatedButton.styleFrom(
                  backgroundColor: MabokoCouleurs.secondaire,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  'Payer ${formaterFcfa(_montant)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choixPeriodicite() {
    final economie = widget.plan.economieAnnuelle;

    return Row(
      children: [
        Expanded(
          child: _carteChoix(
            actif: _periodicite == 'mensuel',
            titre: 'Mensuel',
            sousTitre: formaterFcfa(widget.plan.prixMensuel),
            onTap: () => setState(() => _periodicite = 'mensuel'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _carteChoix(
            actif: _periodicite == 'annuel',
            titre: 'Annuel',
            sousTitre: formaterFcfa(widget.plan.prixAnnuel),
            badge: economie > 0 ? '− ${formaterFcfa(economie)}' : null,
            onTap: () => setState(() => _periodicite = 'annuel'),
          ),
        ),
      ],
    );
  }

  Widget _carteOperateur(String valeur, String libelle) {
    return _carteChoix(
      actif: _operateur == valeur,
      titre: libelle,
      onTap: () => setState(() => _operateur = valeur),
    );
  }

  Widget _carteChoix({
    required bool actif,
    required String titre,
    String? sousTitre,
    String? badge,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _enCours ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: actif ? MabokoCouleurs.secondaire.withValues(alpha: 0.1) : context.surfaceMaboko,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko,
            width: actif ? 1.6 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              style: TextStyle(
                fontWeight: actif ? FontWeight.bold : FontWeight.w600,
                fontSize: 14,
                color: actif ? MabokoCouleurs.secondaire : MabokoCouleurs.principale,
              ),
            ),
            if (sousTitre != null) ...[
              const SizedBox(height: 2),
              Text(
                sousTitre,
                style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko),
              ),
            ],
            if (badge != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: MabokoCouleurs.succes.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: MabokoCouleurs.succes,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
