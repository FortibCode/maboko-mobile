import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_exception.dart';
import '../core/theme/maboko_theme.dart';
import '../features/compte/data/google_auth.dart';

/// Mes comptes liés (§5.1.7).
///
/// Un client peut relier son compte Google à son compte Maboko pour se
/// connecter plus vite. Les autres fournisseurs sont annoncés comme
/// « bientôt disponibles » plutôt que laissés cliquables sans effet.
class ComptesLiesScreen extends StatefulWidget {
  const ComptesLiesScreen({super.key});

  @override
  State<ComptesLiesScreen> createState() => _ComptesLiesScreenState();
}

class _ComptesLiesScreenState extends State<ComptesLiesScreen> {
  static const _cleGoogleLie = 'compte_google_lie';
  static const _cleEmailLie = 'compte_google_email';

  bool _chargement = true;
  bool _googleLie = false;
  String? _emailGoogle;
  bool _enCours = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _googleLie = prefs.getBool(_cleGoogleLie) ?? false;
      _emailGoogle = prefs.getString(_cleEmailLie);
      _chargement = false;
    });
  }

  Future<void> _basculerGoogle() async {
    if (_enCours) return;
    setState(() => _enCours = true);

    try {
      if (_googleLie) {
        // Déconnexion locale : on ne touche pas au compte Google lui-même,
        // seulement au lien côté Maboko.
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_cleGoogleLie, false);
        await prefs.remove(_cleEmailLie);

        if (!mounted) return;
        setState(() {
          _googleLie = false;
          _emailGoogle = null;
          _enCours = false;
        });
        _informer('Compte Google délié.', MabokoCouleurs.succes);
      } else {
        final session = await const GoogleAuth().connecter();

        // L'utilisateur a fermé la fenêtre Google : pas une erreur.
        if (session == null) {
          setState(() => _enCours = false);
          return;
        }

        final email = session.utilisateur['email'] as String?;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_cleGoogleLie, true);
        if (email != null) await prefs.setString(_cleEmailLie, email);

        if (!mounted) return;
        setState(() {
          _googleLie = true;
          _emailGoogle = email;
          _enCours = false;
        });
        _informer('Compte Google relié.', MabokoCouleurs.succes);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _enCours = false);
      _informer(e.message, MabokoCouleurs.danger);
    } catch (_) {
      if (!mounted) return;
      setState(() => _enCours = false);
      _informer('Une erreur est survenue. Réessayez.', MabokoCouleurs.danger);
    }
  }

  void _informer(String message, Color couleur) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: couleur),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.fondMaboko,
      appBar: AppBar(
        title: const Text('Mes comptes liés'),
        backgroundColor: MabokoCouleurs.secondaire,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator(color: MabokoCouleurs.secondaire))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                _encadre(),
                const SizedBox(height: 20),
                _section('Fournisseurs disponibles'),
                _carteGoogle(),
                const SizedBox(height: 12),
                _carteAVenir(
                  icone: Icons.facebook_rounded,
                  couleur: const Color(0xFF1877F2),
                  nom: 'Facebook',
                ),
                const SizedBox(height: 12),
                _carteAVenir(
                  icone: Icons.apple_rounded,
                  couleur: Colors.black,
                  nom: 'Apple',
                ),
                const SizedBox(height: 12),
                _carteAVenir(
                  icone: Icons.phone_android_rounded,
                  couleur: const Color(0xFF34A853),
                  nom: 'Numéro de téléphone',
                ),
              ],
            ),
    );
  }

  Widget _section(String titre) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        titre,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: context.texteSecondaireMaboko,
          letterSpacing: .3,
        ),
      ),
    );
  }

  Widget _carteGoogle() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _googleLie ? MabokoCouleurs.succes : context.bordureMaboko,
          width: _googleLie ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.bordureMaboko),
            ),
            alignment: Alignment.center,
            child: const Text(
              'G',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4285F4),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Google',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  _googleLie
                      ? (_emailGoogle ?? 'Compte relié')
                      : 'Reliez votre compte Google pour vous connecter en un geste.',
                  style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _enCours
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: MabokoCouleurs.secondaire),
                )
              : TextButton(
                  onPressed: _basculerGoogle,
                  style: TextButton.styleFrom(
                    foregroundColor: _googleLie ? MabokoCouleurs.danger : MabokoCouleurs.secondaire,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(
                    _googleLie ? 'Délier' : 'Relier',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _carteAVenir({
    required IconData icone,
    required Color couleur,
    required String nom,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.bordureMaboko),
      ),
      child: Opacity(
        opacity: 0.55,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: couleur.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(icone, color: couleur, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nom,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(
                    'Bientôt disponible',
                    style: TextStyle(fontSize: 12.5, color: context.texteSecondaireMaboko),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.bordureMaboko,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'À venir',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: context.texteSecondaireMaboko,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _encadre() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.teinteMaboko,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MabokoCouleurs.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, size: 20, color: MabokoCouleurs.accent),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Relier un compte vous permet de vous connecter plus vite, sans '
              'ressaisir votre mot de passe. Vous pouvez délier à tout moment.',
              style: TextStyle(fontSize: 12.5, height: 1.45, color: context.texteSecondaireMaboko),
            ),
          ),
        ],
      ),
    );
  }
}