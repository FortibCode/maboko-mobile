import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/etats.dart';
import '../data/profil_repository.dart';

/// Modification des informations du compte.
///
/// L'entrée « Modifier mon profil » figurait dans les paramètres sans action,
/// et aucune route ne le permettait : le nom et la ville saisis à l'inscription
/// étaient définitifs.
class ModifierProfilScreen extends StatefulWidget {
  const ModifierProfilScreen({super.key});

  @override
  State<ModifierProfilScreen> createState() => _ModifierProfilScreenState();
}

class _ModifierProfilScreenState extends State<ModifierProfilScreen> {
  static const _depot = ProfilRepository();
  final _formulaire = GlobalKey<FormState>();

  final _nom = TextEditingController();
  final _prenom = TextEditingController();
  final _email = TextEditingController();
  final _ville = TextEditingController();
  final _quartier = TextEditingController();

  bool _chargement = true;
  bool _envoi = false;
  String? _erreur;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  @override
  void dispose() {
    for (final c in [_nom, _prenom, _email, _ville, _quartier]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final profil = await _depot.moi();
      if (!mounted) return;

      // Le nom complet renvoyé par l'API concatène prénom et nom : on le
      // rescinde pour que chaque champ reste modifiable séparément.
      setState(() {
        _nom.text = profil.nom ?? '';
        _prenom.text = profil.prenom ?? '';
        _email.text = profil.email ?? '';
        _ville.text = profil.ville ?? '';
        _quartier.text = profil.quartier ?? '';
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

  Future<void> _enregistrer() async {
    if (!_formulaire.currentState!.validate()) return;

    setState(() => _envoi = true);

    try {
      await _depot.modifier(
        nom: _nom.text.trim(),
        prenom: _prenom.text.trim(),
        email: _email.text.trim(),
        ville: _ville.text.trim(),
        quartier: _quartier.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour.'),
          backgroundColor: MabokoCouleurs.succes,
        ),
      );
      Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _envoi = false);
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
        title: const Text('Modifier mon profil'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _corps(),
    );
  }

  Widget _corps() {
    if (_chargement) return const ChargementEnCours();

    if (_erreur != null) {
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 60),
          EtatErreur(message: _erreur!, onReessayer: _charger),
        ],
      );
    }

    return Form(
      key: _formulaire,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _champ(_prenom, 'Prénom', Icons.badge_outlined),
          _champ(_nom, 'Nom', Icons.person_outline, obligatoire: true),
          _champ(_email, 'Adresse e-mail', Icons.mail_outline, courriel: true),
          const SizedBox(height: 8),
          const Text(
            'Localisation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          _champ(_ville, 'Ville', Icons.location_city_outlined),
          _champ(_quartier, 'Quartier', Icons.place_outlined),
          const SizedBox(height: 12),
          Text(
            'Votre numéro de téléphone identifie votre compte et sert à '
            'récupérer votre mot de passe : il ne se modifie pas ici.',
            style: TextStyle(fontSize: 12, color: context.texteSecondaireMaboko, height: 1.4),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _envoi ? null : _enregistrer,
              style: ElevatedButton.styleFrom(
                backgroundColor: MabokoCouleurs.secondaire,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _envoi
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Enregistrer', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _champ(
    TextEditingController controleur,
    String libelle,
    IconData icone, {
    bool obligatoire = false,
    bool courriel = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controleur,
        keyboardType: courriel ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: libelle,
          prefixIcon: Icon(icone, color: MabokoCouleurs.secondaire, size: 20),
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
        ),
        validator: (valeur) {
          final v = (valeur ?? '').trim();
          if (obligatoire && v.isEmpty) return 'Ce champ est obligatoire.';
          if (courriel && v.isNotEmpty && !v.contains('@')) {
            return 'Adresse e-mail invalide.';
          }

          return null;
        },
      ),
    );
  }
}
