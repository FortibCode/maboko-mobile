import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/adresse_api.dart';
import '../config/app_config.dart';
import '../../services/storage_service.dart';
import 'api_exception.dart';

/// Point d'entree unique vers l'API Maboko.
///
/// Centralise l'adresse de base, l'entete d'authentification, les delais
/// d'attente et la traduction des erreurs. Aucun ecran ne doit appeler
/// `http` directement.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Appele lorsque l'API repond 401 : le jeton n'est plus valable et
  /// l'application doit ramener l'utilisateur vers l'ecran de connexion.
  static void Function()? onSessionExpiree;

  Future<dynamic> get(String chemin, {Map<String, String>? parametres}) {
    return _envoyer('GET', chemin, parametres: parametres);
  }

  Future<dynamic> post(String chemin, {Map<String, dynamic>? corps}) {
    return _envoyer('POST', chemin, corps: corps);
  }

  Future<dynamic> patch(String chemin, {Map<String, dynamic>? corps}) {
    return _envoyer('PATCH', chemin, corps: corps);
  }

  /// [corps] est accepté : la suppression de compte exige le mot de passe,
  /// et HTTP autorise un corps sur DELETE.
  Future<dynamic> delete(String chemin, {Map<String, dynamic>? corps}) =>
      _envoyer('DELETE', chemin, corps: corps);

  Future<dynamic> _envoyer(
    String methode,
    String chemin, {
    Map<String, dynamic>? corps,
    Map<String, String>? parametres,
  }) async {
    final uri = Uri.parse('${AdresseApi.valeur}$chemin')
        .replace(queryParameters: parametres);

    final entetes = <String, String>{
      'Accept': 'application/json',
      if (corps != null) 'Content-Type': 'application/json',
    };

    final jeton = await StorageService.getToken();
    if (jeton != null && jeton.isNotEmpty) {
      entetes['Authorization'] = 'Bearer $jeton';
    }

    late final http.Response reponse;

    try {
      final requete = http.Request(methode, uri)..headers.addAll(entetes);
      if (corps != null) {
        requete.body = jsonEncode(corps);
      }

      final diffusee = await _client.send(requete).timeout(AppConfig.timeout);
      reponse = await http.Response.fromStream(diffusee);
    } on TimeoutException {
      throw ApiException(
        "Le serveur met trop de temps à répondre. Vérifiez votre connexion."
        '${_indiceDeveloppement()}',
      );
    } catch (_) {
      throw ApiException(
        "Impossible de joindre Maboko. Vérifiez votre connexion internet."
        '${_indiceDeveloppement()}',
      );
    }

    return _interpreter(reponse);
  }

  /// En développement, nomme l'adresse tentée.
  ///
  /// Sans cela, une application compilée avec l'adresse de l'émulateur Android
  /// (10.0.2.2, qui n'existe que là) reste suspendue trente secondes puis
  /// affiche « vérifiez votre connexion » — un message qui accuse le réseau du
  /// téléphone alors que c'est la compilation qu'il faut corriger.
  /// Rien n'est ajouté en production : l'utilisateur final n'a que faire d'une URL.
  static String _indiceDeveloppement() {
    if (AppConfig.isRelease) return '';

    return '\n(API visée : ${AdresseApi.valeur})';
  }

  dynamic _interpreter(http.Response reponse) {
    final code = reponse.statusCode;

    dynamic donnees;
    if (reponse.body.isNotEmpty) {
      try {
        donnees = jsonDecode(reponse.body);
      } catch (_) {
        donnees = null;
      }
    }

    if (code >= 200 && code < 300) {
      return donnees;
    }

    if (code == 401) {
      // Le jeton est expire ou revoque : on nettoie la session locale pour
      // eviter que l'application reste bloquee sur un ecran authentifie.
      StorageService.clearToken();
      onSessionExpiree?.call();

      throw ApiException(
        _message(donnees) ?? 'Votre session a expire. Reconnectez-vous.',
        statusCode: code,
      );
    }

    if (code == 429) {
      throw ApiException(
        'Trop de tentatives. Patientez quelques minutes avant de reessayer.',
        statusCode: code,
      );
    }

    if (code == 422) {
      throw ApiException(
        _message(donnees) ?? 'Certaines informations sont invalides.',
        statusCode: code,
        erreursValidation: _erreurs(donnees),
      );
    }

    if (code >= 500) {
      throw ApiException(
        'Le service Maboko rencontre un incident. Reessayez dans un instant.',
        statusCode: code,
      );
    }

    throw ApiException(
      _message(donnees) ?? "L'operation a echoue.",
      statusCode: code,
    );
  }

  String? _message(dynamic donnees) {
    if (donnees is Map && donnees['message'] is String) {
      return donnees['message'] as String;
    }
    return null;
  }

  Map<String, List<String>> _erreurs(dynamic donnees) {
    if (donnees is! Map || donnees['errors'] is! Map) return {};

    return (donnees['errors'] as Map).map(
      (cle, valeur) => MapEntry(
        cle.toString(),
        (valeur as List).map((e) => e.toString()).toList(),
      ),
    );
  }
}
