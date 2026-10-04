import 'package:shared_preferences/shared_preferences.dart';

import '../core/cache/cache_local.dart';

class StorageService {
  // Clés statiques principales
  static const String _tokenKey = "auth_token";
  static const String _emailKey = "user_email";
  static const String _nameKey = "user_name";
  static const String _roleKey = "user_role";
  static const String _telephoneKey = "user_telephone";
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

  /// Vrai si un jeton est présent localement.
  ///
  /// Attention : ce n'est qu'un indice. Un jeton expiré côté serveur
  /// reste présent ici tant qu'il n'a pas été nettoyé. Les appels API
  /// renverront 401 et `ApiClient.onSessionExpiree` fera le ménage.
  static Future<bool> estConnecte() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
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
  // NUMÉRO DE TÉLÉPHONE
  // ----------------------------------------------------

  static Future<bool> saveUserTelephone(String telephone) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_telephoneKey, telephone);
  }

  static Future<String?> getUserTelephone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_telephoneKey);
  }

  // ----------------------------------------------------
  // GESTION DU RÔLE DE L'UTILISATEUR
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
  // SAUVEGARDE PROFIL EN UN COUP
  // ----------------------------------------------------

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
  // GESTION DU PARCOURS D'ONBOARDING
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
  // DÉCONNEXION
  // ----------------------------------------------------

  /// Efface le jeton et les données de session locales.
  ///
  /// Le cache (photos, réponses API) est vidé en même temps : sur un
  /// téléphone partagé, le compte suivant ne doit rien voir du précédent.
  ///
  /// L'appel réseau `POST /logout` est fait par l'appelant : cette méthode
  /// ne s'occupe que du stockage local, elle est donc utilisable même
  /// hors ligne.
  static Future<bool> clearToken() async {
    await CacheLocal.viderTout();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_telephoneKey);
    return await prefs.remove(_tokenKey);
  }

  /// Nettoyage complet de toutes les préférences locales.
  static Future<bool> clearAll() async {
    await CacheLocal.viderTout();
    final prefs = await SharedPreferences.getInstance();
    return await prefs.clear();
  }

  /// Déconnexion complète : à appeler depuis un bouton « Se déconnecter ».
  ///
  /// Elle ne fait *que* le stockage local. Le contrôleur qui appelle cette
  /// méthode se charge, s'il le souhaite, d'appeler `/logout` au préalable.
  static Future<void> deconnecter() async {
    await clearToken();
  }
}