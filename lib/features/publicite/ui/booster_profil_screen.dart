import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../../../services/storage_service.dart';
import '../data/publicite_repository.dart';
import '../models/publicite.dart';

/// Écran « Booster mon profil / Mes publicités » pour les artisans.
class BoosterProfilScreen extends StatefulWidget {
  const BoosterProfilScreen({super.key});

  @override
  State<BoosterProfilScreen> createState() => _BoosterProfilScreenState();
}

class _BoosterProfilScreenState extends State<BoosterProfilScreen> {
  static const _depot = PubliciteRepository();

  List<Publicite> _publicites = const [];
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
      final liste = await _depot.mesPublicites();
      if (!mounted) return;
      setState(() {
        _publicites = liste;
        _chargement = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = e.message;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erreur = 'Erreur lors du chargement des publicités.';
        _chargement = false;
      });
    }
  }

  Future<void> _ouvrirFormulaireCreation() async {
    final resultat = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FormulaireCampagneSheet(),
    );

    if (resultat == true) {
      _charger();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Booster mon profil'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ouvrirFormulaireCreation,
        backgroundColor: MabokoCouleurs.secondaire,
        icon: const Icon(Icons.rocket_launch_rounded, color: Colors.white),
        label: const Text(
          'Créer une publicité',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _chargement
          ? const ChargementEnCours()
          : _erreur != null
              ? EtatErreur(message: _erreur!, onReessayer: _charger)
              : _corps(),
    );
  }

  Widget _corps() {
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          _banniereExplicative(),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mes campagnes (${_publicites.length})',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: 20),
                onPressed: _charger,
                tooltip: 'Actualiser',
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_publicites.isEmpty)
            _vueAucunePub()
          else
            ..._publicites.map(_cartePublicite),
        ],
      ),
    );
  }

  Widget _banniereExplicative() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MabokoCouleurs.secondaire,
            MabokoCouleurs.secondaire.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: MabokoCouleurs.secondaire.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Multipliez vos clients avec Maboko Boost',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '1. Choisissez votre plus belle affiche et votre accroche.\n'
            '2. Payez facilement avec MTN ou Airtel Money.\n'
            '3. Dès validation, votre annonce est vue par tous les clients et vous remontez en tête des recherches avec le badge « Sponsorisé » !',
            style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _ouvrirFormulaireCreation,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: MabokoCouleurs.secondaire,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
            label: const Text('Lancer une pub maintenant', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _vueAucunePub() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: context.surfaceMaboko,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Column(
        children: [
          Icon(Icons.campaign_outlined, size: 56, color: context.texteSecondaireMaboko),
          const SizedBox(height: 14),
          const Text(
            'Vous n’avez aucune campagne publicitaire',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 6),
          Text(
            'Créez votre première annonce pour toucher des milliers de clients partout au Congo.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: context.texteSecondaireMaboko),
          ),
        ],
      ),
    );
  }

  Widget _cartePublicite(Publicite pub) {
    Color badgeFond;
    Color badgeTexte;
    String statutLibelle;
    IconData statutIcone;

    if (pub.estEnLigne) {
      badgeFond = Colors.green.withValues(alpha: 0.15);
      badgeTexte = Colors.green.shade800;
      statutLibelle = 'En ligne (${pub.joursRestants} j restants)';
      statutIcone = Icons.check_circle_rounded;
    } else if (pub.estEnAttente) {
      badgeFond = Colors.orange.withValues(alpha: 0.15);
      badgeTexte = Colors.orange.shade900;
      statutLibelle = 'En attente de validation';
      statutIcone = Icons.hourglass_top_rounded;
    } else {
      badgeFond = Colors.grey.withValues(alpha: 0.15);
      badgeTexte = Colors.grey.shade700;
      statutLibelle = 'Terminée';
      statutIcone = Icons.history_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: context.surfaceMaboko,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pub.imageUrl != null && pub.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                pub.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 100,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.image_not_supported_outlined)),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeFond,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statutIcone, size: 14, color: badgeTexte),
                          const SizedBox(width: 4),
                          Text(
                            statutLibelle,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: badgeTexte,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (pub.creeLe != null)
                      Text(
                        '${pub.creeLe!.day}/${pub.creeLe!.month}/${pub.creeLe!.year}',
                        style: TextStyle(fontSize: 11.5, color: context.texteSecondaireMaboko),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  pub.titre,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (pub.description != null && pub.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    pub.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: context.texteSecondaireMaboko),
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _statItem(Icons.visibility_rounded, '${pub.nbAffichages}', 'Vues'),
                    const SizedBox(width: 24),
                    _statItem(Icons.touch_app_rounded, '${pub.nbClics}', 'Clics'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icone, String valeur, String label) {
    return Row(
      children: [
        Icon(icone, size: 16, color: MabokoCouleurs.secondaire),
        const SizedBox(width: 6),
        Text(valeur, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko)),
      ],
    );
  }
}

/// Formulaire de création d'une campagne avec paiement Mobile Money
class _FormulaireCampagneSheet extends StatefulWidget {
  const _FormulaireCampagneSheet();

  @override
  State<_FormulaireCampagneSheet> createState() => _FormulaireCampagneSheetState();
}

class _FormulaireCampagneSheetState extends State<_FormulaireCampagneSheet> {
  static const _depot = PubliciteRepository();

