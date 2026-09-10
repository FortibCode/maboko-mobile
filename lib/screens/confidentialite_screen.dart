import 'package:flutter/material.dart';

import '../core/network/api.dart';
import '../core/network/api_exception.dart';
import '../core/theme/maboko_theme.dart';
import '../services/storage_service.dart';
import '../features/compte/data/google_auth.dart';

/// Confidentialité et sécurité du compte.
///
/// L'entrée existait dans les paramètres sans action. La suppression de compte,
/// elle, était déjà exposée par l'API mais restée inaccessible : un utilisateur
/// ne pouvait pas fermer son compte depuis l'application.
class ConfidentialiteScreen extends StatefulWidget {
  const ConfidentialiteScreen({super.key});

  @override
  State<ConfidentialiteScreen> createState() => _ConfidentialiteScreenState();
}

class _ConfidentialiteScreenState extends State<ConfidentialiteScreen> {
  bool _suppression = false;

  Future<void> _supprimerCompte() async {
    final motDePasse = TextEditingController();

    // Le mot de passe est redemandé : un téléphone laissé déverrouillé ne doit
    // pas suffire à effacer un compte. L'API l'exige également.
    final confirme = await showDialog<bool>(
      context: context,
      builder: (contexte) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer définitivement ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Votre compte, vos demandes et vos messages seront effacés. '
              'Cette action est irréversible.',
              style: TextStyle(height: 1.4, fontSize: 13.5),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: motDePasse,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Confirmez votre mot de passe',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(contexte, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: MabokoCouleurs.danger),
            onPressed: () => Navigator.pop(contexte, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;

    if (motDePasse.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe est obligatoire.'),
          backgroundColor: MabokoCouleurs.danger,
        ),
      );

      return;
    }

    setState(() => _suppression = true);

    try {
      await api.delete('/compte', corps: {'password': motDePasse.text});
      await const GoogleAuth().deconnecter();
      await StorageService.clearAll();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _suppression = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Confidentialité et sécurité'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _carte(
            titre: 'Mot de passe',
            enfants: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lock_reset_rounded, color: MabokoCouleurs.secondaire),
                title: const Text('Changer mon mot de passe', style: TextStyle(fontSize: 14)),
                subtitle: const Text(
                  'Un code vous sera envoyé par SMS.',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                onTap: () => Navigator.pushNamed(context, '/forgot'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _carte(
            titre: 'Vos données',
            enfants: const [
              _Info(
                Icons.lock_outline_rounded,
                'Vos pièces d’identité sont chiffrées',
                'Elles ne servent qu’à la vérification de votre profil.',
              ),
              _Info(
                Icons.visibility_off_outlined,
                'Votre numéro n’est pas public',
                'Il n’est transmis qu’à l’artisan ou au chauffeur d’une mission acceptée.',
              ),
            ],
          ),
          const SizedBox(height: 24),

          OutlinedButton.icon(
            onPressed: _suppression ? null : _supprimerCompte,
            icon: _suppression
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: MabokoCouleurs.danger),
                  )
                : const Icon(Icons.delete_forever_rounded),
            label: const Text('Supprimer mon compte'),
            style: OutlinedButton.styleFrom(
              foregroundColor: MabokoCouleurs.danger,
              side: const BorderSide(color: MabokoCouleurs.danger),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _carte({required String titre, required List<Widget> enfants}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 8),
          ...enfants,
        ],
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icone, this.titre, this.detail);

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
          Icon(icone, size: 19, color: MabokoCouleurs.secondaire),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titre, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12,
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
