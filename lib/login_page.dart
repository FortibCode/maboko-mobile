import 'package:flutter/material.dart';

import 'core/network/api.dart';
import 'core/network/api_exception.dart';
import 'services/storage_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  String _formatIdentifier(String input) {
    final String trimmed = input.trim();
    // Si c'est un numéro de téléphone local, ajouter +242
    if (RegExp(r'^0[456]\d{7}$').hasMatch(trimmed)) return '+242$trimmed';
    if (RegExp(r'^[456]\d{7}$').hasMatch(trimmed)) return '+2420$trimmed';
    return trimmed; // sinon e-mail ou numéro déjà complet
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final data = await api.post('/login', corps: {
        'identifiant': _formatIdentifier(_emailController.text),
        'password': _passwordController.text,
      });

      final user = data['user'] as Map<String, dynamic>;

      // L'API renvoie « nom », pas « name » : la lecture precedente
      // retombait systematiquement sur « Utilisateur ».
      final String name = (user['nom'] as String?)?.trim().isNotEmpty == true
          ? user['nom'] as String
          : 'Utilisateur';
      final String role = user['role'] as String? ?? 'client';
      final String email = user['email'] as String? ?? _emailController.text.trim();
      final int avatarIndex = await StorageService.getAvatarIndex() ?? 0;

      await StorageService.saveToken(data['token'] as String? ?? '');
      if (user['telephone'] is String) {
        await StorageService.saveUserTelephone(user['telephone'] as String);
      }
      await StorageService.saveUserData(
        name: name,
        role: role,
        avatarIndex: avatarIndex,
        email: email,
      );

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/home',
        (route) => false,
        arguments: {
          'avatarName': name,
          'avatarIndex': avatarIndex,
          'userRole': role,
        },
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryOrange = Color(0xFFEB6E14);
    const Color hintGrey = Color(0xFFB6B6B6);
    const Color iconColor = Color(0xFFB35B28);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF9F1C),
              Color(0xFFE67718),
              Color(0xFFB35B28),
            ],
            stops: [0.1, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo Circulaire
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(6),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/Maboko.jpeg',
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.handshake_outlined,
                          size: 50,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Textes "Bon retour !"
                  const Text(
                    "Bon retour !",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Connectez-vous pour accéder à votre espace.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // La Carte Blanche Flottante
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: "Email ou téléphone",
                              labelStyle: const TextStyle(color: hintGrey),
                              helperText: "Ex : 06 666 66 66 ou votre email",
                              helperStyle: TextStyle(color: hintGrey.withValues(alpha: 0.8), fontSize: 11),
                              prefixIcon: const Icon(Icons.person_outline, color: iconColor),
                              border: InputBorder.none,
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: hintGrey.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: primaryOrange),
                              ),
                            ),
                            validator: (value) => (value == null || value.trim().isEmpty)
                                ? "Veuillez entrer votre identifiant"
                                : null,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: "Mot de passe",
                              labelStyle: const TextStyle(color: hintGrey),
                              prefixIcon: const Icon(Icons.lock_outline, color: iconColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: hintGrey,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              border: InputBorder.none,
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: hintGrey.withValues(alpha: 0.3)),
                              ),
                              focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: primaryOrange),
                              ),
                            ),
                            validator: (value) => (value == null || value.isEmpty)
                                ? "Veuillez entrer votre mot de passe"
                                : null,
                          ),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.pushNamed(context, '/forgot'),
                              style: TextButton.styleFrom(
                                foregroundColor: iconColor,
                                padding: const EdgeInsets.only(top: 8, bottom: 8),
                              ),
                              child: const Text("Mot de passe oublié ?", style: TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryOrange,
                                elevation: 5,
                                shadowColor: primaryOrange.withValues(alpha: 0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("Se connecter", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(child: Divider(color: hintGrey.withValues(alpha: 0.3))),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text("OU", style: TextStyle(color: hintGrey, fontWeight: FontWeight.w600)),
                              ),
                              Expanded(child: Divider(color: hintGrey.withValues(alpha: 0.3))),
                            ],
                          ),
                          const SizedBox(height: 16),

                          SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pushNamed(context, '/register'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: iconColor, width: 2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_add_outlined, color: iconColor, size: 20),
                                  SizedBox(width: 8),
                                  Text("Créer un compte", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: iconColor)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Footer Texte
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildFooterItem(Icons.verified_outlined, "Sûr et fiable"),
                      _buildFooterItem(Icons.groups_outlined, "Artisans & clients"),
                      _buildFooterItem(Icons.favorite_border_outlined, "Congo en avant"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 9,
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
