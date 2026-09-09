import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/identite_repository.dart';

/// Vérification d'identité (§4.5) : dépôt des pièces puis suivi de l'examen.
///
/// C'est le préalable au badge « Profil vérifié », qui pèse dans le classement
/// de recherche et rassure les clients avant une intervention à domicile.
class VerificationIdentiteScreen extends StatefulWidget {
  const VerificationIdentiteScreen({super.key});

  @override
  State<VerificationIdentiteScreen> createState() => _VerificationIdentiteScreenState();
}

class _VerificationIdentiteScreenState extends State<VerificationIdentiteScreen> {
  static const _repository = IdentiteRepository();

  static const _pieces = [
    (valeur: 'cni', libelle: 'Carte nationale d’identité'),
    (valeur: 'passeport', libelle: 'Passeport'),
    (valeur: 'carte_consulaire', libelle: 'Carte consulaire'),
  ];

  final _numero = TextEditingController();

  EtatVerification? _etat;
  String _typePiece = 'cni';
  String? _recto;
  String? _verso;
  bool _chargement = true;
  bool _envoiEnCours = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    _numero.dispose();
    super.dispose();
  }

  Future<void> _charger() async {
    setState(() => _erreur = null);

    try {
      final etat = await _repository.etat();
      if (!mounted) return;
      setState(() {
        _etat = etat;
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

  Future<void> _choisir(bool recto) async {
    final fichier = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      imageQuality: 85,
    );

    if (fichier == null) return;

    final octets = await fichier.readAsBytes();
    if (!mounted) return;

    final encode = 'data:image/jpeg;base64,${base64Encode(octets)}';
    setState(() => recto ? _recto = encode : _verso = encode);
  }

  Future<void> _envoyer() async {
    if (_recto == null) {
      _informer('La photo recto de la pièce est obligatoire.', MabokoCouleurs.danger);

      return;
    }

    setState(() => _envoiEnCours = true);

    try {
      await _repository.deposer(
        typePiece: _typePiece,
        recto: _recto!,
        numeroPiece: _numero.text.trim(),
        verso: _verso,
      );

      if (!mounted) return;
      setState(() {
        _envoiEnCours = false;
        _recto = null;
        _verso = null;
      });
      _informer('Pièces envoyées. Notre équipe les examine sous 48 heures.', MabokoCouleurs.succes);
      await _charger();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _envoiEnCours = false);
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
      backgroundColor: MabokoCouleurs.fond,
      appBar: AppBar(
        title: const Text('Vérifier mon identité'),
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

    final etat = _etat!;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _bandeauStatut(etat),
        const SizedBox(height: 20),
        if (etat.peutDeposer) ...[
          _explication(),
          const SizedBox(height: 20),
          _choixPiece(),
          const SizedBox(height: 16),
          TextField(
            controller: _numero,
            decoration: InputDecoration(
              labelText: 'Numéro de la pièce (facultatif)',
              prefixIcon: const Icon(Icons.badge_outlined, color: MabokoCouleurs.secondaire),
              filled: true,
              fillColor: MabokoCouleurs.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: MabokoCouleurs.bordure),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _cadrePhoto('Recto', _recto, () => _choisir(true), obligatoire: true)),
              const SizedBox(width: 12),
              Expanded(child: _cadrePhoto('Verso', _verso, () => _choisir(false))),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _envoiEnCours ? null : _envoyer,
              style: ElevatedButton.styleFrom(
                backgroundColor: MabokoCouleurs.secondaire,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _envoiEnCours
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                    )
                  : const Text(
                      'Envoyer mes pièces',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _bandeauStatut(EtatVerification etat) {
    final (couleur, icone) = switch (etat.statut) {
      'valide' => (MabokoCouleurs.succes, Icons.verified_rounded),
      'en_attente' => (MabokoCouleurs.accent, Icons.hourglass_top_rounded),
      'rejete' => (MabokoCouleurs.danger, Icons.error_outline_rounded),
      _ => (MabokoCouleurs.secondaire, Icons.badge_outlined),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: couleur.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: couleur, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(etat.message, style: const TextStyle(fontSize: 14, height: 1.45)),
                if (etat.motifRejet != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Motif : ${etat.motifRejet}',
                    style: TextStyle(fontSize: 13, color: couleur, fontWeight: FontWeight.w600),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _explication() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MabokoCouleurs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: MabokoCouleurs.bordure),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pourquoi vérifier votre identité ?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          SizedBox(height: 10),
          Text(
            'Le badge « Profil vérifié » apparaît sur votre fiche, vous fait '
            'remonter dans les résultats de recherche, et rassure les clients '
            'avant une intervention à domicile.',
            style: TextStyle(fontSize: 13.5, height: 1.5, color: MabokoCouleurs.texteSecondaire),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.lock_outline, size: 15, color: MabokoCouleurs.secondaire),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vos pièces ne sont visibles que de l’équipe Maboko, jamais des clients.',
                  style: TextStyle(fontSize: 12.5, color: MabokoCouleurs.texteSecondaire),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _choixPiece() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Type de pièce', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        // RadioGroup remplace les paramètres groupValue/onChanged, dépréciés
        // sur RadioListTile depuis Flutter 3.32.
        RadioGroup<String>(
          groupValue: _typePiece,
          onChanged: (valeur) => setState(() => _typePiece = valeur ?? _typePiece),
          child: Column(
            children: _pieces
                .map((piece) => RadioListTile<String>(
                      value: piece.valeur,
                      title: Text(piece.libelle, style: const TextStyle(fontSize: 14)),
                      activeColor: MabokoCouleurs.secondaire,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _cadrePhoto(String libelle, String? donnees, VoidCallback onTap, {bool obligatoire = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          color: MabokoCouleurs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: donnees != null ? MabokoCouleurs.succes : MabokoCouleurs.bordure,
          ),
        ),
        child: donnees != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: Image.memory(
                  base64Decode(donnees.split(',').last),
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.photo_camera_outlined, color: MabokoCouleurs.secondaire, size: 26),
                  const SizedBox(height: 8),
                  Text(
                    obligatoire ? '$libelle *' : libelle,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }
}
