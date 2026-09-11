import 'package:flutter/material.dart';

import '../theme/maboko_theme.dart';
import 'adresse_api.dart';
import 'app_config.dart';

/// Boîte de réglage de l'adresse du serveur.
///
/// Le poste de développement reçoit son adresse en DHCP : elle change au
/// renouvellement du bail, et l'application ne joint plus rien. Sans ce
/// réglage, il fallait recompiler à chaque fois.
///
/// Absente des compilations de production, où l'adresse est celle du domaine
/// et n'a aucune raison d'être modifiée.
Future<void> ouvrirReglageAdresse(BuildContext context) async {
  if (AppConfig.isRelease) return;

  final champ = TextEditingController(text: AdresseApi.valeur);
  String? erreur;

  await showDialog<void>(
    context: context,
    builder: (contexte) => StatefulBuilder(
      builder: (contexte, rafraichir) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Adresse du serveur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saisissez l’adresse affichée par votre backend au démarrage. '
              'Le port et « /api/v1 » sont ajoutés si vous les omettez.',
              style: TextStyle(fontSize: 12.5, height: 1.4, color: contexte.texteSecondaireMaboko),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: champ,
              autofocus: true,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: '192.168.1.83',
                errorText: erreur,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Valeur d’origine : ${AdresseApi.valeurCompilee}',
              style: TextStyle(fontSize: 11, color: contexte.texteSecondaireMaboko),
            ),
          ],
        ),
        actions: [
          if (AdresseApi.personnalisee)
            TextButton(
              onPressed: () async {
                await AdresseApi.reinitialiser();
                if (contexte.mounted) Navigator.pop(contexte);
              },
              child: const Text('Réinitialiser'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(contexte),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MabokoCouleurs.secondaire),
            onPressed: () async {
              final motif = await AdresseApi.definir(champ.text);

              if (motif != null) {
                rafraichir(() => erreur = motif);

                return;
              }

              if (contexte.mounted) Navigator.pop(contexte);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );

  champ.dispose();
}
