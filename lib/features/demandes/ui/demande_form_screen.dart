import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../artisans/models/artisan.dart';
import '../data/demande_repository.dart';

/// Formulaire de demande de devis (§5.1.7) : description du besoin,
/// photos à l'appui et adresse d'intervention.
class DemandeFormScreen extends StatefulWidget {
  const DemandeFormScreen({super.key, required this.artisan});

  final Artisan artisan;

  @override
  State<DemandeFormScreen> createState() => _DemandeFormScreenState();
}

class _DemandeFormScreenState extends State<DemandeFormScreen> {
  static const _repository = DemandeRepository();
  static const _maxPhotos = 6;

  final _formKey = GlobalKey<FormState>();
  final _titre = TextEditingController();
  final _description = TextEditingController();
  final _adresse = TextEditingController();
  final _budget = TextEditingController();

  final List<String> _photos = [];
  DateTime? _dateSouhaitee;
  bool _envoiEnCours = false;

  @override
  void dispose() {
    _titre.dispose();
    _description.dispose();
    _adresse.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _ajouterPhoto() async {
    if (_photos.length >= _maxPhotos) return;

    final fichier = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 75,
    );

    if (fichier == null) return;

    final octets = await fichier.readAsBytes();
    if (!mounted) return;

    setState(() {
      _photos.add('data:image/jpeg;base64,${base64Encode(octets)}');
    });
  }

  Future<void> _choisirDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Quand souhaitez-vous l’intervention ?',
    );

    if (date != null && mounted) setState(() => _dateSouhaitee = date);
  }

  Future<void> _envoyer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _envoiEnCours = true);

    try {
      await _repository.creer(
        artisanId: widget.artisan.id,
        titre: _titre.text.trim(),
        description: _description.text.trim(),
        adresse: _adresse.text.trim(),
        budgetEstime: double.tryParse(_budget.text.replaceAll(' ', '')),
        dateSouhaitee: _dateSouhaitee?.toIso8601String().split('T').first,
        photos: _photos,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _envoiEnCours = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Demande de devis'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _destinataire(),
            const SizedBox(height: 20),
            _champ(
              controleur: _titre,
              libelle: 'Objet de la demande',
              indice: 'Ex. : réparation d’une fuite sous l’évier',
              icone: Icons.title_rounded,
              validateur: (v) => (v == null || v.trim().isEmpty) ? 'Indiquez l’objet de votre demande' : null,
            ),
            const SizedBox(height: 14),
            _champ(
              controleur: _description,
              libelle: 'Décrivez votre besoin',
              indice: 'Plus vous êtes précis, plus le devis sera juste',
              icone: Icons.notes_rounded,
              lignes: 5,
              validateur: (v) {
                final texte = v?.trim() ?? '';
                if (texte.isEmpty) return 'Décrivez votre besoin';
                if (texte.length < 10) return 'Décrivez votre besoin en quelques mots (10 caractères minimum)';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _champ(
              controleur: _adresse,
              libelle: 'Adresse d’intervention',
              indice: 'Ex. : rue Mbochis, Bacongo, Brazzaville',
              icone: Icons.place_outlined,
              validateur: (v) => (v == null || v.trim().isEmpty) ? 'Indiquez où intervenir' : null,
            ),
            const SizedBox(height: 14),
            _champ(
              controleur: _budget,
              libelle: 'Budget estimé (facultatif)',
              indice: 'En francs CFA',
              icone: Icons.payments_outlined,
              clavier: TextInputType.number,
            ),
            const SizedBox(height: 14),
            _selecteurDate(),
            const SizedBox(height: 20),
            _galeriePhotos(),
            const SizedBox(height: 26),
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
                        'Envoyer la demande',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _destinataire() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceMaboko,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: context.fondMaboko,
            child: const Icon(Icons.handyman_rounded, color: MabokoCouleurs.secondaire, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demande adressée à',
                  style: TextStyle(fontSize: 11.5, color: context.texteSecondaireMaboko),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.artisan.nomComplet,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  widget.artisan.metiers.isNotEmpty
                      ? widget.artisan.metiers.first
                      : widget.artisan.specialite,
                  style: const TextStyle(fontSize: 12.5, color: MabokoCouleurs.secondaire),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _champ({
    required TextEditingController controleur,
    required String libelle,
    required String indice,
    required IconData icone,
    int lignes = 1,
    TextInputType? clavier,
    String? Function(String?)? validateur,
  }) {
    return TextFormField(
      controller: controleur,
      maxLines: lignes,
      keyboardType: clavier,
      validator: validateur,
      decoration: InputDecoration(
        labelText: libelle,
        hintText: indice,
        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFB6A997)),
        prefixIcon: Icon(icone, color: MabokoCouleurs.secondaire),
        filled: true,
        fillColor: context.surfaceMaboko,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.bordureMaboko),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.bordureMaboko),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: MabokoCouleurs.secondaire, width: 1.4),
        ),
      ),
    );
  }

  Widget _selecteurDate() {
    return InkWell(
      onTap: _choisirDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: context.surfaceMaboko,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.bordureMaboko),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined, color: MabokoCouleurs.secondaire),
            const SizedBox(width: 12),
            Text(
              _dateSouhaitee == null
                  ? 'Date souhaitée (facultatif)'
                  : '${_dateSouhaitee!.day.toString().padLeft(2, '0')}/'
                      '${_dateSouhaitee!.month.toString().padLeft(2, '0')}/'
                      '${_dateSouhaitee!.year}',
              style: TextStyle(
                fontSize: 14.5,
                color: _dateSouhaitee == null ? const Color(0xFF7A6A5C) : MabokoCouleurs.principale,
              ),
            ),
            const Spacer(),
            if (_dateSouhaitee != null)
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () => setState(() => _dateSouhaitee = null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _galeriePhotos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              '${_photos.length}/$_maxPhotos',
              style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Une photo du problème aide l’artisan à chiffrer sans se déplacer.',
          style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._photos.asMap().entries.map((e) => _vignette(e.key, e.value)),
            if (_photos.length < _maxPhotos) _boutonAjout(),
          ],
        ),
      ],
    );
  }

  Widget _vignette(int index, String donnees) {
    final base64 = donnees.split(',').last;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            base64Decode(base64),
            width: 84,
            height: 84,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: () => setState(() => _photos.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _boutonAjout() {
    return InkWell(
      onTap: _ajouterPhoto,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: context.surfaceMaboko,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.bordureMaboko),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_a_photo_outlined, color: MabokoCouleurs.secondaire, size: 22),
            const SizedBox(height: 4),
            Text('Ajouter', style: TextStyle(fontSize: 10.5, color: context.texteSecondaireMaboko)),
          ],
        ),
      ),
    );
  }
}
