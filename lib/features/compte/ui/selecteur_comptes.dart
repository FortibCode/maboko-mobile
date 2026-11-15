import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/role_utilisateur.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/photo_profil.dart';
import '../../../services/storage_service.dart';
import '../data/comptes_repository.dart';
import 'nouveau_profil_screen.dart';

/// Ouvre le sélecteur de comptes, sur le modèle d'Instagram.
///
/// [context] doit rester monté après la fermeture de la feuille : passer
/// celui de l'écran d'accueil, pas celui du tiroir, qui disparaît avec lui.
Future<void> ouvrirSelecteurComptes(BuildContext context) async {
  final choix = await showModalBottomSheet<_Choix>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _FeuilleComptes(),
  );

  if (choix == null || !context.mounted) return;

  if (choix.ajouter) {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NouveauProfilScreen()),
    );
    return;
  }

  await basculerVersCompte(context, choix.compte!);
}

/// Passe sur un autre compte et rouvre l'application sur son espace.
Future<void> basculerVersCompte(BuildContext context, CompteFamille compte) async {
  final messager = ScaffoldMessenger.of(context);

  try {
    final session = await const ComptesRepository().basculer(compte.id);
    await ouvrirSessionCompte(context, session);
  } on ApiException catch (e) {
    messager.showSnackBar(
      SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
    );
  }
}

/// Enregistre la session du compte et repart de son écran d'accueil.
Future<void> ouvrirSessionCompte(BuildContext context, SessionCompte session) async {
  await StorageService.changerDeCompte(jeton: session.jeton, utilisateur: session.utilisateur);

  if (!context.mounted) return;

  final nom = (session.utilisateur['nom'] as String?)?.trim();
  ouvrirEspace(
    context,
    RoleMaboko.depuis(session.utilisateur['role'] as String?),
    nom: nom == null || nom.isEmpty ? 'Utilisateur' : nom,
  );
}

class _Choix {
  const _Choix.compte(CompteFamille this.compte) : ajouter = false;
  const _Choix.ajouter()
      : compte = null,
        ajouter = true;

  final CompteFamille? compte;
  final bool ajouter;
}

class _FeuilleComptes extends StatefulWidget {
  const _FeuilleComptes();

  @override
  State<_FeuilleComptes> createState() => _FeuilleComptesState();
}

class _FeuilleComptesState extends State<_FeuilleComptes> {
  late final Future<ListeComptes> _liste = const ComptesRepository().lister();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FutureBuilder<ListeComptes>(
          future: _liste,
          builder: (context, instantane) {
            if (instantane.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 140,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (instantane.hasError) {
              final erreur = instantane.error;
              return SizedBox(
                height: 140,
                child: Center(
                  child: Text(
                    erreur is ApiException ? erreur.message : 'Comptes indisponibles.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final liste = instantane.data!;

            return Container(
              decoration: BoxDecoration(
                border: Border.all(color: context.bordureMaboko),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final compte in liste.comptes) _ligneCompte(context, compte),
                  if (liste.peutAjouter)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: context.bordureMaboko,
                        child: const Icon(Icons.add_rounded, color: MabokoCouleurs.secondaire),
                      ),
                      title: const Text('Ajouter un compte'),
                      subtitle: Text(
                        '${liste.comptes.length} sur ${liste.maximum}',
                        style: TextStyle(color: context.texteSecondaireMaboko, fontSize: 12.5),
                      ),
                      onTap: () => Navigator.pop(context, const _Choix.ajouter()),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _ligneCompte(BuildContext context, CompteFamille compte) {
    final nom = compte.nomComplet.isEmpty ? 'Compte Maboko' : compte.nomComplet;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: PhotoProfil(url: compte.avatarUrl, nom: nom, taille: 48),
      title: Text(nom, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: compte.suspendu
          ? const Text('Compte suspendu', style: TextStyle(color: MabokoCouleurs.danger, fontSize: 12.5))
          : compte.notificationsNonLues > 0
              ? Text(
                  '● ${compte.notificationsNonLues} notification${compte.notificationsNonLues > 1 ? 's' : ''}',
                  style: const TextStyle(color: MabokoCouleurs.danger, fontSize: 12.5),
                )
              : null,
      trailing: compte.estActif
          ? const Icon(Icons.check_circle_rounded, color: MabokoCouleurs.secondaire)
          : null,
      // Le compte actif est déjà ouvert ; un compte suspendu ne s'ouvre pas.
      onTap: compte.estActif || compte.suspendu
          ? null
          : () => Navigator.pop(context, _Choix.compte(compte)),
    );
  }
}
