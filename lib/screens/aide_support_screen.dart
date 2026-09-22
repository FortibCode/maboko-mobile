import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/theme/maboko_theme.dart';
import 'conseils_screen.dart';

/// Aide et support (§5.1.7).
///
/// Point d'entrée unique vers l'assistance : FAQ, conseils, contact par
/// e-mail et WhatsApp. L'écran précédent ouvrait directement la messagerie
/// interne, ce qui ne répondait ni aux questions fréquentes ni aux urgences.
class AideSupportScreen extends StatelessWidget {
  const AideSupportScreen({super.key});

  /// Adresse de support de Maboko. À ajuster à la mise en production.
  static const _emailSupport = 'support@maboko.app';

  /// Numéro WhatsApp du support, format international sans espaces.
  static const _whatsappSupport = '242061234567';

  static const _faq = <_Question>[
    _Question(
      question: 'Comment demander un devis à un artisan ?',
      reponse: 'Ouvrez la fiche d’un artisan depuis l’onglet Découvrir, '
          'puis appuyez sur « Demander un devis ». Décrivez votre besoin, '
          'ajoutez une photo si possible, et précisez votre localisation. '
          'L’artisan vous répond dans l’application.',
    ),
    _Question(
      question: 'Combien de temps pour recevoir une réponse ?',
      reponse: 'La plupart des artisans répondent dans les 2 heures. Si '
          'aucune réponse n’arrive après 24 heures, vous pouvez relancer '
          'directement depuis la conversation, ou contacter le support.',
    ),
    _Question(
      question: 'Comment fonctionne Allô Chauffeur ?',
      reponse: 'Depuis l’accueil, appuyez sur « Allô Chauffeur ». Indiquez '
          'votre point de départ et votre destination, choisissez moto ou '
          'voiture : le tarif estimé s’affiche avant la réservation. Le '
          'chauffeur le plus proche est contacté automatiquement.',
    ),
    _Question(
      question: 'Puis-je payer en espèces ?',
      reponse: 'Le paiement par Mobile Money (Airtel Money ou MTN Mobile '
          'Money) est recommandé : il laisse une trace en cas de litige. '
          'Pour les espèces, arrangez-vous directement avec l’artisan, mais '
          'gardez le devis dans l’application comme preuve.',
    ),
    _Question(
      question: 'Que faire si un artisan ne vient pas ?',
      reponse: 'Signalez la demande depuis son détail : bouton « Signaler ». '
          'L’équipe Maboko examine le dossier sous 48 heures. L’artisan peut '
          'être suspendu le temps de l’enquête.',
    ),
    _Question(
      question: 'Comment vérifier qu’un artisan est fiable ?',
      reponse: 'Trois signaux : le badge « Profil vérifié » (identité '
          'contrôlée), les avis clients récents, et son portfolio de '
          'réalisations. Un artisan sans historique n’est pas forcément '
          'mauvais, mais soyez plus prudent sur les gros chantiers.',
    ),
    _Question(
      question: 'Comment supprimer mon compte ?',
      reponse: 'Depuis Profil → Paramètres avancés → Supprimer mon compte. '
          'La suppression est définitive et efface toutes vos données : '
          'demandes, messages, avis. Vous pouvez aussi écrire au support.',
    ),
  ];

  Future<void> _ouvrirLien(BuildContext context, Uri uri) async {
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible d’ouvrir cette application.'),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Aide et support'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _encadre(context),
          const SizedBox(height: 20),

          _section(context, 'Nous contacter'),
          _carteAction(
            context,
            icone: Icons.chat_bubble_outline_rounded,
            couleur: const Color(0xFF25D366),
            titre: 'WhatsApp',
            sous: 'Réponse en quelques minutes, 8h – 20h',
            onTap: () => _ouvrirLien(
              context,
              Uri.parse('https://wa.me/$_whatsappSupport'),
            ),
          ),
          const SizedBox(height: 10),
          _carteAction(
            context,
            icone: Icons.email_outlined,
            couleur: MabokoCouleurs.secondaire,
            titre: 'E-mail',
            sous: _emailSupport,
            onTap: () => _ouvrirLien(
              context,
              Uri(
                scheme: 'mailto',
                path: _emailSupport,
                query: 'subject=Support Maboko',
              ),
            ),
          ),
          const SizedBox(height: 10),
          _carteAction(
            context,
            icone: Icons.tips_and_updates_outlined,
            couleur: MabokoCouleurs.accent,
            titre: 'Conseils et assistances',
            sous: 'Réponses rapides aux questions fréquentes',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ConseilsScreen()),
            ),
          ),

          const SizedBox(height: 24),
          _section(context, 'Questions fréquentes'),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.bordureMaboko),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: Column(
                children: _faq
                    .map(
                      (q) => ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                        title: Text(
                          q.question,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              q.reponse,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: context.texteSecondaireMaboko,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        titre,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.texteSecondaireMaboko,
          letterSpacing: .3,
        ),
      ),
    );
  }

  Widget _encadre(BuildContext context) {
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
          const Icon(Icons.support_agent_rounded, size: 22, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Une question ? Consultez d’abord les questions fréquentes : '
              'la réponse y est souvent. Sinon, l’équipe vous répond par '
              'WhatsApp ou par e-mail.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: context.texteSecondaireMaboko),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carteAction(
    BuildContext context, {
    required IconData icone,
    required Color couleur,
    required String titre,
    required String sous,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Theme.of(context).cardColor,
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
                  color: couleur.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(icone, color: couleur, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titre,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                    const SizedBox(height: 3),
                    Text(
                      sous,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.texteSecondaireMaboko),
            ],
          ),
        ),
      ),
    );
  }
}

class _Question {
  const _Question({required this.question, required this.reponse});

  final String question;
  final String reponse;
}