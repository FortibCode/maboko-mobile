import '../../../core/network/api.dart';

/// Un des comptes de la personne connectée (multi-comptes artisan).
class CompteFamille {
  const CompteFamille({
    required this.id,
    required this.nom,
    required this.role,
    this.prenom,
    this.avatarUrl,
    this.specialite,
    this.estPrincipal = false,
    this.estActif = false,
    this.archive = false,
    this.suspendu = false,
    this.notificationsNonLues = 0,
  });

  final int id;
  final String nom;
  final String? prenom;
  final String? avatarUrl;
  final String role;
  final String? specialite;
  final bool estPrincipal;

  /// Compte sur lequel le téléphone est connecté en ce moment.
  final bool estActif;

  /// Retiré de la liste par son titulaire : données conservées, réactivable.
  final bool archive;
  final bool suspendu;
  final int notificationsNonLues;

  String get nomComplet => [prenom, nom].where((m) => m != null && m.trim().isNotEmpty).join(' ');

  /// Spécialité affichable : une fiche jamais complétée n'en montre pas.
  String? get specialiteAffichable {
    final valeur = specialite?.trim();
    if (valeur == null || valeur.isEmpty || valeur == 'À compléter') return null;
    return valeur;
  }

  factory CompteFamille.depuisJson(Map<String, dynamic> json) => CompteFamille(
        id: json['id'] as int,
        nom: json['nom'] as String? ?? '',
        prenom: json['prenom'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        role: json['role'] as String? ?? 'artisan',
        specialite: json['specialite'] as String?,
        estPrincipal: json['estPrincipal'] as bool? ?? false,
        estActif: json['estActif'] as bool? ?? false,
        archive: json['archive'] as bool? ?? false,
        suspendu: json['suspendu'] as bool? ?? false,
        notificationsNonLues: json['notificationsNonLues'] as int? ?? 0,
      );
}

class ListeComptes {
  const ListeComptes({
    required this.comptes,
    required this.peutAjouter,
    required this.maximum,
    this.archives = const [],
  });

  /// Comptes actifs, compte principal en tête.
  final List<CompteFamille> comptes;
  final List<CompteFamille> archives;
  final bool peutAjouter;

  /// Limite fixée par le serveur : l'application ne la code nulle part.
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

  /// Présente quand l'opération a fermé le compte ouvert (archivage,
  /// suppression) : l'API rend alors une session sur le compte principal.
  static SessionCompte? siPresente(Map<String, dynamic> json) =>
      json['token'] is String ? SessionCompte.depuisJson(json) : null;
}

/// Compte existant trouvé à l'étape 1 de l'association.
class DemandeAssociation {
  const DemandeAssociation({required this.compte, required this.telephoneMasque, this.codeDeveloppement});

  final CompteFamille compte;
  final String telephoneMasque;

  /// Renvoyé par l'API en développement seulement, faute de SMS.
  final String? codeDeveloppement;
}

/// Multi-comptes artisan, sur le modèle d'Instagram : une connexion, plusieurs
/// comptes, et un passage de l'un à l'autre sans mot de passe.
class ComptesRepository {
  const ComptesRepository();

  Future<ListeComptes> lister() async {
    final reponse = await api.get('/comptes') as Map<String, dynamic>;

    List<CompteFamille> lire(Object? liste) => ((liste as List?) ?? [])
        .map((c) => CompteFamille.depuisJson(c as Map<String, dynamic>))
        .toList();

    return ListeComptes(
      comptes: lire(reponse['data']),
      archives: lire(reponse['archives']),
      peutAjouter: reponse['peutAjouter'] as bool? ?? false,
      maximum: reponse['maximum'] as int? ?? 1,
    );
  }

  /// Crée un compte ; l'API ouvre aussitôt sa session.
  Future<SessionCompte> ajouter({
    required String nom,
    List<String> metiers = const [],
    String? bio,
    String? photo,
  }) async {
    final reponse = await api.post('/comptes', corps: {
      'nom': nom,
      if (metiers.isNotEmpty) 'metiers': metiers,
      if (bio != null && bio.trim().isNotEmpty) 'bio': bio.trim(),
      if (photo != null) 'photo': photo,
    });

    return SessionCompte.depuisJson(reponse as Map<String, dynamic>);
  }

  Future<SessionCompte> basculer(int compteId) async {
    final reponse = await api.post('/comptes/$compteId/basculer', corps: const {});

    return SessionCompte.depuisJson(reponse as Map<String, dynamic>);
  }

  Future<void> definirPrincipal(int compteId, {required String motDePasse}) async {
    await api.post('/comptes/$compteId/principal', corps: {'password': motDePasse});
  }

  Future<SessionCompte?> archiver(int compteId) async {
    final reponse = await api.post('/comptes/$compteId/archiver', corps: const {'confirmation': true});

    return SessionCompte.siPresente(reponse as Map<String, dynamic>);
  }

  Future<void> reactiver(int compteId) async {
    await api.post('/comptes/$compteId/reactiver', corps: const {});
  }

  Future<SessionCompte?> supprimer(int compteId, {required String motDePasse}) async {
    final reponse = await api.delete('/comptes/$compteId', corps: {
      'password': motDePasse,
      'confirmation': true,
    });

    return SessionCompte.siPresente(reponse as Map<String, dynamic>);
  }

  Future<DemandeAssociation> demanderAssociation({
    required String identifiant,
    required String motDePasse,
  }) async {
    final reponse = await api.post('/comptes/associations', corps: {
      'identifiant': identifiant,
      'password': motDePasse,
    }) as Map<String, dynamic>;

    final compte = reponse['compte'] as Map<String, dynamic>;

    return DemandeAssociation(
      compte: CompteFamille.depuisJson(compte),
      telephoneMasque: compte['telephoneMasque'] as String? ?? '',
      codeDeveloppement: reponse['debug_code']?.toString(),
    );
  }

  Future<void> confirmerAssociation({required int compteId, required String code}) async {
    await api.post('/comptes/associations/confirmer', corps: {
      'compte_id': compteId,
      'code': code,
      'confirmation': true,
    });
  }
}
