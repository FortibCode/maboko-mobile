import '../../../core/network/api.dart';

/// Un des comptes de la personne connectée (multi-comptes artisan).
class CompteFamille {
  const CompteFamille({
    required this.id,
    required this.nom,
    required this.role,
    this.prenom,
    this.avatarUrl,
    this.estPrincipal = false,
    this.estActif = false,
    this.suspendu = false,
    this.notificationsNonLues = 0,
  });

  final int id;
  final String nom;
  final String? prenom;
  final String? avatarUrl;
  final String role;
  final bool estPrincipal;

  /// Compte sur lequel le téléphone est connecté en ce moment.
  final bool estActif;
  final bool suspendu;
  final int notificationsNonLues;

  String get nomComplet => [prenom, nom].where((m) => m != null && m.trim().isNotEmpty).join(' ');

  factory CompteFamille.depuisJson(Map<String, dynamic> json) => CompteFamille(
        id: json['id'] as int,
        nom: json['nom'] as String? ?? '',
        prenom: json['prenom'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        role: json['role'] as String? ?? 'artisan',
        estPrincipal: json['estPrincipal'] as bool? ?? false,
        estActif: json['estActif'] as bool? ?? false,
        suspendu: json['suspendu'] as bool? ?? false,
        notificationsNonLues: json['notificationsNonLues'] as int? ?? 0,
      );
}

class ListeComptes {
  const ListeComptes({required this.comptes, required this.peutAjouter, required this.maximum});

  final List<CompteFamille> comptes;
  final bool peutAjouter;
  final int maximum;
}

/// Session ouverte sur un compte : jeton et utilisateur, comme à la connexion.
class SessionCompte {
  const SessionCompte({required this.jeton, required this.utilisateur});

  final String jeton;
  final Map<String, dynamic> utilisateur;

  factory SessionCompte.depuisJson(Map<String, dynamic> json) => SessionCompte(
        jeton: json['token'] as String,
        utilisateur: json['user'] as Map<String, dynamic>,
      );
}

/// Multi-comptes artisan, sur le modèle d'Instagram : une connexion, jusqu'à
/// trois comptes, et un passage de l'un à l'autre sans mot de passe.
class ComptesRepository {
  const ComptesRepository();

  Future<ListeComptes> lister() async {
    final reponse = await api.get('/comptes') as Map<String, dynamic>;

    return ListeComptes(
      comptes: ((reponse['data'] as List?) ?? [])
          .map((c) => CompteFamille.depuisJson(c as Map<String, dynamic>))
          .toList(),
      peutAjouter: reponse['peutAjouter'] as bool? ?? false,
      maximum: reponse['maximum'] as int? ?? 3,
    );
  }

  /// Crée un profil avec son seul nom ; l'API ouvre aussitôt sa session.
  Future<SessionCompte> ajouter(String nom) async {
    final reponse = await api.post('/comptes', corps: {'nom': nom});

    return SessionCompte.depuisJson(reponse as Map<String, dynamic>);
  }

  Future<SessionCompte> basculer(int compteId) async {
    final reponse = await api.post('/comptes/$compteId/basculer', corps: const {});

    return SessionCompte.depuisJson(reponse as Map<String, dynamic>);
  }
}
