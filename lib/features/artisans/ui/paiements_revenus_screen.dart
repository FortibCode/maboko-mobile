import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../../tableau_bord/data/tableau_bord_repository.dart';
import '../../tableau_bord/models/tableau_bord.dart';
import '../../tableau_bord/ui/graphique_revenus.dart';

/// Paiements et revenus (§5.2).
///
/// Vue synthétique de ce que l'artisan a gagné : total, mois courant,
/// douze derniers mois, détail des missions. Complète le tableau de bord
/// en donnant une lecture « comptable » hors de l'accueil.
class PaiementsRevenusScreen extends StatefulWidget {
  const PaiementsRevenusScreen({super.key});

  @override
  State<PaiementsRevenusScreen> createState() => _PaiementsRevenusScreenState();
}

class _PaiementsRevenusScreenState extends State<PaiementsRevenusScreen> {
  static const _repository = TableauBordRepository();

  TableauBord? _bord;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      final bord = await _repository.charger();
      if (!mounted) return;
      setState(() => _bord = bord);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreur = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Paiements et revenus'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
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
        children: [
          const SizedBox(height: 60),
          EtatErreur(message: _erreur!, onReessayer: _charger),
        ],
      );
    }

    if (_bord == null) return const ChargementEnCours();

    final bord = _bord!;

    if (bord.ficheManquante) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 60),
          EtatVide(
            icone: Icons.badge_outlined,
            titre: 'Fiche artisan incomplète',
            message: 'Complétez votre fiche pour voir vos revenus.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _cartePrincipale(bord),
        const SizedBox(height: 22),
        _section('Revenus des 12 derniers mois'),
        _carteGraphique(bord),
        const SizedBox(height: 22),
        _section('Détail des missions'),
        _carteCompteurs(bord),
        const SizedBox(height: 22),
        _section('Récapitulatif'),
        _carteRecap(bord),
        const SizedBox(height: 22),
        _encadre(),
      ],
    );
  }

  Widget _section(String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        titre,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.texteSecondaireMaboko,
          letterSpacing: .3,
        ),
      ),
    );
  }

  Widget _cartePrincipale(TableauBord bord) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [MabokoCouleurs.accent, MabokoCouleurs.secondaire],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.payments_rounded, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Revenus générés',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'maboko ${bord.plan ?? 'Gratuit'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formaterFcfa(bord.revenusTotal),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Dont ${formaterFcfa(bord.revenusMois)} ce mois-ci',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _carteGraphique(TableauBord bord) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: GraphiqueRevenus(serie: bord.revenusParMois),
    );
  }

  Widget _carteCompteurs(TableauBord bord) {
    return Row(
      children: [
        Expanded(
          child: _tuile(
            '${bord.compteurs.enAttente}',
            'À traiter',
            MabokoCouleurs.accent,
            Icons.hourglass_top_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tuile(
            '${bord.compteurs.enCours}',
            'En cours',
            MabokoCouleurs.secondaire,
            Icons.timelapse_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _tuile(
            '${bord.compteurs.terminees}',
            'Terminées',
            MabokoCouleurs.succes,
            Icons.check_circle_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _tuile(String valeur, String libelle, Color couleur, IconData icone) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Column(
        children: [
          Icon(icone, color: couleur, size: 20),
          const SizedBox(height: 8),
          Text(
            valeur,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: couleur),
          ),
          const SizedBox(height: 3),
          Text(
            libelle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: context.texteSecondaireMaboko),
          ),
        ],
      ),
    );
  }

  Widget _carteRecap(TableauBord bord) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Column(
        children: [
          _ligneRecap(
            icone: Icons.calendar_today_rounded,
            titre: 'Ce mois-ci',
            montant: bord.revenusMois,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ligneRecap(
            icone: Icons.all_inclusive_rounded,
            titre: 'Total cumulé',
            montant: bord.revenusTotal,
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ligneRecap(
            icone: Icons.emoji_events_rounded,
            titre: 'Missions terminées',
            valeur: '${bord.compteurs.terminees}',
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          _ligneRecap(
            icone: Icons.star_rounded,
            titre: 'Note moyenne',
            valeur: bord.nbAvis == 0 ? '—' : bord.noteMoyenne.toStringAsFixed(1),
            sousTitre: '${bord.nbAvis} avis',
          ),
        ],
      ),
    );
  }

  Widget _ligneRecap({
    required IconData icone,
    required String titre,
    double? montant,
    String? valeur,
    String? sousTitre,
  }) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: MabokoCouleurs.secondaire.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icone, size: 18, color: MabokoCouleurs.secondaire),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (sousTitre != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sousTitre,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.texteSecondaireMaboko,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            montant != null ? formaterFcfa(montant) : (valeur ?? '—'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: MabokoCouleurs.secondaire,
            ),
          ),
        ],
      ),
    );
  }

  Widget _encadre() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.teinteMaboko,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Les montants sont ceux des missions terminées et validées par '
              'le client. Les missions en cours n’apparaissent pas encore.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: context.texteSecondaireMaboko,
              ),
            ),
          ),
        ],
      ),
    );
  }
}