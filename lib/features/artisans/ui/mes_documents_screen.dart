import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';

/// Mes documents (§5.2).
///
/// L'artisan garde ici ses papiers professionnels : CNI, RCCM, diplômes,
/// attestations. Les photos restent sur le téléphone — ce sont des
/// documents personnels qui n'ont pas à transiter par le serveur.
class MesDocumentsScreen extends StatefulWidget {
  const MesDocumentsScreen({super.key});

  @override
  State<MesDocumentsScreen> createState() => _MesDocumentsScreenState();
}

class _MesDocumentsScreenState extends State<MesDocumentsScreen> {
  static const _cleDocuments = 'artisan_documents';

  List<DocumentArtisan> _documents = const [];
  bool _chargement = true;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    final brut = prefs.getStringList(_cleDocuments) ?? [];

    if (!mounted) return;
    setState(() {
      _documents = brut
          .map(DocumentArtisan.depuisChaine)
          .whereType<DocumentArtisan>()
          .toList()
        ..sort((a, b) => b.ajouteLe.compareTo(a.ajouteLe));
      _chargement = false;
    });
  }

  Future<void> _enregistrer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _cleDocuments,
      _documents.map((d) => d.versChaine()).toList(),
    );
  }

  Future<void> _ajouter() async {
    // 1. Choix de la source
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _feuilleSource(),
    );

    if (source == null) return;

    setState(() => _enCours = true);

    try {
      // 2. Prise / sélection de la photo
      final fichier = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1800,
        imageQuality: 80,
      );

      if (fichier == null) {
        setState(() => _enCours = false);
        return;
      }

      final octets = await fichier.readAsBytes();
      if (!mounted) return;

      // 3. Nom du document
      final nom = await _demanderNom();
      if (nom == null || nom.trim().isEmpty) {
        setState(() => _enCours = false);
        return;
      }

      final encode = 'data:image/jpeg;base64,${base64Encode(octets)}';

      final doc = DocumentArtisan(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        nom: nom.trim(),
        photoBase64: encode,
        ajouteLe: DateTime.now(),
      );

      setState(() {
        _documents = [doc, ..._documents];
        _enCours = false;
      });
      await _enregistrer();
    } catch (_) {
      if (!mounted) return;
      setState(() => _enCours = false);
      _informer('Impossible d’ajouter ce document.', MabokoCouleurs.danger);
    }
  }

  Future<String?> _demanderNom() {
    final controleur = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Nom du document'),
        content: TextField(
          controller: controleur,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          maxLength: 60,
          decoration: const InputDecoration(
            hintText: 'Ex. : CNI, RCCM, Diplôme menuiserie',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controleur.text),
            child: const Text(
              'Valider',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _apercu(DocumentArtisan doc) async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      doc.nom,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Image.memory(
                base64Decode(doc.photoBase64.split(',').last),
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _supprimer(DocumentArtisan doc) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce document ?'),
        content: Text('« ${doc.nom} » sera retiré de votre liste.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: MabokoCouleurs.danger),
            ),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    setState(() => _documents = _documents.where((d) => d.id != doc.id).toList());
    await _enregistrer();
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
        title: const Text('Mes documents'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _enCours ? null : _ajouter,
        backgroundColor: MabokoCouleurs.secondaire,
        icon: _enCours
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
              )
            : const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text(
          'Ajouter',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: _chargement
          ? const ChargementEnCours()
          : _documents.isEmpty
              ? _vide()
              : _liste(),
    );
  }

  Widget _vide() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        SizedBox(height: 60),
        EtatVide(
          icone: Icons.folder_outlined,
          titre: 'Aucun document',
          message: 'Ajoutez vos papiers professionnels : CNI, RCCM, '
              'diplômes, attestations. Ils restent sur votre téléphone.',
        ),
      ],
    );
  }

  Widget _liste() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _documents.length + 1,
      itemBuilder: (contexte, i) {
        if (i == 0) return _encadre();

        final doc = _documents[i - 1];
        return _carte(doc);
      },
    );
  }

  Widget _carte(DocumentArtisan doc) {
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
          onTap: () => _apercu(doc),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Vignette
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(doc.photoBase64.split(',').last),
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: context.bordureMaboko,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doc.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ajouté ${_dateLisible(doc.ajouteLe)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.texteSecondaireMaboko,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded,
                      color: MabokoCouleurs.danger, size: 20),
                  tooltip: 'Supprimer',
                  onPressed: () => _supprimer(doc),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _encadre() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.teinteMaboko,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_outline_rounded,
              size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Vos documents restent sur votre téléphone. Ils ne sont ni '
              'envoyés à Maboko, ni visibles des clients.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: context.texteSecondaireMaboko,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feuilleSource() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: context.bordureMaboko,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Text(
            'Ajouter un document',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 18),
          _optionSource(
            icone: Icons.photo_camera_rounded,
            titre: 'Prendre une photo',
            sous: 'Utile pour un document papier',
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          const SizedBox(height: 10),
          _optionSource(
            icone: Icons.photo_library_rounded,
            titre: 'Choisir dans la galerie',
            sous: 'Si vous avez déjà la photo',
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
        ],
      ),
    );
  }

  Widget _optionSource({
    required IconData icone,
    required String titre,
    required String sous,
    required VoidCallback onTap,
  }) {
    return Material(
      color: context.surfaceMaboko,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.bordureMaboko),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: MabokoCouleurs.secondaire.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                alignment: Alignment.center,
                child: Icon(icone, color: MabokoCouleurs.secondaire, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14.5)),
                    const SizedBox(height: 3),
                    Text(
                      sous,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: context.texteSecondaireMaboko,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: context.texteSecondaireMaboko),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLisible(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'à l’instant';
    if (difference.inHours < 1) return 'il y a ${difference.inMinutes} min';
    if (difference.inDays < 1) return 'il y a ${difference.inHours} h';
    if (difference.inDays == 1) return 'hier';
    if (difference.inDays < 7) return 'il y a ${difference.inDays} jours';

    const mois = [
      'janv.', 'févr.', 'mars', 'avril', 'mai', 'juin',
      'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
    ];

    return 'le ${date.day} ${mois[date.month - 1]} ${date.year}';
  }
}

// ---------------------------------------------------------------------------
// Modèle
// ---------------------------------------------------------------------------

/// Document personnel de l'artisan, encodé en `id|nom|base64|horodatage`.
class DocumentArtisan {
  const DocumentArtisan({
    required this.id,
    required this.nom,
    required this.photoBase64,
    required this.ajouteLe,
  });

  final String id;
  final String nom;
  final String photoBase64;
  final DateTime ajouteLe;

  String versChaine() =>
      '$id|${nom.replaceAll('|', '&#124;')}|$photoBase64|${ajouteLe.millisecondsSinceEpoch}';

  static DocumentArtisan? depuisChaine(String brut) {
    final morceaux = brut.split('|');
    if (morceaux.length < 4) return null;

    return DocumentArtisan(
      id: morceaux[0],
      nom: morceaux[1].replaceAll('&#124;', '|'),
      photoBase64: morceaux[2],
      ajouteLe: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(morceaux[3]) ?? 0,
      ),
    );
  }
}