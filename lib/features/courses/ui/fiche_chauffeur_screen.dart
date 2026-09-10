import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/maboko_theme.dart';
import '../data/course_repository.dart';

/// Dépôt de la fiche véhicule du chauffeur (§5.3.1).
///
/// L'inscription crée le compte, jamais la fiche. Sans elle, tout l'espace
/// chauffeur répond 404 et aucune course ne peut être proposée. La route
/// existait côté serveur ; aucun écran de l'application ne l'appelait, si
/// bien qu'un chauffeur inscrit depuis le téléphone restait bloqué.
class FicheChauffeurScreen extends StatefulWidget {
  const FicheChauffeurScreen({super.key, this.premiereFois = false});

  /// Passage juste après la création du compte : pas de retour en arrière,
  /// et l'écran ouvre l'espace chauffeur au lieu de se refermer.
  final bool premiereFois;

  @override
  State<FicheChauffeurScreen> createState() => _FicheChauffeurScreenState();
}

class _FicheChauffeurScreenState extends State<FicheChauffeurScreen> {
  static const _depot = CourseRepository();

  final _cleFormulaire = GlobalKey<FormState>();
  final _modele = TextEditingController();
  final _plaque = TextEditingController();
  final _permis = TextEditingController();

  String _type = 'moto';
  bool _envoi = false;

  @override
  void dispose() {
    _modele.dispose();
    _plaque.dispose();
    _permis.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_cleFormulaire.currentState!.validate()) return;

    setState(() => _envoi = true);

    try {
      await _depot.enregistrerFiche(
        typeVehicule: _type,
        modele: _modele.text.trim(),
        plaque: _plaque.text.trim().toUpperCase(),
        permis: _permis.text.trim().toUpperCase(),
      );

      if (!mounted) return;
      setState(() => _envoi = false);

      _informer(
        'Véhicule enregistré. Il est en cours de validation.',
        MabokoCouleurs.succes,
      );

      if (widget.premiereFois) {
        Navigator.pushNamedAndRemoveUntil(context, '/chauffeur', (route) => false);

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
        title: Text(widget.premiereFois ? 'Votre véhicule' : 'Ma fiche véhicule'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: !widget.premiereFois,
      ),
      body: Form(
        key: _cleFormulaire,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _encadre(
              widget.premiereFois
                  ? 'Dernière étape : décrivez le véhicule avec lequel vous '
                      'transporterez vos passagers. L’équipe Maboko vérifie '
                      'la plaque et le permis avant votre première course.'
                  : 'Ces informations sont vérifiées par l’équipe Maboko. '
                      'Toute modification remet votre véhicule en validation.',
            ),
            const SizedBox(height: 22),

            _titre('Type de véhicule'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _choixType('moto', 'Moto', Icons.two_wheeler_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _choixType('voiture', 'Voiture', Icons.directions_car_rounded),
                ),
              ],
            ),
            const SizedBox(height: 22),

            TextFormField(
              controller: _modele,
              textCapitalization: TextCapitalization.words,
              decoration: _decoration('Marque et modèle', Icons.build_outlined,
                  indice: _type == 'moto' ? 'Ex. : Yamaha Crux' : 'Ex. : Toyota Corolla'),
              validator: (valeur) => (valeur ?? '').trim().length < 3
                  ? 'Indiquez la marque et le modèle.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _plaque,
              textCapitalization: TextCapitalization.characters,
              decoration: _decoration('Plaque d’immatriculation', Icons.badge_outlined,
                  indice: 'Ex. : BZV-777-CG'),
              validator: (valeur) => (valeur ?? '').trim().length < 4
                  ? 'La plaque est obligatoire.'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _permis,
              textCapitalization: TextCapitalization.characters,
              decoration: _decoration('Numéro de permis de conduire',
                  Icons.credit_card_outlined),
              validator: (valeur) => (valeur ?? '').trim().length < 4
                  ? 'Le numéro de permis est obligatoire.'
                  : null,
            ),
            const SizedBox(height: 24),

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
          ],
        ),
      ),
    );
  }

  Widget _choixType(String valeur, String libelle, IconData icone) {
    final choisi = _type == valeur;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => setState(() => _type = valeur),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: choisi
              ? MabokoCouleurs.secondaire.withValues(alpha: 0.12)
              : context.surfaceMaboko,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: choisi ? MabokoCouleurs.secondaire : context.bordureMaboko,
            width: choisi ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icone,
                size: 28,
                color: choisi ? MabokoCouleurs.secondaire : context.texteSecondaireMaboko),
            const SizedBox(height: 8),
            Text(
              libelle,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: choisi ? FontWeight.bold : FontWeight.normal,
                color: choisi ? MabokoCouleurs.secondaire : context.texteFortMaboko,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _titre(String titre) => Text(
        titre,
        style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.bold, color: context.texteFortMaboko),
      );

  Widget _encadre(String texte) {
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
          const Icon(Icons.local_taxi_outlined, size: 20, color: MabokoCouleurs.secondaire),
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
