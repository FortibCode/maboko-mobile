import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/cache/cache_local.dart';

class StorageService {
  static const String _tokenKey = "auth_token";
  static const String _userIdKey = "user_id"; // 👈 NOUVEAU
  static const String _emailKey = "user_email";
  static const String _nameKey = "user_name";
  static const String _roleKey = "user_role";
  static const String _telephoneKey = "user_telephone";
  static const String _accountsKey = "saved_accounts";
  
  static const String _profileCompletedKey = "profile_completed_";
  static const String _onboardingDoneKey = "onboarding_completed";
  static const String _likeKeyPrefix = "user_like_";
  static const String _commentKeyPrefix = "user_comment_count_";

  // ----------------------------------------------------
  // GESTION DU TOKEN ET DE L'ID
  // ----------------------------------------------------
  static Future<bool> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // 👇 NOUVELLES MÉTHODES POUR L'ID UNIQUE
  static Future<bool> saveUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_userIdKey, id);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<bool> estConnecte() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ----------------------------------------------------
  // GESTION MULTI-COMPTES
  // ----------------------------------------------------

  static Future<List<Map<String, dynamic>>> getSavedAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_accountsKey);
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(data));
  }

  static Future<void> saveAccount(Map<String, dynamic> account) async {
    final accounts = await getSavedAccounts();
    // 👇 On utilise l'ID unique pour éviter d'écraser un compte avec le même email
    final index = accounts.indexWhere((a) => a['id'] == account['id']);
    if (index >= 0) {
      accounts[index] = account; // Mise à jour
    } else {
      accounts.add(account); // Nouveau compte
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountsKey, jsonEncode(accounts));
  }

  static Future<void> saveCurrentUserAsAccount() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return;
    
    final account = {
      'token': token,
      'id': await getUserId(), // 👈 On sauvegarde l'ID
      'email': await getUserEmail(),
      'name': await getUserName(),
      'role': await getUserRole(),
      'telephone': await getUserTelephone(),
    };
    await saveAccount(account);
  }

  static Future<void> switchAccount(Map<String, dynamic> account) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, account['token']);
    await prefs.setString(_userIdKey, account['id']); // 👈 On restaure l'ID
    await prefs.setString(_emailKey, account['email'] ?? '');
    await prefs.setString(_nameKey, account['name'] ?? '');
    await prefs.setString(_roleKey, account['role'] ?? 'client');
    if (account['telephone'] != null) {
      await prefs.setString(_telephoneKey, account['telephone']);
    }
    await CacheLocal.viderTout();
  }

  // ----------------------------------------------------
  // AUTRES MÉTHODES
  // ----------------------------------------------------
  static Future<bool> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_emailKey, email);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<bool> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_nameKey, name);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  static Future<bool> saveUserTelephone(String telephone) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_telephoneKey, telephone);
  }

  static Future<String?> getUserTelephone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_telephoneKey);
  }

  static Future<bool> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_roleKey, role);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  static Future<void> saveUserData({
    required String name,
    required String role,
    String? email,
  }) async {
    await saveUserName(name);
    await saveUserRole(role);
    if (email != null && email.isNotEmpty) {
      await saveUserEmail(email);
    }
  }

  static Future<bool> isProfileCompleted(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("$_profileCompletedKey$email") ?? false;
  }

  static Future<bool> setProfileCompleted(String email, bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool("$_profileCompletedKey$email", completed);
  }

  static Future<bool> saveOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(_onboardingDoneKey, completed);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingDoneKey) ?? false;
  }

  static Future<bool> setUserPostLiked(String email, String postId, bool isLiked) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool("$_likeKeyPrefix${email}_$postId", isLiked);
  }

  static Future<bool> getUserPostLiked(String email, String postId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("$_likeKeyPrefix${email}_$postId") ?? false;
  }

  static Future<bool> setUserCommentCount(String email, String postId, int count) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt("$_commentKeyPrefix${email}_$postId", count);
  }

  static Future<int> getUserCommentCount(String email, String postId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("$_commentKeyPrefix${email}_$postId") ?? 0;
  }

  static Future<bool> clearToken() async {
    await CacheLocal.viderTout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_telephoneKey);
    await prefs.remove(_userIdKey); // 👈 Nettoyage de l'ID
    return await prefs.remove(_tokenKey);
  }

  static Future<bool> clearAll() async {
    await CacheLocal.viderTout();
    final prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }

  static Future<void> deconnecter() async {
    await clearToken();
  }
}