import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/choix_photo.dart';
import '../../metiers/data/metier_repository.dart';
import '../../metiers/models/metier.dart';
import '../data/comptes_repository.dart';
import 'selecteur_comptes.dart';

/// Ajout d'un compte artisan : nom, métiers, présentation et photo.
///
/// Téléphone, email et mot de passe sont ceux du compte principal, déjà
/// vérifiés : l'artisan ne repasse ni par l'inscription ni par un code SMS.
/// Zone d'intervention et adresse se complètent ensuite dans « Mes métiers et
/// ma zone », comme pour tout compte.
class NouveauProfilScreen extends StatefulWidget {
  const NouveauProfilScreen({super.key});

  /// Métiers retenus au plus, comme sur la fiche artisan (côté API : 5).
  static const maxMetiers = 3;

  @override
  State<NouveauProfilScreen> createState() => _NouveauProfilScreenState();
}

class _NouveauProfilScreenState extends State<NouveauProfilScreen> {
  final _cleFormulaire = GlobalKey<FormState>();
  final _nom = TextEditingController();
  final _bio = TextEditingController();

  late final Future<List<Metier>> _metiers = const MetierRepository().lister();
  final Set<String> _metiersChoisis = {};
  String? _photo;

  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _nom.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _choisirPhoto() async {
    final photo = await choisirPhoto(context, largeurMax: 800);
    if (photo != null && mounted) setState(() => _photo = photo);
  }

  Future<void> _creer() async {
    if (!_cleFormulaire.currentState!.validate()) return;

    if (_metiersChoisis.isEmpty) {
      setState(() => _erreur = 'Choisissez au moins un métier pour ce compte.');
      return;
    }

    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      final session = await const ComptesRepository().ajouter(
        nom: _nom.text.trim(),
        metiers: _metiersChoisis.toList(),
        bio: _bio.text,
        photo: _photo,
      );
      if (!mounted) return;

      // Comme sur Instagram, le nouveau compte s'ouvre aussitôt.
      await ouvrirSessionCompte(context, session);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _envoi = false;
        _erreur = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Annuler',
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _cleFormulaire,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              const Text('Nouveau compte artisan', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                'Ses propres prestations, commandes, avis et messages. '
                'Même numéro, même email et même mot de passe que votre compte.',
                style: TextStyle(color: context.texteSecondaireMaboko, height: 1.4),
              ),
              const SizedBox(height: 22),
              Center(child: _photoDuCompte()),
              const SizedBox(height: 22),
              TextFormField(
                controller: _nom,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 255,
                decoration: _decoration('Nom professionnel', 'Ex. : Couture Mama'),
                validator: (valeur) =>
                    valeur == null || valeur.trim().isEmpty ? 'Choisissez un nom pour ce compte.' : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Métiers (${NouveauProfilScreen.maxMetiers} au plus)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _choixMetiers(),
              const SizedBox(height: 18),
              TextFormField(
                controller: _bio,
                maxLines: 3,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: _decoration('Présentation (facultatif)', 'Ce que propose ce compte'),
              ),
              if (_erreur != null) ...[
                const SizedBox(height: 4),
                Text(_erreur!, style: const TextStyle(color: MabokoCouleurs.danger)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _envoi ? null : _creer,
                  style: FilledButton.styleFrom(
                    backgroundColor: MabokoCouleurs.secondaire,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                  ),
                  child: _envoi
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text('Créer le compte', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String libelle, String indice) => InputDecoration(
        labelText: libelle,
        hintText: indice,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      );

  Widget _photoDuCompte() {
    final octets = _photo == null ? null : base64Decode(_photo!.split(',').last);

    return GestureDetector(
      onTap: _envoi ? null : _choisirPhoto,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CircleAvatar(
            radius: 46,
            backgroundColor: context.bordureMaboko,
            backgroundImage: octets == null ? null : MemoryImage(octets),
            child: octets == null
                ? Icon(Icons.storefront_outlined, size: 36, color: context.texteSecondaireMaboko)
                : null,
          ),
          const Positioned(
            right: -2,
            bottom: -2,
            child: CircleAvatar(
              radius: 15,
              backgroundColor: MabokoCouleurs.secondaire,
              child: Icon(Icons.photo_camera_rounded, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _choixMetiers() {
    return FutureBuilder<List<Metier>>(
      future: _metiers,
      builder: (context, instantane) {
        if (instantane.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (instantane.hasError) {
          return Text('Métiers indisponibles.', style: TextStyle(color: context.texteSecondaireMaboko));
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final metier in instantane.data!)
              FilterChip(
                label: Text(metier.nom),
                selected: _metiersChoisis.contains(metier.slug),
                selectedColor: MabokoCouleurs.secondaire.withValues(alpha: 0.18),
                checkmarkColor: MabokoCouleurs.secondaire,
                onSelected: (choisi) => setState(() {
                  _erreur = null;
                  if (!choisi) {
                    _metiersChoisis.remove(metier.slug);
                  } else if (_metiersChoisis.length < NouveauProfilScreen.maxMetiers) {
                    _metiersChoisis.add(metier.slug);
                  }
                }),
              ),
          ],
        );
      },
    );
  }
}
