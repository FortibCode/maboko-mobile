import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../data/comptes_repository.dart';
import 'selecteur_comptes.dart';

/// Ajout d'un compte : seul le nom est demandé.
///
/// Téléphone, email et mot de passe sont ceux du compte principal, déjà
/// vérifiés : l'artisan ne repasse ni par l'inscription ni par un code SMS.
class NouveauProfilScreen extends StatefulWidget {
  const NouveauProfilScreen({super.key});

  @override
  State<NouveauProfilScreen> createState() => _NouveauProfilScreenState();
}

class _NouveauProfilScreenState extends State<NouveauProfilScreen> {
  final _cleFormulaire = GlobalKey<FormState>();
  final _nom = TextEditingController();
  bool _envoi = false;
  String? _erreur;

  @override
  void dispose() {
    _nom.dispose();
    super.dispose();
  }

  Future<void> _creer() async {
    if (!_cleFormulaire.currentState!.validate()) return;

    setState(() {
      _envoi = true;
      _erreur = null;
    });

    try {
      final session = await const ComptesRepository().ajouter(_nom.text.trim());
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              const Text(
                'Créez un nom de profil',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Ce nouveau compte aura ses propres publications, abonnés et messages. '
                'Il utilise le même numéro, le même email et le même mot de passe que votre compte.',
                style: TextStyle(color: context.texteSecondaireMaboko, height: 1.4),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nom,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                maxLength: 255,
                decoration: InputDecoration(
                  labelText: 'Nom de profil',
                  hintText: 'Ex. : Couture Mama',
                  errorText: _erreur,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (valeur) =>
                    valeur == null || valeur.trim().isEmpty ? 'Choisissez un nom de profil.' : null,
                onFieldSubmitted: (_) => _envoi ? null : _creer(),
              ),
              const SizedBox(height: 12),
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
                      : const Text('Suivant', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
