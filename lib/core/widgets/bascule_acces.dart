import 'package:flutter/material.dart';

import '../theme/maboko_theme.dart';

/// Sélecteur Connexion / Inscription (§5.1.3).
///
/// Les deux parcours restent deux écrans distincts : l'inscription se fait en
/// deux temps — formulaire puis code SMS — et l'imbriquer dans un onglet
/// casserait un flux qui fonctionne. Le sélecteur ne fait donc que naviguer,
/// mais l'utilisateur, lui, voit bien deux onglets.
class BasculeAcces extends StatelessWidget {
  const BasculeAcces({super.key, required this.surConnexion, this.roleInscription});

  /// Vrai sur l'écran de connexion, faux sur celui d'inscription.
  final bool surConnexion;

  /// Rôle transmis à l'inscription. Sans lui, le compte serait créé comme
  /// client quel que soit le parcours d'où vient l'utilisateur.
  final String? roleInscription;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: _onglet(
              context,
              libelle: 'Connexion',
              actif: surConnexion,
              action: surConnexion
                  ? null
                  : () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      ),
            ),
          ),
          Expanded(
            child: _onglet(
              context,
              libelle: 'Inscription',
              actif: !surConnexion,
              action: surConnexion
                  ? () => Navigator.pushNamed(
                        context,
                        '/register',
                        arguments: {'userRole': roleInscription ?? 'client'},
                      )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _onglet(
    BuildContext context, {
    required String libelle,
    required bool actif,
    required VoidCallback? action,
  }) {
    return GestureDetector(
      onTap: action,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: actif ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
          boxShadow: actif
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          libelle,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: actif ? MabokoCouleurs.secondaire : Colors.white,
          ),
        ),
      ),
    );
  }
}
