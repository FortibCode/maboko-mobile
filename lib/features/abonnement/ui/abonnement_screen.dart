import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../../../services/storage_service.dart';
import '../data/abonnement_repository.dart';
import '../models/plan.dart';
import 'paiement_sheet.dart';

/// Abonnement de l'artisan (§5.2.4) : formule en cours, comparaison des
/// quatre offres et souscription par Mobile Money.
///
/// Remplace l'écran statique qui affichait « maboko Pro » en dur, sans
/// aucun lien avec le compte.
class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({super.key});

  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen> {
  static const _repository = AbonnementRepository();

  List<Plan> _plans = const [];
  AbonnementActuel? _actuel;
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      final resultats = await Future.wait([
        _repository.plans(),
        _repository.actuel(),
      ]);

      if (!mounted) return;
      setState(() {
        _plans = resultats[0] as List<Plan>;
        _actuel = resultats[1] as AbonnementActuel;
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

  Future<void> _souscrire(Plan plan) async {
    final telephone = await StorageService.getUserTelephone();
    if (!mounted) return;

    final resultat = await showModalBottomSheet<({bool reussi, String message})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PaiementSheet(plan: plan, telephoneParDefaut: telephone),
    );

    if (resultat == null || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(resultat.message),
        backgroundColor: resultat.reussi ? MabokoCouleurs.succes : MabokoCouleurs.danger,
      ),
    );

    if (resultat.reussi) await _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabokoCouleurs.fond,
      appBar: AppBar(
        title: const Text('Mon abonnement'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _corps(),
    );
  }

  Widget _corps() {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null) return EtatErreur(message: _erreur!, onReessayer: _charger);

    final actuel = _actuel!;

    return RefreshIndicator(
      color: MabokoCouleurs.secondaire,
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _carteFormuleActuelle(actuel),
          const SizedBox(height: 22),
          const Text(
            'Changer de formule',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Une formule supérieure remonte votre profil dans les résultats de recherche.',
            style: TextStyle(fontSize: 12.5, color: MabokoCouleurs.texteSecondaire),
          ),
          const SizedBox(height: 14),
          ..._plans.map((plan) => _cartePlan(plan, actuel.plan.slug == plan.slug)),
        ],
      ),
    );
  }

  Widget _carteFormuleActuelle(AbonnementActuel actuel) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [MabokoCouleurs.accent, MabokoCouleurs.secondaire],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Formule en cours', style: TextStyle(color: Colors.white70, fontSize: 12.5)),
          const SizedBox(height: 6),
          Text(
            'maboko ${actuel.plan.nom}',
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text(
                'Visibilité × ${actuel.plan.boostClassement.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white70, fontSize: 12.5),
              ),
            ],
          ),
          if (actuel.finLe != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.event_outlined, size: 16, color: Colors.white70),
                const SizedBox(width: 6),
                Text(
                  actuel.renouvellementAuto
                      ? 'Se renouvelle le ${_jolieDate(actuel.finLe!)}'
                      : 'Prend fin le ${_jolieDate(actuel.finLe!)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _cartePlan(Plan plan, bool estActuel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MabokoCouleurs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: estActuel ? MabokoCouleurs.secondaire : MabokoCouleurs.bordure,
          width: estActuel ? 1.6 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(plan.nom, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        if (estActuel) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: MabokoCouleurs.secondaire,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'ACTUELLE',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (plan.description != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        plan.description!,
                        style: const TextStyle(fontSize: 12.5, color: MabokoCouleurs.texteSecondaire, height: 1.35),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    plan.estGratuit ? 'Gratuit' : formaterFcfa(plan.prixMensuel),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: MabokoCouleurs.secondaire),
                  ),
                  if (!plan.estGratuit)
                    const Text('par mois', style: TextStyle(fontSize: 10.5, color: MabokoCouleurs.texteSecondaire)),
                ],
              ),
            ],
          ),
          if (plan.avantages.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...plan.avantages.map(
              (avantage) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_rounded, size: 15, color: MabokoCouleurs.succes),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(avantage, style: const TextStyle(fontSize: 12.5, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (!estActuel && !plan.estGratuit) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => _souscrire(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: MabokoCouleurs.secondaire,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Choisir cette formule', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _jolieDate(String iso) {
    final date = DateTime.tryParse(iso);
    if (date == null) return iso;

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
