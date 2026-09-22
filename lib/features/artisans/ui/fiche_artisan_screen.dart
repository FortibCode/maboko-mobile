import 'package:flutter/material.dart';

import '../../../core/localisation/service_position.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../../metiers/data/metier_repository.dart';
import '../../metiers/models/metier.dart';
import '../data/artisan_repository.dart';
import '../models/artisan.dart';
import 'inscription/inscription_artisan_data.dart';

/// Création de la fiche artisan (§5.2.1).
///
/// L'inscription crée le compte mais pas la fiche. Sans elle, l'artisan
/// n'apparaît dans aucune recherche et son tableau de bord n'affiche que
/// « Votre fiche artisan est incomplète » — sans rien pour y remédier.
/// La route existait côté serveur, aucun écran ne l'appelait.
///
/// Depuis le nouveau parcours, les infos ville/quartier/bio collectées aux
/// étapes précédentes sont pré-remplies ici.
class FicheArtisanScreen extends StatefulWidget {
  const FicheArtisanScreen({
    super.key,
    this.villeConnue,
    this.nomComplet,
    this.premiereFois = false,
    this.modification = false,
  });

  /// Ville déjà renseignée sur le compte, proposée par défaut.
  final String? villeConnue;

  /// Nom de l'artisan, pour l'accueillir au sortir de l'inscription.
  final String? nomComplet;

  /// Passage juste après la création du compte : pas de retour en arrière.
  final bool premiereFois;

  /// Modification d'une fiche existante : les champs sont pré-remplis et
  /// l'enregistrement passe par une mise à jour, pas par une création.
  final bool modification;

  @override
  State<FicheArtisanScreen> createState() => _FicheArtisanScreenState();
}

class _FicheArtisanScreenState extends State<FicheArtisanScreen> {
  static const _artisans = ArtisanRepository();
  static const _metiersDepot = MetierRepository();

  /// Repères des principales villes du pays.
  static const _villes = <String, ({double lat, double lon})>{
    'Brazzaville': (lat: -4.2634, lon: 15.2429),
    'Pointe-Noire': (lat: -4.7761, lon: 11.8635),
    'Dolisie': (lat: -4.1985, lon: 12.6667),
    'Nkayi': (lat: -4.1833, lon: 13.2833),
    'Ouesso': (lat: 1.6136, lon: 16.0517),
    'Owando': (lat: -0.4819, lon: 15.8994),
    'Impfondo': (lat: 1.6167, lon: 18.0667),
  };

  final _cleFormulaire = GlobalKey<FormState>();
  final _adresse = TextEditingController();
  final _zone = TextEditingController();
  final _bio = TextEditingController();

  List<Metier>? _metiers;
  String? _erreurChargement;
  final Set<String> _choisis = {};

  /// Fiche existante, en mode modification.
  Artisan? _existante;

  /// Ville affichée par défaut dans le dropdown.
  late String _ville;

  int _rayon = 10;
  bool _envoi = false;
  bool _positionPrecise = false;

  @override
  void initState() {
    super.initState();
    _ville = _villeParDefaut();
    _charger();
  }

  @override
  void dispose() {
    _adresse.dispose();
    _zone.dispose();
    _bio.dispose();
    super.dispose();
  }

  /// Ville par défaut : celle passée en paramètre si valide, sinon Brazzaville.
  String _villeParDefaut() {
    final connue = widget.villeConnue?.trim();
    if (connue != null && connue.isNotEmpty && _villes.containsKey(connue)) {
      return connue;
    }
    return 'Brazzaville';
  }

