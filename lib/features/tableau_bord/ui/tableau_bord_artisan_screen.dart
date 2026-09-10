import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../../artisans/ui/fiche_artisan_screen.dart';
import '../../demandes/models/demande.dart';
import '../../demandes/ui/demande_detail_screen.dart';
import '../../demandes/ui/demandes_screen.dart';
import '../data/tableau_bord_repository.dart';
import '../models/tableau_bord.dart';
import 'graphique_revenus.dart';

/// Tableau de bord artisan (§5.2.1) : missions reçues, en cours et terminées,
/// revenus cumulés, puis la liste des dernières demandes à traiter.
///
/// Remplace l'écran « Mon Business », dont tous les chiffres étaient lus
/// dans le stockage local du téléphone et n'existaient donc que là.
class TableauBordArtisanScreen extends StatefulWidget {
  const TableauBordArtisanScreen({super.key, this.enTete});

  /// Barre posée au-dessus du contenu quand l'écran sert d'onglet d'accueil.
  ///
  /// Dans ce cas il n'a pas de barre de titre à lui : celle de la coquille
  /// suffit, et deux barres empilées mangeraient un tiers de l'écran.
  final Widget? enTete;

  @override
  State<TableauBordArtisanScreen> createState() => _TableauBordArtisanScreenState();
}

class _TableauBordArtisanScreenState extends State<TableauBordArtisanScreen> {
  static const _repository = TableauBordRepository();

  TableauBord? _bord;
  bool _chargement = true;
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
      final bord = await _repository.charger();
      if (!mounted) return;
      setState(() {
        _bord = bord;
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

  @override
  Widget build(BuildContext context) {
    if (widget.enTete != null) {
      return Container(
        color: context.fondMaboko,
        child: Column(
          children: [
            widget.enTete!,
            Expanded(child: _corps()),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Mon activité'),
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

    final bord = _bord!;

    if (bord.ficheManquante) {
      // Sans bouton, cet ecran etait une impasse : le message demandait de
      // completer la fiche sans offrir le moindre moyen de le faire.
      return EtatVide(
        icone: Icons.badge_outlined,
        titre: 'Votre fiche artisan est incomplète',
        message: 'Renseignez votre métier et votre zone d’intervention pour '
            'apparaître dans les recherches et recevoir des missions.',
        action: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: MabokoCouleurs.secondaire,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
          ),
          onPressed: () async {
            final cree = await Navigator.push<bool>(
              context,
              MaterialPageRoute(builder: (_) => const FicheArtisanScreen()),
            );
            if (cree == true) await _charger();
          },
          icon: const Icon(Icons.edit_outlined, size: 19),
          label: const Text('Compléter ma fiche',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }

    return RefreshIndicator(
      color: MabokoCouleurs.secondaire,
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _carteRevenus(bord),
          const SizedBox(height: 16),

          // Suivi graphique des revenus mensuels (§5.2.4). Le cahier le
          // demande explicitement ; seuls le total et le mois courant
          // etaient affiches jusqu'ici.
          _bloc(
            titre: 'Revenus des 12 derniers mois',
            enfant: GraphiqueRevenus(serie: bord.revenusParMois),
          ),
          const SizedBox(height: 16),

          _compteursMissions(bord),
          const SizedBox(height: 16),
          _reputation(bord),
          if (bord.badges.isNotEmpty) ...[
            const SizedBox(height: 16),
            _bloc(
              titre: 'Mes badges',
              enfant: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: bord.badges
                    .map<Widget>((b) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: context.teinteMaboko,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.55)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded,
                                  size: 15, color: MabokoCouleurs.accent),
                              const SizedBox(width: 6),
                              Text(
                                b.nom,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: context.texteFortMaboko,
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _demandesATraiter(bord),
        ],
      ),
    );
  }

  Widget _carteRevenus(TableauBord bord) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Revenus générés',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
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
          const SizedBox(height: 8),
          Text(
            formaterFcfa(bord.revenusTotal),
            style: const TextStyle(color: Colors.white, fontSize: 27, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Dont ${formaterFcfa(bord.revenusMois)} ce mois-ci',
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Widget _compteursMissions(TableauBord bord) {
    return Row(
      children: [
        Expanded(child: _tuile('${bord.compteurs.enAttente}', 'À traiter', MabokoCouleurs.accent)),
        const SizedBox(width: 10),
        Expanded(child: _tuile('${bord.compteurs.enCours}', 'En cours', MabokoCouleurs.secondaire)),
        const SizedBox(width: 10),
        Expanded(child: _tuile('${bord.compteurs.terminees}', 'Terminées', MabokoCouleurs.succes)),
      ],
    );
  }

  Widget _tuile(String valeur, String libelle, Color couleur) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: context.surfaceMaboko,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Column(
        children: [
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

  Widget _reputation(TableauBord bord) {
    return _bloc(
      titre: 'Ma réputation',
      enfant: Row(
        children: [
          Etoiles(note: bord.noteMoyenne, taille: 20),
          const SizedBox(width: 10),
          Text(
            bord.nbAvis == 0 ? 'Pas encore d’avis' : bord.noteMoyenne.toStringAsFixed(1),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 6),
          if (bord.nbAvis > 0)
            Text(
              'sur ${bord.nbAvis} avis',
              style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
            ),
        ],
      ),
    );
  }

  Widget _demandesATraiter(TableauBord bord) {
    return _bloc(
      titre: 'Demandes à traiter',
      action: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DemandesScreen(estArtisan: true)),
        ),
        child: const Text('Tout voir', style: TextStyle(color: MabokoCouleurs.secondaire)),
      ),
      enfant: bord.dernieresDemandes.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Aucune nouvelle demande. Les missions qui vous sont adressées apparaîtront ici.',
                style: TextStyle(color: context.texteSecondaireMaboko, fontSize: 13.5, height: 1.4),
              ),
            )
          : Column(children: bord.dernieresDemandes.map<Widget>(_ligneDemande).toList()),
    );
  }

  Widget _ligneDemande(Demande demande) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: context.teinteMaboko,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.assignment_outlined, size: 20, color: MabokoCouleurs.secondaire),
      ),
      title: Text(
        demande.titre,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${demande.clientNom ?? 'Client'} · ${formaterFcfa(demande.budgetEstime)}',
        style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: context.texteSecondaireMaboko),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DemandeDetailScreen(demandeId: demande.id, estArtisan: true),
          ),
        );
        await _charger();
      },
    );
  }

  Widget _bloc({required String titre, required Widget enfant, Widget? action}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: context.surfaceMaboko,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 10),
          enfant,
        ],
      ),
    );
  }
}
