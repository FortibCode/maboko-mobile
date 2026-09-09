import '../../../core/network/api.dart';

/// État de la vérification d'identité (§4.5).
class EtatVerification {
  const EtatVerification({
    required this.statut,
    required this.message,
    this.typePiece,
    this.motifRejet,
  });

  final String statut; // absente, en_attente, valide, rejete
  final String message;
  final String? typePiece;
  final String? motifRejet;

  bool get estAbsente => statut == 'absente';

  bool get estEnAttente => statut == 'en_attente';

  bool get estValidee => statut == 'valide';

  bool get estRejetee => statut == 'rejete';

  /// Un dépôt n'est possible qu'en l'absence de demande, ou après un rejet.
  bool get peutDeposer => estAbsente || estRejetee;

  factory EtatVerification.depuisJson(Map<String, dynamic> json) => EtatVerification(
        statut: json['statut'] as String? ?? 'absente',
        message: json['message'] as String? ?? '',
        typePiece: json['typePiece'] as String?,
        motifRejet: json['motifRejet'] as String?,
      );
}

class IdentiteRepository {
  const IdentiteRepository();

  Future<EtatVerification> etat() async {
    final reponse = await api.get('/verification-identite');

    return EtatVerification.depuisJson(reponse as Map<String, dynamic>);
  }

  Future<void> deposer({
    required String typePiece,
    required String recto,
    String? numeroPiece,
    String? verso,
    String? selfie,
  }) async {
    await api.post('/verification-identite', corps: {
      'type_piece': typePiece,
      'recto': recto,
      if (numeroPiece != null && numeroPiece.isNotEmpty) 'numero_piece': numeroPiece,
      if (verso != null) 'verso': verso,
      if (selfie != null) 'selfie': selfie,
    });
  }
}
