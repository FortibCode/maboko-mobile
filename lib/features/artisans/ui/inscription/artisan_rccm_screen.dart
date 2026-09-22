import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/maboko_theme.dart';
import 'artisan_termine_screen.dart';
import 'inscription_artisan_data.dart';

/// Étape 5 du parcours d'inscription artisan : le RCCM.
///
/// Un artisan enregistré au RCCM inspire plus confiance : c'est un signal
/// de sérieux que le client voit sur la fiche. Ceux qui n'en ont pas
/// déposent une pièce d'identité à la place.
class ArtisanRccmScreen extends StatefulWidget {
  const ArtisanRccmScreen({super.key, required this.nomComplet});

  final String nomComplet;

  @override
  State<ArtisanRccmScreen> createState() => _ArtisanRccmScreenState();
}

class _ArtisanRccmScreenState extends State<ArtisanRccmScreen> {
  bool? _aRccm;
  String? _photoRccm;
  String? _photoPiece;
  bool _chargement = true;
  bool _envoiPhoto = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final data = await InscriptionArtisanData.charger();

    if (!mounted) return;
    setState(() {
      _aRccm = data?.aRccm;
      _photoRccm = data?.photoRccm;
      _photoPiece = data?.photoPiece;
      _chargement = false;
    });
  }

  Future<void> _choisirPhoto({required bool rccm}) async {
    setState(() => _envoiPhoto = true);

    try {
      final fichier = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1800,
        imageQuality: 80,
      );

      if (fichier == null) {
        setState(() => _envoiPhoto = false);
        return;
      }

      final octets = await fichier.readAsBytes();
      if (!mounted) return;

      final encode = 'data:image/jpeg;base64,${base64Encode(octets)}';

      setState(() {
        if (rccm) {
          _photoRccm = encode;
        } else {
          _photoPiece = encode;
        }
        _envoiPhoto = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _envoiPhoto = false);
      _informer('Impossible de prendre la photo sur cet appareil.',
          MabokoCouleurs.danger);
    }
  }

  Future<void> _continuer() async {
    if (_aRccm == null) {
      _informer('Indiquez si vous avez un RCCM.', MabokoCouleurs.danger);
      return;
    }

    if (_aRccm == true && _photoRccm == null) {
      _informer('Ajoutez la photo de votre RCCM.', MabokoCouleurs.danger);
      return;
    }

    if (_aRccm == false && _photoPiece == null) {
      _informer('Ajoutez la photo de votre pièce d’identité.',
          MabokoCouleurs.danger);
      return;
    }

    final data = (await InscriptionArtisanData.charger()) ??
        const InscriptionArtisanData();
    await data
        .copierAvec(
          aRccm: _aRccm,
          photoRccm: _photoRccm,
          photoPiece: _photoPiece,
        )
        .sauvegarder();

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ArtisanTermineScreen(nomComplet: widget.nomComplet),
      ),
    );
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
        title: const Text('Enregistrement'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _chargement
          ? const Center(
              child: CircularProgressIndicator(color: MabokoCouleurs.secondaire),
            )
          : Column(
              children: [
                Expanded(child: _corps()),
                _piedDePage(),
              ],
            ),
    );
  }

  Widget _corps() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        _encadre(),
        const SizedBox(height: 20),
        _titre(),
        const SizedBox(height: 14),
        _carteOui(),
        const SizedBox(height: 10),
        _carteNon(),
        if (_aRccm != null) ...[
          const SizedBox(height: 22),
          _sectionPhoto(),
        ],
      ],
    );
  }

  Widget _titre() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Êtes-vous enregistré au RCCM ?',
          style: TextStyle(
            fontSize: 16.5,
            fontWeight: FontWeight.bold,
            color: context.texteFortMaboko,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Le Registre du Commerce et du Crédit Mobilier atteste que votre '
          'activité est déclarée. Un atout de confiance.',
          style: TextStyle(
            fontSize: 13,
            height: 1.45,
            color: context.texteSecondaireMaboko,
          ),
        ),
      ],
    );
  }

  Widget _carteOui() {
    final actif = _aRccm == true;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _aRccm = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: actif ? MabokoCouleurs.succes : context.bordureMaboko,
              width: actif ? 1.6 : 1,
            ),
            color: actif
                ? MabokoCouleurs.succes.withValues(alpha: 0.06)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.verified_rounded,
                size: 24,
                color: actif ? MabokoCouleurs.succes : context.texteSecondaireMaboko,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Oui, j’ai un RCCM',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: actif ? FontWeight.bold : FontWeight.w600,
                        color: actif
                            ? MabokoCouleurs.succes
                            : context.texteFortMaboko,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Vous ajouterez la photo du document à l’étape suivante.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.texteSecondaireMaboko,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                actif
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: actif ? MabokoCouleurs.succes : context.bordureMaboko,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carteNon() {
    final actif = _aRccm == false;

    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _aRccm = false),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: actif ? MabokoCouleurs.secondaire : context.bordureMaboko,
              width: actif ? 1.6 : 1,
            ),
            color: actif
                ? MabokoCouleurs.secondaire.withValues(alpha: 0.06)
                : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.badge_outlined,
                size: 24,
                color: actif
                    ? MabokoCouleurs.secondaire
                    : context.texteSecondaireMaboko,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Non, je n’en ai pas',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: actif ? FontWeight.bold : FontWeight.w600,
                        color: actif
                            ? MabokoCouleurs.secondaire
                            : context.texteFortMaboko,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Vous déposerez une pièce d’identité à la place.',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.texteSecondaireMaboko,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                actif
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: actif
                    ? MabokoCouleurs.secondaire
                    : context.bordureMaboko,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionPhoto() {
    final aRccm = _aRccm == true;
    final photo = aRccm ? _photoRccm : _photoPiece;
    final libelle = aRccm ? 'Photo du RCCM' : 'Photo de la pièce d’identité';
    final icone = aRccm ? Icons.description_outlined : Icons.badge_outlined;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          libelle,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: context.texteFortMaboko,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Prenez la photo en pleine lumière, le document entier dans le cadre.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: context.texteSecondaireMaboko,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _envoiPhoto ? null : () => _choisirPhoto(rccm: aRccm),
          child: Container(
            height: 180,
            decoration: BoxDecoration(
              color: context.surfaceMaboko,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: photo != null
                    ? MabokoCouleurs.succes
                    : context.bordureMaboko,
                width: photo != null ? 1.6 : 1,
              ),
            ),
            child: _envoiPhoto
                ? const Center(
                    child: CircularProgressIndicator(
                        color: MabokoCouleurs.secondaire),
                  )
                : photo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.memory(
                          base64Decode(photo.split(',').last),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            icone,
                            size: 36,
                            color: MabokoCouleurs.secondaire,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Prendre la photo',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
          ),
        ),
        if (photo != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: MabokoCouleurs.succes, size: 18),
              const SizedBox(width: 6),
              const Text(
                'Photo ajoutée',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: MabokoCouleurs.succes,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _envoiPhoto ? null : () => _choisirPhoto(rccm: aRccm),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reprendre'),
                style: TextButton.styleFrom(
                  foregroundColor: MabokoCouleurs.secondaire,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _encadre() {
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
          const Icon(Icons.lock_outline_rounded,
              size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Vos documents ne sont visibles que de l’équipe Maboko, jamais '
              'des clients. Ils servent uniquement à vérifier votre activité.',
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

  Widget _piedDePage() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: SizedBox(
          height: 52,
          width: double.infinity,
          child: FilledButton(
            onPressed: _aRccm == null ? null : _continuer,
            style: FilledButton.styleFrom(
              backgroundColor: MabokoCouleurs.secondaire,
              foregroundColor: Colors.white,
              disabledBackgroundColor: context.bordureMaboko,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Continuer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
            ),
          ),
        ),
      ),
    );
  }
}