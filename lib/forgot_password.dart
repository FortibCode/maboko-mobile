import 'dart:async'; // Nécessaire pour le Timer
import 'package:flutter/material.dart';

import 'core/network/api.dart';
import 'core/network/api_exception.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool otpSent = false;
  bool otpVerified = false;
  bool isLoading = false;
  bool _obscurePassword = true;

  /// Jeton a usage unique remis par l'API apres verification du code SMS.
  /// Sans lui, le changement de mot de passe est refuse : connaitre un numero
  /// de telephone ne suffit plus a prendre le controle d'un compte.
  String? _resetToken;

  // Variables pour le chronomètre
  Timer? _timer;
  int _start = 50;
  bool _canResend = false;


  @override
  void dispose() {
    _timer?.cancel(); // Nettoyage du timer à la fermeture de la page
    phoneController.dispose();
    codeController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void startTimer() {
    setState(() {
      _start = 50;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_start == 0) {
        setState(() {
          _timer?.cancel();
          _canResend = true;
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final String? passedInput = ModalRoute.of(context)?.settings.arguments as String?;
    if (passedInput != null && passedInput.isNotEmpty) {
      phoneController.text = passedInput;
    }
  }

  String _formatCongolesePhone(String input) {
    String cleaned = input.replaceAll(RegExp(r'\s+'), '').trim();
    if (cleaned.startsWith('+242')) return cleaned;
    if (cleaned.startsWith('242')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+242$cleaned';
    if (cleaned.isNotEmpty) return '+2420$cleaned';
    return cleaned;
  }

  Future<void> sendOtp() async {
    if (phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer votre numéro de téléphone"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await api.post("/send-otp", corps: {
        "telephone": _formatCongolesePhone(phoneController.text.trim()),
      });

      setState(() => isLoading = false);

      if (!mounted) return;

      // En developpement sans passerelle SMS, l'API peut renvoyer le code
      // (OTP_EXPOSE_IN_RESPONSE). Ce champ est absent en production.
      final String? simulatedCode =
          (data is Map && data['debug_code'] != null) ? data['debug_code'].toString() : null;

      setState(() => otpSent = true);
      startTimer(); // Démarrage du chronomètre de 50 secondes

      if (simulatedCode != null) {

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.sms_outlined, color: Color(0xFFD46A00)),
                SizedBox(width: 8),
                Text("Simulation SMS reçu", style: TextStyle(color: Color(0xFFD46A00), fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text("Votre code de confirmation est : $simulatedCode", style: const TextStyle(fontSize: 16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK", style: TextStyle(color: Color(0xFFD46A00), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Code de vérification envoyé par SMS"),
            backgroundColor: Color(0xFFD46A00),
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> verifyOtp() async {
    if (codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez entrer le code OTP"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final data = await api.post("/verify-otp", corps: {
        "telephone": _formatCongolesePhone(phoneController.text.trim()),
        "code": codeController.text.trim(),
      });

      setState(() => isLoading = false);

      if (!mounted) return;

      _timer?.cancel(); // Arrêter le timer si le code est validé

      setState(() {
        _resetToken = data['reset_token'] as String?;
        otpVerified = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Code correct. Veuillez définir un nouveau mot de passe"),
          backgroundColor: Color(0xFFD46A00),
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

  Future<void> resetPassword() async {
    if (newPasswordController.text.isEmpty || confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez remplir tous les champs du mot de passe"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPasswordController.text != confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Les mots de passe ne correspondent pas"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final jeton = _resetToken;
    if (jeton == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vérifiez d'abord le code reçu par SMS"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await api.post("/reset-password", corps: {
        "telephone": _formatCongolesePhone(phoneController.text.trim()),
        // Le code seul ne suffit plus : l'API exige le jeton a usage unique
        // remis a l'etape de verification.
        "reset_token": jeton,
        "password": newPasswordController.text,
        "password_confirmation": confirmPasswordController.text,
      });

      setState(() => isLoading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mot de passe modifié avec succès. Veuillez vous connecter"),
          backgroundColor: Color(0xFFD46A00),
        ),
      );
      Navigator.pushReplacementNamed(context, "/login");
    } on ApiException catch (e) {
      setState(() => isLoading = false);
      if (!mounted) return;

      // Le jeton est consomme des la premiere tentative reussie ; en cas
      // d'echec il faut repartir de la verification du code.
      if (e.estValidation) {
        setState(() {
          _resetToken = null;
          otpVerified = false;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon, {Widget? suffixIcon, String? prefixText}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFFD46A00)),
      prefixText: prefixText,
      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD46A00)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9F6F0),
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
        borderSide: const BorderSide(color: Color(0xFFD46A00), width: 1.2),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
              Color(0xFFFF9F1C),
              Color(0xFFD46A00),
              Color(0xFF4A1E04),
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
                      color: const Color(0xFFFDFBF7),
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
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Récupération",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    otpVerified 
                        ? "Définissez votre nouveau mot de passe"
                        : otpSent 
                            ? "Entrez le code reçu par SMS" 
                            : "Entrez votre numéro de téléphone",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !otpSent,
                          decoration: _inputDecoration(
                            "Numéro de téléphone",
                            Icons.phone_outlined,
                            prefixText: "+242 ",
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (!otpSent)
                          isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD46A00)))
                              : SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: sendOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF8C00),
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shadowColor: Colors.orange.withValues(alpha: 0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: const Text(
                                      "Envoyer le code de confirmation",
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),

                        if (otpSent && !otpVerified) ...[
                          TextField(
                            controller: codeController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration("Code reçu par SMS", Icons.lock_clock_outlined),
                          ),
                          const SizedBox(height: 12),
                          
                          // Affichage du chronomètre et bouton renvoyer
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _start > 0 
                                    ? "Renvoyer dans : 00:${_start.toString().padLeft(2, '0')}" 
                                    : "Code expiré ou expirant",
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: _start > 0 ? Colors.grey.shade600 : Colors.red,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextButton(
                                onPressed: _canResend ? sendOtp : null,
                                child: Text(
                                  "Renvoyer",
                                  style: TextStyle(
                                    color: _canResend ? const Color(0xFFD46A00) : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD46A00)))
                              : SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: verifyOtp,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF8C00),
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shadowColor: Colors.orange.withValues(alpha: 0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: const Text(
                                      "Confirmer le code",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                        ],

                        if (otpVerified) ...[
                          TextField(
                            controller: newPasswordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration(
                              "Nouveau mot de passe",
                              Icons.lock_outline,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: const Color(0xFFD46A00),
                                  size: 20,
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: confirmPasswordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration("Confirmer le mot de passe", Icons.lock_outline),
                          ),
                          const SizedBox(height: 20),
                          isLoading
                              ? const Center(child: CircularProgressIndicator(color: Color(0xFFD46A00)))
                              : SizedBox(
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: resetPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF8C00),
                                      foregroundColor: Colors.white,
                                      elevation: 5,
                                      shadowColor: Colors.orange.withValues(alpha: 0.4),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                    child: const Text(
                                      "Valider",
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildBottomFeature(Icons.verified_user_outlined, "Sûr\net fiable"),
                      Container(height: 25, width: 1, color: Colors.white.withValues(alpha: 0.3)),
                      _buildBottomFeature(Icons.groups_outlined, "Pour les artisans\net leurs clients"),
                      Container(height: 25, width: 1, color: Colors.white.withValues(alpha: 0.3)),
                      _buildBottomFeature(Icons.favorite_border, "Un Congo\nqui avance"),
                    ],
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 16),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 10,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}
