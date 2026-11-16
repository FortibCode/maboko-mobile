import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/session/role_utilisateur.dart';
import '../../../core/theme/maboko_theme.dart';
import '../../../core/widgets/photo_profil.dart';
import '../../../services/storage_service.dart';
import '../data/comptes_repository.dart';
import 'gerer_comptes_screen.dart';
import 'nouveau_profil_screen.dart';

/// Ouvre le sélecteur de comptes, sur le modèle d'Instagram.
///
/// [context] doit rester monté après la fermeture de la feuille : passer
/// celui de l'écran d'accueil, pas celui du tiroir, qui disparaît avec lui.
Future<void> ouvrirSelecteurComptes(BuildContext context) async {
  final choix = await showModalBottomSheet<_Choix>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => const _FeuilleComptes(),
  );

  if (choix == null || !context.mounted) return;

  switch (choix) {
    case _ChoixCompte(:final compte):
      await basculerVersCompte(context, compte);
    case _ChoixAjouter():
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const NouveauProfilScreen()));
    case _ChoixGerer():
      await Navigator.push(context, MaterialPageRoute(builder: (_) => const GererComptesScreen()));
  }
}

/// Passe sur un autre compte et rouvre l'application sur son espace.
///
/// Un voile bloque l'écran pendant la transition : un second toucher ne doit
/// pas lancer un autre changement avant que le premier soit terminé.
Future<void> basculerVersCompte(BuildContext context, CompteFamille compte) async {
  final messager = ScaffoldMessenger.of(context);
  final navigateur = Navigator.of(context, rootNavigator: true);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(canPop: false, child: _VoileChangement()),
  );

  try {
    final session = await const ComptesRepository().basculer(compte.id);
    if (!context.mounted) return;
    navigateur.pop();
    await ouvrirSessionCompte(context, session);
  } on ApiException catch (e) {
    navigateur.pop();
    messager.showSnackBar(
      SnackBar(content: Text(e.message), backgroundColor: MabokoCouleurs.danger),
    );
  }
}

/// Enregistre la session du compte et repart de son écran d'accueil : tout
/// l'espace se recharge, rien du compte précédent ne reste affiché.
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

/// Photo, nom, spécialité et notifications d'un compte : même ligne dans le
/// sélecteur et dans « Gérer mes comptes ».
class LigneCompte extends StatelessWidget {
  const LigneCompte({super.key, required this.compte, this.onTap, this.trailing});

  final CompteFamille compte;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final nom = compte.nomComplet.isEmpty ? 'Compte Maboko' : compte.nomComplet;
    final details = [
      if (compte.estPrincipal) 'Compte principal',
      if (compte.specialiteAffichable != null) compte.specialiteAffichable!,
    ].join(' · ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          PhotoProfil(url: compte.avatarUrl, nom: nom, taille: 48),
          if (compte.notificationsNonLues > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: MabokoCouleurs.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        nom,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: compte.estActif ? FontWeight.bold : FontWeight.w600),
      ),
      subtitle: compte.suspendu
          ? const Text('Compte suspendu', style: TextStyle(color: MabokoCouleurs.danger, fontSize: 12.5))
          : Text.rich(
              TextSpan(children: [
                if (details.isNotEmpty) TextSpan(text: details),
                if (compte.notificationsNonLues > 0)
                  TextSpan(
                    text: '${details.isNotEmpty ? ' · ' : ''}${compte.notificationsNonLues} '
                        'notification${compte.notificationsNonLues > 1 ? 's' : ''}',
                    style: const TextStyle(color: MabokoCouleurs.danger),
                  ),
              ]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.texteSecondaireMaboko, fontSize: 12.5),
            ),
      trailing: trailing ??
          (compte.estActif ? const Icon(Icons.check_circle_rounded, color: MabokoCouleurs.secondaire) : null),
      onTap: onTap,
    );
  }
}

sealed class _Choix {
  const _Choix();
}

class _ChoixCompte extends _Choix {
  const _ChoixCompte(this.compte);
  final CompteFamille compte;
}

class _ChoixAjouter extends _Choix {
  const _ChoixAjouter();
}

class _ChoixGerer extends _Choix {
  const _ChoixGerer();
}

class _FeuilleComptes extends StatefulWidget {
  const _FeuilleComptes();

  @override
  State<_FeuilleComptes> createState() => _FeuilleComptesState();
}

class _FeuilleComptesState extends State<_FeuilleComptes> {
  late Future<ListeComptes> _liste = const ComptesRepository().lister();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: FutureBuilder<ListeComptes>(
          future: _liste,
          builder: (context, instantane) {
            if (instantane.connectionState != ConnectionState.done) {
              return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
            }

            if (instantane.hasError) {
              final erreur = instantane.error;
              return SizedBox(
                height: 160,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      erreur is ApiException ? erreur.message : 'Comptes indisponibles.',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: () => setState(() => _liste = const ComptesRepository().lister()),
                      child: const Text('Réessayer'),
                    ),
                  ],
                ),
              );
            }

            final liste = instantane.data!;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: context.bordureMaboko),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final compte in liste.comptes)
                        LigneCompte(
                          compte: compte,
                          // Le compte actif est déjà ouvert ; un compte suspendu ne s'ouvre pas.
                          onTap: compte.estActif || compte.suspendu
                              ? null
                              : () => Navigator.pop(context, _ChoixCompte(compte)),
                        ),
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
                          onTap: () => Navigator.pop(context, const _ChoixAjouter()),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(context, const _ChoixGerer()),
                    icon: const Icon(Icons.manage_accounts_outlined),
                    label: const Text('Gérer mes comptes'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _VoileChangement extends StatelessWidget {
  const _VoileChangement();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Card(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 14),
              Text('Changement de compte…'),
            ],
          ),
        ),
      ),
    );
  }
}
