import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../../artisans/ui/artisan_profile_screen.dart';
import '../data/avis_repository.dart';

/// Historique des avis déposés par le client (§5.1.7).
///
/// Le compteur « Avis donnés » du profil existait depuis le début, mais il
/// n'y avait aucun moyen de voir le détail. Un client qui voulait modifier ou
/// simplement retrouver un avis n'avait aucune entrée.
class MesAvisScreen extends StatefulWidget {
  const MesAvisScreen({super.key});

  @override
  State<MesAvisScreen> createState() => _MesAvisScreenState();
}

class _MesAvisScreenState extends State<MesAvisScreen> {
  static const _repository = AvisRepository();

  List<MonAvis>? _avis;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      final liste = await _repository.mesAvis();
      if (!mounted) return;
      setState(() => _avis = liste);
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
        title: const Text('Mes avis'),
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

    if (_avis == null) return const ChargementEnCours();

    if (_avis!.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 60),
          EtatVide(
            icone: Icons.star_outline_rounded,
            titre: 'Aucun avis déposé',
            message: 'Vos avis sur les artisans apparaîtront ici après vos '
                'premières missions terminées.',
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _avis!.length,
      itemBuilder: (contexte, i) => _carte(_avis![i]),
    );
  }

  Widget _carte(MonAvis avis) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: avis.artisanId == 0
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtisanProfileScreen(artisanId: avis.artisanId),
                    ),
                  ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        avis.artisanNom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    Etoiles(note: avis.note.toDouble(), taille: 15),
                  ],
                ),
                if (avis.commentaire != null && avis.commentaire!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    avis.commentaire!,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: context.texteSecondaireMaboko,
                    ),
                  ),
                ],
                if (avis.publieLe != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _dateLisible(avis.publieLe!),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: context.texteSecondaireMaboko,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _dateLisible(DateTime date) {
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
    ];

    return 'Publié en ${mois[date.month - 1]} ${date.year}';
  }
}