import 'package:flutter/material.dart';

import '../core/theme/maboko_theme.dart';

/// Politique de confidentialité (§5.1.7).
///
/// Document obligatoire pour la mise en ligne sur les stores, et utile au
/// client qui veut comprendre ce que Maboko garde de lui. Contenu volontairement
/// court : les longues politiques ne sont jamais lues.
class ConfidentialiteScreen extends StatelessWidget {
  const ConfidentialiteScreen({super.key});

  static const _derniereMiseAJour = 'Octobre 2025';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Confidentialité'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _entete(context),
          const SizedBox(height: 20),

          _section(context, 'Ce que nous gardons'),
          _paragraphe(context,
              'Votre nom, votre adresse e-mail, votre numéro de téléphone et '
              'votre ville. Ces informations servent à vous identifier, à '
              'mettre les artisans en relation avec vous, et à sécuriser '
              'votre compte.'),

          _section(context, 'Ce que nous ne gardons jamais'),
          _paragraphe(context,
              'Votre mot de passe (il est chiffré, même nous ne le voyons pas). '
              'Vos contacts d’urgence, votre journal personnel, vos '
              'enregistrements et vos témoignages vidéos restent uniquement '
              'sur votre téléphone.'),

          _section(context, 'Ce que nous partageons'),
          _paragraphe(context,
              'Quand vous contactez un artisan, il voit votre nom, votre ville '
              'et le contenu de votre demande. Rien d’autre. Nous ne vendons '
              'jamais vos données à des tiers.'),

          _section(context, 'Vos droits'),
          _paragraphe(context,
              'Vous pouvez demander une copie de vos données, les corriger, ou '
              'supprimer votre compte à tout moment depuis les paramètres. La '
              'suppression est définitive et efface tout en 30 jours.'),

          _section(context, 'Publicité'),
          _paragraphe(context,
              'Maboko n’affiche aucune publicité. Les artisans paient un '
              'abonnement pour apparaître en avant dans les recherches, mais '
              'cela n’affecte jamais les avis clients.'),

          _section(context, 'Contact'),
          _paragraphe(context,
              'Pour toute question sur vos données : support@maboko.app. '
              'Nous répondons en moins de 48 heures.'),

          const SizedBox(height: 24),
          Center(
            child: Text(
              'Dernière mise à jour : $_derniereMiseAJour',
              style: TextStyle(
                fontSize: 12,
                color: context.texteSecondaireMaboko,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _entete(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.teinteMaboko,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_outlined, size: 22, color: MabokoCouleurs.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Chez Maboko, vos données personnelles restent les vôtres. '
              'Cette page explique en clair ce que nous gardons et pourquoi.',
              style: TextStyle(fontSize: 12.5, height: 1.5, color: context.texteSecondaireMaboko),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String titre) {
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Text(
        titre,
        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _paragraphe(BuildContext context, String texte) {
    return Text(
      texte,
      style: TextStyle(
        fontSize: 13.5,
        height: 1.55,
        color: context.texteSecondaireMaboko,
      ),
    );
  }
}