  final _formKey = GlobalKey<FormState>();
  final _titreCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _telCtrl = TextEditingController();

  String? _imageBase64;
  int _dureeSelectionnee = 7;
  String _operateur = 'mtn';
  bool _envoi = false;

  static const _durees = [
    (jours: 3, tarif: 3000, libelle: '3 jours', populaire: false),
    (jours: 7, tarif: 6000, libelle: '7 jours', populaire: true),
    (jours: 15, tarif: 12000, libelle: '15 jours', populaire: false),
    (jours: 30, tarif: 20000, libelle: '30 jours', populaire: false),
  ];

  @override
  void initState() {
    super.initState();
    _chargerTelephone();
  }

  Future<void> _chargerTelephone() async {
    final tel = await StorageService.getUserTelephone();
    if (tel != null && tel.isNotEmpty && mounted) {
      setState(() => _telCtrl.text = tel);
    }
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _descCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirImage() async {
    final fichier = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 80,
    );

    if (fichier == null) return;
    final octets = await fichier.readAsBytes();
    if (!mounted) return;

    setState(() {
      _imageBase64 = 'data:image/jpeg;base64,${base64Encode(octets)}';
    });
  }

  Future<void> _soumettre() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageBase64 == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter une photo ou une affiche pour votre publicité.'),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );
      return;
    }

    setState(() => _envoi = true);

    try {
      final resultat = await _depot.creerCampagne(
        titre: _titreCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        imageBase64: _imageBase64!,
        dureeJours: _dureeSelectionnee,
        operateur: _operateur,
        telephone: _telCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultat.message),
          backgroundColor: MabokoCouleurs.succes,
          duration: const Duration(seconds: 4),
        ),
      );

      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _envoi = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _envoi = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la soumission.'), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceMaboko,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.bordureMaboko,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.rocket_launch_rounded, color: MabokoCouleurs.secondaire),
                  SizedBox(width: 8),
                  Text(
                    'Nouvelle campagne publicitaire',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Votre pub sera affichée à l’ouverture de l’application et en tête des recherches.',
                style: TextStyle(fontSize: 13, color: context.texteSecondaireMaboko),
              ),
              const SizedBox(height: 18),

              // Image / Affiche
              const Text('1. Visuel de l’annonce *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _choisirImage,
                child: Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: context.fondMaboko,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.bordureMaboko, style: BorderStyle.solid),
                  ),
                  child: _imageBase64 != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(
                                base64Decode(_imageBase64!.split(',').last),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 36, color: context.texteSecondaireMaboko),
                            const SizedBox(height: 6),
                            Text(
                              'Touchez pour ajouter une photo de votre travail',
                              style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 18),

              // Titre et Description
              const Text('2. Texte de l’annonce *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Titre d’accroche *',
                  hintText: 'Ex. : Plomberie express Bacongo – Devis gratuit',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().length < 3)
                    ? 'Indiquez un titre percutant (min 3 caractères)'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (facultatif)',
                  hintText: 'Ex. : Dépannage rapide 7j/7, matériaux de qualité garantis.',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 18),

              // Formule / Durée
              const Text('3. Choix de la durée *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: _durees.map((d) {
                  final estSelectionne = _dureeSelectionnee == d.jours;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _dureeSelectionnee = d.jours),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: estSelectionne
                              ? MabokoCouleurs.secondaire
                              : context.fondMaboko,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: estSelectionne
                                ? MabokoCouleurs.secondaire
                                : context.bordureMaboko,
                            width: estSelectionne ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (d.populaire)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(bottom: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Top',
                                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                              ),
                            Text(
                              d.libelle,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: estSelectionne ? Colors.white : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${d.tarif} F',
                              style: TextStyle(
                                fontSize: 11,
                                color: estSelectionne ? Colors.white70 : context.texteSecondaireMaboko,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),

              // Paiement Mobile Money
              const Text('4. Paiement Mobile Money *', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _operateur = 'mtn'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _operateur == 'mtn' ? Colors.amber.shade100 : context.fondMaboko,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _operateur == 'mtn' ? Colors.amber.shade800 : context.bordureMaboko,
                            width: _operateur == 'mtn' ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _operateur == 'mtn' ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 18,
                              color: _operateur == 'mtn' ? Colors.amber.shade900 : context.texteSecondaireMaboko,
                            ),
                            const SizedBox(width: 8),
                            const Text('MTN MoMo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _operateur = 'airtel'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _operateur == 'airtel' ? Colors.red.shade50 : context.fondMaboko,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _operateur == 'airtel' ? Colors.red.shade700 : context.bordureMaboko,
                            width: _operateur == 'airtel' ? 1.8 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _operateur == 'airtel' ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 18,
                              color: _operateur == 'airtel' ? Colors.red.shade700 : context.texteSecondaireMaboko,
                            ),
                            const SizedBox(width: 8),
                            const Text('Airtel Money', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              TextFormField(
                controller: _telCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Numéro Mobile Money *',
                  hintText: '+242060000000',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || !v.trim().startsWith('+242'))
                    ? 'Format international : +24206...'
                    : null,
              ),
              const SizedBox(height: 24),

              // Bouton validation
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _envoi ? null : _soumettre,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MabokoCouleurs.secondaire,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _envoi
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Payer ${_durees.firstWhere((d) => d.jours == _dureeSelectionnee).tarif} FCFA & Valider',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
