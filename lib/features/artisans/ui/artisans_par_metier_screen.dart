import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/artisan_repository.dart';
import '../models/artisan.dart';
import 'carte_artisan.dart';

/// Résultats de la recherche d'artisans pour un métier donné (§4.1).
class ArtisansParMetierScreen extends StatefulWidget {
  const ArtisansParMetierScreen({super.key, required this.slugMetier, required this.titre});

  final String slugMetier;
  final String titre;

  @override
  State<ArtisansParMetierScreen> createState() => _ArtisansParMetierScreenState();
}

class _ArtisansParMetierScreenState extends State<ArtisansParMetierScreen> {
  static const _repository = ArtisanRepository();

  late FiltresArtisan _filtres = FiltresArtisan(metier: widget.slugMetier);

  List<Artisan> _artisans = const [];
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
      final artisans = await _repository.rechercher(_filtres);
      if (!mounted) return;
      setState(() {
        _artisans = artisans;
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

  void _appliquer(FiltresArtisan filtres) {
    setState(() => _filtres = filtres);
    _charger();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: Text(widget.titre),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _barreFiltres(),
          Expanded(child: _corps()),
        ],
      ),
    );
  }

  Widget _barreFiltres() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        children: [
          _puce(
            libelle: 'Mieux notés',
            actif: _filtres.tri == 'note',
            onTap: () => _appliquer(_filtres.copierAvec(tri: _filtres.tri == 'note' ? 'pertinence' : 'note')),
          ),
          _puce(
            libelle: '4 étoiles et plus',
            actif: _filtres.noteMin != null,
            onTap: () => _appliquer(
              _filtres.noteMin != null
                  ? _filtres.copierAvec(effacerNoteMin: true)
                  : _filtres.copierAvec(noteMin: 4),
            ),
          ),
          _puce(
            libelle: 'Profil vérifié',
            actif: _filtres.badge == 'profil-verifie',
            onTap: () => _appliquer(
              _filtres.badge == 'profil-verifie'
                  ? _filtres.copierAvec(effacerBadge: true)
                  : _filtres.copierAvec(badge: 'profil-verifie'),
            ),
          ),
          _puce(
            libelle: 'Plus d’expérience',
            actif: _filtres.tri == 'missions',
            onTap: () => _appliquer(
              _filtres.copierAvec(tri: _filtres.tri == 'missions' ? 'pertinence' : 'missions'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _puce({required String libelle, required bool actif, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(libelle),
        selected: actif,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        backgroundColor: context.surfaceMaboko,
        selectedColor: MabokoCouleurs.secondaire.withValues(alpha: 0.15),
        side: BorderSide(color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko),
        labelStyle: TextStyle(
          fontSize: 12.5,
          fontWeight: actif ? FontWeight.w700 : FontWeight.w500,
          color: actif ? MabokoCouleurs.secondaire : MabokoCouleurs.principale,
        ),
      ),
    );
  }

  Widget _corps() {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null) return EtatErreur(message: _erreur!, onReessayer: _charger);

    if (_artisans.isEmpty) {
      return EtatVide(
        icone: Icons.person_search_rounded,
        titre: 'Aucun artisan pour ce métier',
        message: 'Aucun ${widget.titre.toLowerCase()} ne correspond à ces critères. '
            'Essayez de retirer un filtre.',
      );
    }

    return RefreshIndicator(
      color: MabokoCouleurs.secondaire,
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _artisans.length,
        itemBuilder: (context, i) => CarteArtisan(artisan: _artisans[i]),
      ),
    );
  }
}
