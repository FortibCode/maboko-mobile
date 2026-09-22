import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/avis_recus_repository.dart';
import '../models/artisan.dart';

/// Avis reçus par l'artisan (§5.2).
///
/// L'artisan voit ici tout ce que les clients ont écrit sur lui : note
/// moyenne, répartition par étoiles, et chaque avis avec son auteur. Il
/// peut répondre à un avis pour remercier ou nuancer.
class AvisRecusScreen extends StatefulWidget {
  const AvisRecusScreen({super.key});

  @override
  State<AvisRecusScreen> createState() => _AvisRecusScreenState();
}

class _AvisRecusScreenState extends State<AvisRecusScreen> {
  static const _repository = AvisRecusRepository();

  AvisRecus? _donnees;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      final donnees = await _repository.charger();
      if (!mounted) return;
      setState(() => _donnees = donnees);
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
        title: const Text('Avis reçus'),
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

    if (_donnees == null) return const ChargementEnCours();

    if (_donnees!.avis.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 60),
          EtatVide(
            icone: Icons.star_outline_rounded,
            titre: 'Pas encore d’avis',
            message: 'Les avis des clients apparaîtront ici après vos '
                'premières missions terminées.',
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _blocStatistiques(_donnees!),
        const SizedBox(height: 20),
        _titreSection('Tous les avis (${_donnees!.avis.length})'),
        const SizedBox(height: 10),
        ..._donnees!.avis.map<Widget>(_carteAvis),
      ],
    );
  }

  Widget _titreSection(String titre) {
    return Text(
      titre,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.texteSecondaireMaboko,
        letterSpacing: .3,
      ),
    );
  }

  Widget _blocStatistiques(AvisRecus donnees) {
    final repartition = donnees.repartition;
    final max = repartition.values.fold<int>(1, (a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Côté gauche : note moyenne
          Column(
            children: [
              Text(
                donnees.noteMoyenne.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Etoiles(note: donnees.noteMoyenne, taille: 18),
              const SizedBox(height: 6),
              Text(
                '${donnees.nbAvis} avis',
                style: TextStyle(
                  fontSize: 12.5,
                  color: context.texteSecondaireMaboko,
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          // Côté droit : barres de répartition
          Expanded(
            child: Column(
              children: [
                for (int etoiles = 5; etoiles >= 1; etoiles--)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 12,
                          child: Text(
                            '$etoiles',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: context.texteSecondaireMaboko,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.star_rounded,
                            size: 13, color: Colors.amber.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (repartition[etoiles] ?? 0) / max,
                              minHeight: 6,
                              backgroundColor: context.bordureMaboko,
                              valueColor: AlwaysStoppedAnimation(
                                Colors.amber.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 20,
                          child: Text(
                            '${repartition[etoiles] ?? 0}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.texteSecondaireMaboko,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteAvis(Avis avis) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: MabokoCouleurs.secondaire.withValues(alpha: 0.12),
                child: Text(
                  _initiales(avis.auteur),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: MabokoCouleurs.secondaire,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avis.auteur ?? 'Client Maboko',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Etoiles(note: avis.note.toDouble(), taille: 12),
                        if (avis.publieLe != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '· ${_dateCourte(avis.publieLe!)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: context.texteSecondaireMaboko,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (avis.commentaire != null && avis.commentaire!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              avis.commentaire!,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: context.texteFortMaboko,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _initiales(String? nom) {
    if (nom == null || nom.trim().isEmpty) return '?';
    final parties = nom.trim().split(RegExp(r'\s+'));
    if (parties.length == 1) return parties.first[0].toUpperCase();
    return '${parties.first[0]}${parties.last[0]}'.toUpperCase();
  }

  String _dateCourte(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inDays < 1) return 'aujourd’hui';
    if (difference.inDays == 1) return 'hier';
    if (difference.inDays < 7) return 'il y a ${difference.inDays} j';
    if (difference.inDays < 30) return 'il y a ${(difference.inDays / 7).floor()} sem.';
    if (difference.inDays < 365) return 'il y a ${(difference.inDays / 30).floor()} mois';

    return '${date.day}/${date.month}/${date.year}';
  }
}