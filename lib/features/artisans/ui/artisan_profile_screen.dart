import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../../demandes/ui/demande_form_screen.dart';
import '../../messagerie/data/messagerie_repository.dart';
import '../../messagerie/ui/conversation_screen.dart';
import '../data/artisan_repository.dart';
import '../../fil/data/fil_repository.dart';
import '../../fil/models/publication.dart';
import '../models/artisan.dart';

/// Fiche complète de l'artisan consultée par un client potentiel (§5.1.6) :
/// métier, zone d'intervention, note, badges, avis, parcours — avant la
/// demande de devis.
class ArtisanProfileScreen extends StatefulWidget {
  const ArtisanProfileScreen({super.key, required this.artisanId});

  final int artisanId;

  @override
  State<ArtisanProfileScreen> createState() => _ArtisanProfileScreenState();
}

class _ArtisanProfileScreenState extends State<ArtisanProfileScreen> {
  static const _repository = ArtisanRepository();
  static const _messagerie = MessagerieRepository();

  bool _ouvertureConversation = false;

  Artisan? _artisan;

  /// Réalisations de l'artisan (§5.1.6). Elles n'étaient nulle part sur la
  /// fiche : un client ne pouvait pas juger son travail avant de le contacter.
  List<Publication> _realisations = const [];
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
      final artisan = await _repository.fiche(widget.artisanId);
      if (!mounted) return;
      setState(() {
        _artisan = artisan;
        _chargement = false;
      });

