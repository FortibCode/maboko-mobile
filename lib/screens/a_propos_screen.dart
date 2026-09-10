import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/maboko_theme.dart';

/// À propos de Maboko.
///
/// L'entrée existait dans les paramètres avec une action vide. Elle ne présente
/// que des informations vérifiables : rien n'est inventé sur l'entreprise.
class AProposScreen extends StatelessWidget {
  const AProposScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('À propos de Maboko'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 96,
                  height: 96,
                  clipBehavior: Clip.antiAlias,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                  child: Image.asset('assets/images/Maboko.jpeg', fit: BoxFit.cover),
                ),
                const SizedBox(height: 16),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, fontFamily: 'serif'),
                    children: [
                      TextSpan(text: 'mabok', style: TextStyle(color: MabokoCouleurs.secondaire)),
                      TextSpan(text: 'o', style: TextStyle(color: MabokoCouleurs.accent)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'les mains qui font le Congo',
                  style: TextStyle(color: context.texteSecondaireMaboko, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          _carte(
            context,
            titre: 'Ce que fait Maboko',
            enfants: const [
              _Ligne(Icons.handyman_outlined, 'Trouver un artisan',
                  'Maçons, plombiers, menuisiers, mécaniciens et autres métiers, près de chez vous.'),
              _Ligne(Icons.description_outlined, 'Demander un devis',
                  'Décrivez votre besoin, recevez des propositions, suivez la mission jusqu’au bout.'),
              _Ligne(Icons.local_taxi_outlined, 'Allô Chauffeur',
                  'Réserver une course en moto ou en voiture, et suivre son trajet.'),
            ],
          ),
          const SizedBox(height: 16),

          _carte(
            context,
            titre: 'Application',
            enfants: [
              const _Ligne(Icons.verified_outlined, 'Version',
                  AppConfig.isRelease ? 'Version de production' : 'Version de développement'),
              _Ligne(
                Icons.lock_outline_rounded,
                'Transport des données',
                AppConfig.transportEstSecurise
                    ? 'Chiffré (HTTPS)'
                    : 'Non chiffré — configuration de développement',
              ),
            ],
          ),
          const SizedBox(height: 24),

          Text(
            'Une question ? Écrivez au support depuis l’onglet Messages.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _carte(BuildContext context, {required String titre, required List<Widget> enfants}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titre.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: context.texteSecondaireMaboko,
            ),
          ),
          const SizedBox(height: 12),
          ...enfants,
        ],
      ),
    );
  }
}

class _Ligne extends StatelessWidget {
  const _Ligne(this.icone, this.titre, this.detail);

  final IconData icone;
  final String titre;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, size: 20, color: MabokoCouleurs.secondaire),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: context.texteSecondaireMaboko,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
