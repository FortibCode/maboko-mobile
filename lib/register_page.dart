import 'package:flutter/material.dart';
import 'core/network/api.dart';
import 'core/network/api_exception.dart';
import 'services/storage_service.dart';
import 'core/session/role_utilisateur.dart';
import 'core/widgets/bascule_acces.dart';
import 'features/artisans/ui/inscription/artisan_experience_screen.dart';
import 'features/courses/ui/fiche_chauffeur_screen.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController codeController = TextEditingController();

  bool isLoading = false;
  bool _obscurePassword = true;
  bool isOtpStep = false;

  String _userRole = 'client';
  bool _argsRead = false;

  bool hasMinLength = false;
  bool hasUppercase = false;
  bool hasDigit = false;
  bool hasSpecialChar = false;

  // Palette marron & beige — alignée sur la page de connexion du web.
  static const Color terracotta = Color(0xFFB35B28);
  static const Color orMaboko = Color(0xFFEAA023);
  static const Color beigeFond = Color(0xFFFFFDF8);
  static const Color texteMarron = Color(0xFF4A2A18);

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_validatePasswordRules);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_argsRead) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _userRole = args?['userRole'] ?? 'client';
      _argsRead = true;
    }
  }

  @override
  void dispose() {
    passwordController.removeListener(_validatePasswordRules);
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    codeController.dispose();
    super.dispose();
  }

  void _validatePasswordRules() {
    final password = passwordController.text;
    setState(() {
      hasMinLength = password.length >= 8;
      hasUppercase = password.contains(RegExp(r'[A-Z]'));
      hasDigit = password.contains(RegExp(r'[0-9]'));
      hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  String formatCongolesePhone(String input) {
    String cleaned = input.replaceAll(RegExp(r'\s+'), '').trim();
    if (cleaned.startsWith('+242')) {
      return cleaned;
    }
    if (cleaned.startsWith('242')) {
      return '+$cleaned';
    }
    if (cleaned.startsWith('0')) {
      return '+242$cleaned';
    }
    if (cleaned.isNotEmpty) {
      return '+2420$cleaned';
    }
    return cleaned;
  }

  bool _isValidCongolesePhone(String phone) {
    final String formatted = formatCongolesePhone(phone);
    final RegExp phoneRegex = RegExp(r'^\+2420[456]\d{7}$');
    return phoneRegex.hasMatch(formatted);
  }

  Future<void> sendRegisterOtp() async {
    final String rawPhone = phoneController.text.trim();
    final String formattedPhone = formatCongolesePhone(rawPhone);

    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        rawPhone.isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur : tous les champs sont obligatoires"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_isValidCongolesePhone(rawPhone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Format invalide. Ex : 06 666 66 66 (9 chiffres)"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!(hasMinLength && hasUppercase && hasDigit && hasSpecialChar)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez respecter toutes les normes du mot de passe"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await api.post('/send-register-otp', corps: {
        "nom": nameController.text.trim(),
        "email": emailController.text.trim(),
        "telephone": formattedPhone,
        "password": passwordController.text,
        "role": _roleApi(),
      });

      setState(() => isLoading = false);
      if (!mounted) return;

      final codeDeveloppement = data is Map ? data['debug_code'] : null;
      if (codeDeveloppement != null) {
        _showOtpDialog(codeDeveloppement.toString());
      }

      setState(() => isOtpStep = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Code de validation envoyé par SMS"),
          backgroundColor: terracotta,
        ),
      );
    } on ApiException catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  String _roleApi() => RoleMaboko.depuis(_userRole).pourApi;

  Future<void> resendOtp() async {
    await sendRegisterOtp();
  }

  void _showOtpDialog(String code) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.sms_outlined, color: terracotta),
            SizedBox(width: 8),
            Text("Code de développement",
                style: TextStyle(color: terracotta, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text("Votre code de validation est : $code",
            style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK",
                style: TextStyle(color: terracotta, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _titreSelonRole() => switch (RoleMaboko.depuis(_userRole)) {
        RoleMaboko.artisan => "Rejoignez Maboko en tant qu'Artisan",
        RoleMaboko.chauffeur => 'Rejoignez Allô Chauffeur',
        _ => 'Rejoignez Maboko',
      };

  Widget _choixRole(RoleMaboko role, IconData icone) {
    final choisi = RoleMaboko.depuis(_userRole) == role;

    return GestureDetector(
      onTap: () => setState(() => _userRole = role.pourApi),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: choisi ? terracotta.withValues(alpha: 0.10) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: choisi ? terracotta : const Color(0xFFE8DCC8),
            width: choisi ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icone,
                size: 22,
                color: choisi ? terracotta : const Color(0xFF7A6A5C)),
            const SizedBox(height: 6),
            Text(
              role.libelle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: choisi ? FontWeight.bold : FontWeight.normal,
                color: choisi ? terracotta : const Color(0xFF7A6A5C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Aiguillage juste après la création du compte.
  ///
  /// L'artisan passe désormais par un parcours d'inscription en plusieurs
  /// étapes (expérience, ville, quartier, bio, RCCM) avant sa fiche métier.
  /// Le chauffeur garde son parcours actuel.
  Future<void> _apresInscription(String role, String nom) async {
    final reel = RoleMaboko.depuis(role);

    if (reel.estArtisan) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ArtisanExperienceScreen(nomComplet: nom),
        ),
      );

      return;
    }

    if (reel.estChauffeur) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const FicheChauffeurScreen(premiereFois: true),
        ),
      );

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Bienvenue sur Maboko !"),
        backgroundColor: terracotta,
      ),
    );

    ouvrirEspace(context, reel, nom: nom);
  }

  Future<void> verifyAndRegister() async {
    if (codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer le code de validation"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final donnees = await api.post('/verify-register-otp', corps: {
        "telephone": formatCongolesePhone(phoneController.text.trim()),
        "code": codeController.text.trim(),
      });

      final utilisateur = (donnees['user'] as Map<String, dynamic>?) ?? const {};
      final String role = utilisateur['role'] as String? ?? _userRole;
      final String nom = (utilisateur['nom'] as String?)?.trim().isNotEmpty == true
          ? utilisateur['nom'] as String
          : nameController.text.trim();

      await StorageService.saveToken(donnees['token'] as String? ?? '');
      await StorageService.saveUserData(
        name: nom,
        role: role,
        email: utilisateur['email'] as String? ?? emailController.text.trim(),
      );
      if (utilisateur['telephone'] is String) {
        await StorageService.saveUserTelephone(utilisateur['telephone'] as String);
      }
      await StorageService.saveOnboardingCompleted(true);

      setState(() => isLoading = false);
      if (!mounted) return;

      await _apresInscription(role, nom);
    } on ApiException catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon,
      {String? helperText, Widget? suffixIcon, String? prefixText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      helperText: helperText,
      helperStyle: TextStyle(color: Colors.grey.shade500, fontSize: 11),
      prefixIcon: Icon(icon, color: terracotta),
      prefixText: prefixText,
      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: terracotta),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: beigeFond,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: terracotta, width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  Widget _buildPasswordRuleRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isValid ? Colors.green.shade600 : Colors.red.shade400,
          size: 15,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green.shade800 : Colors.grey.shade600,
            fontSize: 12,
            fontWeight: isValid ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A2A18), // marron foncé
              Color(0xFF7A3F1D), // marron moyen
              Color(0xFFB35B28), // terracotta
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: beigeFond,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 25,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/Maboko.jpeg',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.handshake,
                          size: 60,
                          color: terracotta,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    isOtpStep ? "Validation du code" : _titreSelonRole(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isOtpStep
                        ? "Entrez le code reçu par SMS au ${phoneController.text}"
                        : "Remplissez les informations pour créer votre compte.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 22),

                  if (!isOtpStep) ...[
                    BasculeAcces(surConnexion: false, roleInscription: _userRole),
                    const SizedBox(height: 22),
                  ],

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: beigeFond,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!isOtpStep) ...[
                          const Text(
                            'Je crée un compte en tant que',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7A6A5C),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _choixRole(RoleMaboko.client, Icons.search_rounded)),
                              const SizedBox(width: 8),
                              Expanded(child: _choixRole(RoleMaboko.artisan, Icons.handyman_outlined)),
                              const SizedBox(width: 8),
                              Expanded(child: _choixRole(RoleMaboko.chauffeur, Icons.local_taxi_outlined)),
                            ],
                          ),
                          const SizedBox(height: 18),
                          TextField(
                            style: const TextStyle(color: texteMarron, fontSize: 15),
                            controller: nameController,
                            decoration: _inputDecoration("Nom d'utilisateur", Icons.person_outline),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            style: const TextStyle(color: texteMarron, fontSize: 15),
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration("Email", Icons.email_outlined),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            style: const TextStyle(color: texteMarron, fontSize: 15),
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration(
                              "Téléphone",
                              Icons.phone_outlined,
                              prefixText: "+242 ",
                              helperText: "Ex : 06 666 66 66 (9 chiffres)",
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            style: const TextStyle(color: texteMarron, fontSize: 15),
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration(
                              "Mot de passe",
                              Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: terracotta,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: beigeFond,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE8D5C0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Le mot de passe doit contenir :",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                      color: terracotta),
                                ),
                                const SizedBox(height: 6),
                                _buildPasswordRuleRow("Au moins 8 caractères", hasMinLength),
                                const SizedBox(height: 4),
                                _buildPasswordRuleRow("Une lettre majuscule (A-Z)", hasUppercase),
                                const SizedBox(height: 4),
                                _buildPasswordRuleRow("Un chiffre (0-9)", hasDigit),
                                const SizedBox(height: 4),
                                _buildPasswordRuleRow("Un caractère spécial (!@#\$...)", hasSpecialChar),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          isLoading
                              ? const Center(child: CircularProgressIndicator(color: terracotta))
                              : SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: sendRegisterOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: terracotta,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shadowColor: terracotta.withValues(alpha: 0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Continuer",
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward_rounded, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                        ] else ...[
                          TextField(
                            style: const TextStyle(color: texteMarron, fontSize: 15),
                            controller: codeController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration("Code de validation SMS", Icons.lock_clock_outlined),
                          ),
                          const SizedBox(height: 20),
                          isLoading
                              ? const Center(child: CircularProgressIndicator(color: terracotta))
                              : SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: verifyAndRegister,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: terracotta,
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shadowColor: terracotta.withValues(alpha: 0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Valider le compte",
                                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.check_circle_outline_rounded, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: resendOtp,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: terracotta,
                                side: const BorderSide(color: terracotta, width: 1.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              child: const Text(
                                "Renvoyer le code",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() {
                                  isOtpStep = false;
                                });
                              },
                              child: const Text(
                                "Modifier mes informations",
                                style: TextStyle(
                                    color: terracotta,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}