      // Chargées après la fiche : le portfolio complète l'écran, il ne doit
      // pas retarder son affichage ni le faire échouer.
      try {
        final realisations = await const FilRepository()
            .publications(artisanId: artisan.utilisateurId);
        if (!mounted) return;
        setState(() => _realisations = realisations);
      } catch (_) {}
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    }
  }

  /// Ouvre le fil de discussion avec l'artisan, ou récupère l'existant.
  Future<void> _contacter() async {
    final artisan = _artisan;
    if (artisan == null || _ouvertureConversation) return;

    setState(() => _ouvertureConversation = true);

    try {
      final conversation = await _messagerie.ouvrir(interlocuteurId: artisan.utilisateurId);
      if (!mounted) return;
      setState(() => _ouvertureConversation = false);

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ConversationScreen(conversation: conversation)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _ouvertureConversation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

  Future<void> _demanderDevis() async {
    final artisan = _artisan;
    if (artisan == null) return;

    final envoyee = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => DemandeFormScreen(artisan: artisan)),
    );

    if (envoyee == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande envoyée. L’artisan vous répondra depuis l’application.'),
          backgroundColor: MabokoCouleurs.succes,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final artisan = _artisan;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profil artisan'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      bottomNavigationBar: artisan == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      height: 52,
                      width: 56,
                      child: OutlinedButton(
                        onPressed: _ouvertureConversation ? null : _contacter,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          foregroundColor: MabokoCouleurs.secondaire,
                          side: const BorderSide(color: MabokoCouleurs.secondaire),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _ouvertureConversation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: MabokoCouleurs.secondaire,
                                ),
                              )
                            : const Icon(Icons.chat_bubble_outline),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _demanderDevis,
                          icon: const Icon(Icons.request_quote_outlined),
                          label: const Text('Demander un devis'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MabokoCouleurs.secondaire,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      body: _corps(),
    );
  }

  Widget _corps() {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null) return EtatErreur(message: _erreur!, onReessayer: _charger);

    final artisan = _artisan!;

    return RefreshIndicator(
      color: MabokoCouleurs.secondaire,
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _enTete(artisan),
          const SizedBox(height: 16),
          _statistiques(artisan),
          if (artisan.badges.isNotEmpty) ...[
            const SizedBox(height: 16),
            _section(
              titre: 'Badges de confiance',
              enfant: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: artisan.badges.map<Widget>(_carteBadge).toList(),
              ),
            ),
          ],
          if (_realisations.isNotEmpty) ...[
            const SizedBox(height: 16),
            _section(
              titre: 'Portfolio de réalisations',
              enfant: SizedBox(
                height: 118,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _realisations.length,
                  separatorBuilder: (contexte, index) => const SizedBox(width: 10),
                  itemBuilder: (contexte, i) {
                    final realisation = _realisations[i];
                    final apercu = realisation.medias.isEmpty ? null : realisation.medias.first;

                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 118,
                        height: 118,
                        child: apercu == null
                            ? Container(
                                color: context.bordureMaboko,
                                alignment: Alignment.center,
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  realisation.description,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              )
                            : Image.network(
                                apercu,
                                fit: BoxFit.cover,
                                errorBuilder: (contexte, erreur, trace) =>
                                    Container(color: context.bordureMaboko),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (artisan.bio != null && artisan.bio!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _section(
              titre: 'Son parcours',
              enfant: Text(artisan.bio!, style: const TextStyle(height: 1.5, fontSize: 14)),
            ),
          ],
          const SizedBox(height: 16),
          _section(
            titre: 'Zone d’intervention',
            enfant: Row(
              children: [
                const Icon(Icons.place_outlined, size: 18, color: MabokoCouleurs.secondaire),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    artisan.zoneIntervention ?? artisan.adresse ?? 'Non précisée',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _section(
            titre: 'Avis clients',
            compteur: artisan.nbAvis,
            enfant: artisan.avis.isEmpty
                ? Text(
                    'Cet artisan n’a pas encore reçu d’avis.',
                    style: TextStyle(color: context.texteSecondaireMaboko, fontSize: 13.5),
                  )
                : Column(children: artisan.avis.map<Widget>(_ligneAvis).toList()),
          ),
        ],
      ),
    );
  }

  Widget _enTete(Artisan artisan) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 38,
          backgroundColor: context.surfaceMaboko,
          backgroundImage: artisan.avatarUrl != null && artisan.avatarUrl!.isNotEmpty
              ? NetworkImage(artisan.avatarUrl!)
              : null,
          child: artisan.avatarUrl == null || artisan.avatarUrl!.isEmpty
              ? const Icon(Icons.handyman_rounded, size: 34, color: MabokoCouleurs.secondaire)
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                artisan.nomComplet,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 3),
              Text(
                artisan.metiers.isNotEmpty ? artisan.metiers.join(' · ') : artisan.specialite,
                style: const TextStyle(color: MabokoCouleurs.secondaire, fontWeight: FontWeight.w600),
              ),
              if (artisan.quartier != null) ...[
                const SizedBox(height: 3),
                Text(
                  artisan.quartier!,
                  style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Etoiles(note: artisan.noteMoyenne),
                  const SizedBox(width: 6),
                  Text(
                    artisan.nbAvis == 0
                        ? 'Pas encore d’avis'
                        : '${artisan.noteMoyenne.toStringAsFixed(1)} · ${artisan.nbAvis} avis',
                    style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statistiques(Artisan artisan) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _statistique('${artisan.nbMissionsTerminees}', 'Missions'),
          _separateur(),
          _statistique(artisan.nbAvis == 0 ? '—' : artisan.noteMoyenne.toStringAsFixed(1), 'Note'),
          _separateur(),
          _statistique('${artisan.badges.length}', 'Badges'),
        ],
      ),
    );
  }

  Widget _statistique(String valeur, String libelle) {
    return Column(
      children: [
        Text(valeur, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(libelle, style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko)),
      ],
    );
  }

  Widget _separateur() => Container(width: 1, height: 30, color: context.bordureMaboko);

  Widget _section({required String titre, required Widget enfant, int? compteur}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
              Text(titre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              if (compteur != null && compteur > 0) ...[
                const SizedBox(width: 6),
                Text('($compteur)', style: TextStyle(color: context.texteSecondaireMaboko, fontSize: 13)),
              ],
            ],
          ),
          const SizedBox(height: 12),
          enfant,
        ],
      ),
    );
  }

  Widget _carteBadge(BadgeConfiance badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: context.teinteMaboko,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 15, color: MabokoCouleurs.accent),
          const SizedBox(width: 6),
          Text(
            badge.nom,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: context.texteFortMaboko),
          ),
        ],
      ),
    );
  }

  Widget _ligneAvis(Avis avis) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Etoiles(note: avis.note.toDouble(), taille: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  avis.auteur ?? 'Client Maboko',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (avis.commentaire != null && avis.commentaire!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              avis.commentaire!,
              style: TextStyle(fontSize: 13.5, height: 1.45, color: context.texteSecondaireMaboko),
            ),
          ],
        ],
      ),
    );
  }
}
