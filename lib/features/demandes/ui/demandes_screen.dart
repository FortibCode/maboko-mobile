import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/demande_repository.dart';
import '../models/demande.dart';
import 'demande_detail_screen.dart';

/// Demandes de devis.
///
/// Pour un client : ses demandes envoyées (§5.1.10).
/// Pour un artisan : les missions reçues, classées En attente / En cours /
/// Terminées (§5.2.2). L'API distingue les deux selon le rôle du compte.
class DemandesScreen extends StatefulWidget {
  const DemandesScreen({super.key, required this.estArtisan});

  final bool estArtisan;

  @override
  State<DemandesScreen> createState() => _DemandesScreenState();
}

class _DemandesScreenState extends State<DemandesScreen> with SingleTickerProviderStateMixin {
  static const _repository = DemandeRepository();

  static const _onglets = [
    (libelle: 'En attente', statuts: ['en_attente']),
    (libelle: 'En cours', statuts: ['acceptee', 'en_cours']),
    (libelle: 'Terminées', statuts: ['terminee', 'refusee', 'annulee']),
  ];

  late final TabController _tabs = TabController(length: _onglets.length, vsync: this);

  List<Demande> _demandes = const [];
  bool _chargement = true;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });

    try {
      final demandes = await _repository.lister();
      if (!mounted) return;
      setState(() {
        _demandes = demandes;
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

  List<Demande> _pourOnglet(int index) {
    final statuts = _onglets[index].statuts;

    return _demandes.where((d) => statuts.contains(d.statut)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MabokoCouleurs.fond,
      appBar: AppBar(
        title: Text(widget.estArtisan ? 'Missions reçues' : 'Mes demandes'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            for (var i = 0; i < _onglets.length; i++)
              Tab(
                text: _chargement
                    ? _onglets[i].libelle
                    : '${_onglets[i].libelle} (${_pourOnglet(i).length})',
              ),
          ],
        ),
      ),
      body: _corps(),
    );
  }

  Widget _corps() {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null) return EtatErreur(message: _erreur!, onReessayer: _charger);

    return TabBarView(
      controller: _tabs,
      children: List.generate(_onglets.length, (i) => _liste(i)),
    );
  }

  Widget _liste(int index) {
    final demandes = _pourOnglet(index);

    if (demandes.isEmpty) {
      return RefreshIndicator(
        color: MabokoCouleurs.secondaire,
        onRefresh: _charger,
        child: ListView(
          children: [
            SizedBox(
              height: 380,
              child: EtatVide(
                icone: Icons.inbox_outlined,
                titre: 'Rien ici pour l’instant',
                message: widget.estArtisan
                    ? 'Aucune mission dans cette catégorie. Les nouvelles demandes arrivent ici.'
                    : 'Aucune demande dans cette catégorie. Trouvez un artisan depuis l’onglet Découvrir.',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: MabokoCouleurs.secondaire,
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: demandes.length,
        itemBuilder: (context, i) => _CarteDemande(
          demande: demandes[i],
          estArtisan: widget.estArtisan,
          onOuvrir: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DemandeDetailScreen(
                  demandeId: demandes[i].id,
                  estArtisan: widget.estArtisan,
                ),
              ),
            );
            await _charger();
          },
        ),
      ),
    );
  }
}

class _CarteDemande extends StatelessWidget {
  const _CarteDemande({
    required this.demande,
    required this.estArtisan,
    required this.onOuvrir,
  });

  final Demande demande;
  final bool estArtisan;
  final VoidCallback onOuvrir;

  @override
  Widget build(BuildContext context) {
    final contrepartie = estArtisan ? demande.clientNom : demande.artisanNom;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MabokoCouleurs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MabokoCouleurs.bordure),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onOuvrir,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        demande.titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PastilleStatut(statut: demande.statut),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  demande.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: MabokoCouleurs.texteSecondaire, height: 1.4),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: MabokoCouleurs.texteSecondaire),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        demande.adresse,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: MabokoCouleurs.texteSecondaire),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (contrepartie != null && contrepartie.isNotEmpty) ...[
                      Icon(
                        estArtisan ? Icons.person_outline : Icons.handyman_outlined,
                        size: 14,
                        color: MabokoCouleurs.secondaire,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contrepartie,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      formaterFcfa(demande.montantFinal ?? demande.montantPropose ?? demande.budgetEstime),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: MabokoCouleurs.principale,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
