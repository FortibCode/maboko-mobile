import '../../../core/network/api.dart';

/// Profil de l'utilisateur connecté.
class ProfilUtilisateur {
  const ProfilUtilisateur({
    required this.id,
    required this.nomComplet,
    required this.role,
    this.matricule, // 👈 AJOUT
    this.nom,
    this.prenom,
    this.avatarUrl,
    this.ville,
    this.quartier,
    this.email,
    this.telephone,
  });

  final int id;
  final String nomComplet;
  final String? matricule; // 👈 AJOUT
  final String? nom;
  final String? prenom;
  final String role;
  final String? avatarUrl;
  final String? ville;
  final String? quartier;
  final String? email;
  final String? telephone;

  String? get localisation {
    final morceaux = [quartier, ville].where((m) => m != null && m.trim().isNotEmpty);
    return morceaux.isEmpty ? null : morceaux.join(', ');
  }

  factory ProfilUtilisateur.depuisJson(Map<String, dynamic> json) {
    final nom = (json['nom'] as String? ?? '').trim();
    final prenom = (json['prenom'] as String? ?? '').trim();

    return ProfilUtilisateur(
      id: json['id'] as int? ?? 0,
      nomComplet: [prenom, nom].where((m) => m.isNotEmpty).join(' '),
      matricule: json['matricule'] as String?, // 👈 AJOUT
      nom: nom.isEmpty ? null : nom,
      prenom: prenom.isEmpty ? null : prenom,
      role: json['role'] as String? ?? 'client',
      avatarUrl: (json['avatar_url'] as String?)?.trim(),
      ville: json['ville'] as String?,
      quartier: json['quartier'] as String?,
      email: json['email'] as String?,
      telephone: json['telephone'] as String?,
    );
  }
}

class ProfilRepository {
  const ProfilRepository();

  Future<ProfilUtilisateur> moi() async {
    final reponse = await api.get('/user');
    return ProfilUtilisateur.depuisJson(reponse as Map<String, dynamic>);
  }

  Future<String?> enregistrerPhoto(String photoBase64) async {
    final reponse = await api.post('/compte/avatar', corps: {'photo': photoBase64});
    return (reponse as Map<String, dynamic>)['avatarUrl'] as String?;
  }

  Future<void> retirerPhoto() => api.delete('/compte/avatar');

  Future<void> modifier({
    required String nom,
    String? prenom,
    String? email,
    String? ville,
    String? quartier,
  }) {
    return api.patch('/compte', corps: {
      'nom': nom,
      if (prenom != null && prenom.isNotEmpty) 'prenom': prenom,
      if (email != null && email.isNotEmpty) 'email': email,
      if (ville != null && ville.isNotEmpty) 'ville': ville,
      if (quartier != null && quartier.isNotEmpty) 'quartier': quartier,
    });
  }
}