  Future<void> _charger() async {
    setState(() => _erreurChargement = null);

    try {
      final liste = await _metiersDepot.lister();
      final fiche = widget.modification ? await _artisans.maFiche() : null;

      // En mode première fois, on relit les infos du parcours d'inscription
      // pour pré-remplir la ville, le quartier (dans zone) et la bio.
      InscriptionArtisanData? parcours;
      if (widget.premiereFois) {
        parcours = await InscriptionArtisanData.charger();
      }

      if (!mounted) return;

      setState(() {
        _metiers = liste;
        _existante = fiche;

        if (fiche != null) {
          // Mode modification : on utilise la fiche existante.
          _choisis
            ..clear()
            ..addAll(fiche.metiersSlugs);
          _adresse.text = fiche.adresse ?? '';
          _zone.text = fiche.zoneIntervention ?? '';
          _bio.text = fiche.bio ?? '';
          _rayon = fiche.rayonKm ?? _rayon;
          if (fiche.zoneIntervention != null &&
              _villes.containsKey(fiche.zoneIntervention)) {
            _ville = fiche.zoneIntervention!;
          }
        } else if (parcours != null) {
          // Mode première fois : on pré-remplit avec le parcours.
          if (parcours.ville != null && _villes.containsKey(parcours.ville)) {
            _ville = parcours.ville!;
          }
          if (parcours.quartier != null && parcours.quartier!.isNotEmpty) {
            _zone.text = parcours.quartier!;
          }
          if (parcours.bio != null && parcours.bio!.isNotEmpty) {
            _bio.text = parcours.bio!;
          }
        }
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _erreurChargement = e.message);
    }
  }

  Future<void> _enregistrer() async {
    if (!_cleFormulaire.currentState!.validate()) return;

    if (_choisis.isEmpty) {
      _informer('Choisissez au moins un métier.', MabokoCouleurs.danger);
      return;
    }

    setState(() => _envoi = true);

    final position = _existante == null ? await ServicePosition.actuelle() : null;
    final repere = _villes[_ville]!;
    final precise = position != null;

    final metierChoisi = _metiers!.firstWhere((m) => m.slug == _choisis.first);

    try {
      if (_existante != null) {
        await _artisans.mettreAJourFiche(
          _existante!.id,
          specialite: metierChoisi.nom,
          adresse: _adresse.text.trim(),
          metiers: _choisis.toList(),
          bio: _bio.text.trim(),
          zoneIntervention:
              _zone.text.trim().isEmpty ? _ville : _zone.text.trim(),
          rayonKm: _rayon,
        );
      } else {
        await _artisans.creerFiche(
          specialite: metierChoisi.nom,
          adresse: _adresse.text.trim(),
          latitude: position?.latitude ?? repere.lat,
          longitude: position?.longitude ?? repere.lon,
          metiers: _choisis.toList(),
          bio: _bio.text.trim(),
          zoneIntervention:
              _zone.text.trim().isEmpty ? _ville : _zone.text.trim(),
          rayonKm: _rayon,
        );
      }

      // La fiche est enregistrée : on peut vider le parcours d'inscription
      // pour ne pas polluer la prochaine connexion.
      if (widget.premiereFois) {
        await InscriptionArtisanData.vider();
      }

      if (!mounted) return;
      setState(() {
        _envoi = false;
        _positionPrecise = precise;
      });

      _informer(
        _existante != null
            ? 'Fiche mise à jour.'
            : precise
                ? 'Fiche enregistrée. Elle est en cours de validation.'
                : 'Fiche enregistrée avec la position approximative de $_ville.',
        MabokoCouleurs.succes,
      );

      if (widget.premiereFois) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
          arguments: {
            'avatarName': widget.nomComplet ?? 'Artisan',
            'userRole': 'artisan',
          },
        );

        return;
      }

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _envoi = false);
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
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: Text(widget.premiereFois
            ? 'Votre métier'
            : widget.modification
                ? 'Mes métiers et ma zone'
                : 'Ma fiche artisan'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.premiereFois,
      ),
      body: _corps(),
    );
  }

  Widget _corps() {
    if (_erreurChargement != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          EtatErreur(message: _erreurChargement!, onReessayer: _charger),
        ],
      );
    }

    if (_metiers == null) return const ChargementEnCours();

    return Form(
      key: _cleFormulaire,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _encadre(
            icone: Icons.storefront_outlined,
            texte: widget.premiereFois
                ? 'Bienvenue${widget.nomComplet == null ? '' : ' ${widget.nomComplet}'} ! '
                    'Dernière étape : dites-nous ce que vous faites et où. '
                    'C’est ce que les clients verront en vous cherchant.'
                : 'Cette fiche est ce que les clients voient quand ils '
                    'cherchent un artisan. Ajoutez ou retirez un métier, '
                    'ajustez votre zone : les changements sont visibles tout '
                    'de suite.',
          ),
          const SizedBox(height: 20),

          _titre('Vos métiers', 'Cinq au maximum. Le premier sera votre spécialité.'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _metiers!.map(_puce).toList(),
          ),
          const SizedBox(height: 22),

          _titre('Où intervenez-vous ?', null),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _ville,
            decoration: _decoration('Ville', Icons.location_city_outlined),
            items: _villes.keys
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() => _ville = v ?? _ville),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _adresse,
            decoration: _decoration('Adresse de l’atelier', Icons.place_outlined,
                indice: 'Ex. : rue Mbochis, Bacongo'),
            validator: (valeur) => (valeur ?? '').trim().length < 4
                ? 'Indiquez où vous travaillez.'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _zone,
            decoration: _decoration('Quartiers desservis (facultatif)',
                Icons.travel_explore_outlined,
                indice: 'Ex. : Bacongo, Makélékélé'),
          ),
          const SizedBox(height: 18),

          _titre('Rayon de déplacement', '$_rayon km autour de votre atelier'),
          Slider(
            value: _rayon.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            activeColor: MabokoCouleurs.secondaire,
            label: '$_rayon km',
            onChanged: (v) => setState(() => _rayon = v.round()),
          ),
          const SizedBox(height: 6),

          _titre('Présentez votre travail', 'Facultatif, mais ça rassure les clients.'),
          const SizedBox(height: 10),
          TextFormField(
            controller: _bio,
            maxLines: 4,
            maxLength: 2000,
            decoration: _decoration('Quelques mots sur votre savoir-faire',
                Icons.notes_outlined),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: _envoi ? null : _enregistrer,
              style: FilledButton.styleFrom(
                backgroundColor: MabokoCouleurs.secondaire,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _envoi
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : Text(widget.premiereFois ? 'Commencer' : 'Enregistrer',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15.5)),
            ),
          ),
          if (_existante == null && !_positionPrecise) ...[
            const SizedBox(height: 12),
            Text(
              'Votre position exacte est demandée au moment de l’enregistrement. '
              'Si vous la refusez, le repère de la ville est utilisé et vous '
              'apparaîtrez de façon moins précise dans les recherches.',
              style: TextStyle(
                  fontSize: 12, height: 1.45, color: context.texteSecondaireMaboko),
            ),
          ],
        ],
      ),
    );
  }

  Widget _puce(Metier metier) {
    final choisi = _choisis.contains(metier.slug);

    return FilterChip(
      label: Text(metier.nom),
      selected: choisi,
      showCheckmark: false,
      backgroundColor: context.surfaceMaboko,
      selectedColor: MabokoCouleurs.secondaire.withValues(alpha: 0.16),
      side: BorderSide(
        color: choisi ? MabokoCouleurs.secondaire : context.bordureMaboko,
        width: choisi ? 1.4 : 1,
      ),
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: choisi ? FontWeight.bold : FontWeight.normal,
        color: choisi ? MabokoCouleurs.secondaire : context.texteFortMaboko,
      ),
      onSelected: (valeur) => setState(() {
        if (!valeur) {
          _choisis.remove(metier.slug);
        } else if (_choisis.length < 5) {
          _choisis.add(metier.slug);
        } else {
          _informer('Cinq métiers au maximum.', MabokoCouleurs.principale);
        }
      }),
    );
  }

  Widget _titre(String titre, String? sous) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titre,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: context.texteFortMaboko)),
        if (sous != null) ...[
          const SizedBox(height: 3),
          Text(sous,
              style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko)),
        ],
      ],
    );
  }

  Widget _encadre({required IconData icone, required String texte}) {
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
          Icon(icone, size: 20, color: MabokoCouleurs.secondaire),
          const SizedBox(width: 10),
          Expanded(
            child: Text(texte,
                style: TextStyle(
                    fontSize: 12.5, height: 1.45, color: context.texteSecondaireMaboko)),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String libelle, IconData icone, {String? indice}) {
    return InputDecoration(
      labelText: libelle,
      hintText: indice,
      prefixIcon: Icon(icone, size: 20, color: MabokoCouleurs.secondaire),
      filled: true,
      fillColor: context.surfaceMaboko,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.bordureMaboko),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.bordureMaboko),
      ),
    );
  }
}