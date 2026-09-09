import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Clés statiques principales
  static const String _tokenKey = "auth_token";
  static const String _emailKey = "user_email";
  static const String _nameKey = "user_name";
  static const String _roleKey = "user_role";
  static const String _avatarIndexKey = "avatar_index";
  static const String _profileCompletedKey = "profile_completed_";
  static const String _onboardingDoneKey = "onboarding_completed";

  // Clés dynamiques pour isoler les likes et commentaires par utilisateur connecté
  static const String _likeKeyPrefix = "user_like_";
  static const String _commentKeyPrefix = "user_comment_count_";

  // ----------------------------------------------------
  // GESTION DU TOKEN
  // ----------------------------------------------------

  static Future<bool> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ----------------------------------------------------
  // GESTION DE L'E-MAIL
  // ----------------------------------------------------

  static Future<bool> saveUserEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_emailKey, email);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  // ----------------------------------------------------
  // GESTION DU NOM / PSEUDO DE L'UTILISATEUR
  // ----------------------------------------------------

  static Future<bool> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_nameKey, name);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  // ----------------------------------------------------
  // GESTION DU RÔLE DE L'UTILISATEUR (Client / Artisan)
  // ----------------------------------------------------

  static Future<bool> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_roleKey, role);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  // ----------------------------------------------------
  // GESTION DE L'AVATAR SELECTIONNÉ
  // ----------------------------------------------------

  static Future<bool> saveAvatarIndex(int avatarIndex) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setInt(_avatarIndexKey, avatarIndex);
  }

  static Future<int?> getAvatarIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_avatarIndexKey);
  }

  // ----------------------------------------------------
  // METHODE PRATIQUE POUR SAUVEGARDER TOUTES LES INFOS PROFIL D'UN COUP
  // ----------------------------------------------------

  static Future<void> saveUserData({
    required String name,
    required String role,
    required int avatarIndex,
    String? email,
  }) async {
    await saveUserName(name);
    await saveUserRole(role);
    await saveAvatarIndex(avatarIndex);
    if (email != null && email.isNotEmpty) {
      await saveUserEmail(email);
    }
  }

  // ----------------------------------------------------
  // GESTION DE LA CONFIGURATION DU PROFIL PAR UTILISATEUR
  // ----------------------------------------------------

  static Future<bool> isProfileCompleted(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("$_profileCompletedKey$email") ?? false;
  }

  static Future<bool> setProfileCompleted(String email, bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool("$_profileCompletedKey$email", completed);
  }

  // ----------------------------------------------------
  // GESTION DU PARCOURS D'ONBOARDING (première ouverture)
  // ----------------------------------------------------

  static Future<bool> saveOnboardingCompleted(bool completed) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(_onboardingDoneKey, completed);
  }

  static Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingDoneKey) ?? false;
  }

  // ----------------------------------------------------
  // GESTION DES LIKES ET INTERACTIONS PAR COMPTE
  // ----------------------------------------------------

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

  // ----------------------------------------------------
  // DÉCONNEXION (Nettoyage des données de session)
  // ----------------------------------------------------

  static Future<bool> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey); 
    await prefs.remove(_nameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_avatarIndexKey);
    return await prefs.remove(_tokenKey);
  }

  // Nettoyage complet de toutes les préférences locales
  static Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }
}
