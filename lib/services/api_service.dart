import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/agent.dart';
import '../models/bon_livraison.dart';
import '../config/api_config.dart';
import 'api_logger.dart';

class ApiService {
  String baseUrl;
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal() : baseUrl = _getBaseUrl() {
    debugPrint('ApiService initialisé avec succès - URL: $baseUrl');
    debugPrint('Service API avec données réelles initialisé avec succès');
  }
  
  static String _getBaseUrl() {
    return ApiConfig.baseUrl;
  }
  
  // Méthode pour mettre à jour l'URL du serveur
  void updateServerUrl(String url) {
    if (url.isNotEmpty) {
      baseUrl = url;
      debugPrint('URL du serveur mise à jour: $baseUrl');
    }
  }
  
  // Authentification d'un agent avec email et mot de passe
  Future<Agent?> authAgent(String email, String password) async {
    try {
      debugPrint('Tentative d\'authentification avec email: $email');
      
      // Préparer les données pour la requête - FORMAT JSON
      final Map<String, String> requestData = {
        'email': email,
        'password': password,
      };
      
      // Préparer les données au format x-www-form-urlencoded
      String formBody = '';
      requestData.forEach((key, value) {
        if (formBody.isNotEmpty) formBody += '&';
        formBody += '$key=$value';
      });
      
      // Liste des URLs à essayer
      List<String> urlsToTry = ApiConfig.loginUrls;
      
      Exception? lastException;
      
      for (String url in urlsToTry) {
        try {
          // Journaliser la requête
          ApiLogger.logRequest(url, 'POST', body: requestData);
          
          // Essayer d'abord avec Content-Type: application/json
          var response = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestData),
          ).timeout(
            Duration(seconds: ApiConfig.timeout),
            onTimeout: () => throw TimeoutException('Délai d\'attente dépassé pour l\'authentification')
          );
          
          // Journaliser la réponse
          ApiLogger.logResponse(url, response.statusCode, response.body);
          
          // Si échec, essayer avec application/x-www-form-urlencoded
          if (response.statusCode != 200) {
            debugPrint('Réessai avec Content-Type: application/x-www-form-urlencoded');
            
            // Journaliser la nouvelle requête
            ApiLogger.logRequest(url, 'POST', 
                body: {'formData': formBody},
                headers: {'Content-Type': 'application/x-www-form-urlencoded'});
            
            response = await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: formBody,
            ).timeout(
              Duration(seconds: ApiConfig.timeout),
              onTimeout: () => throw TimeoutException('Délai d\'attente dépassé pour l\'authentification')
            );
            
            // Journaliser la réponse
            ApiLogger.logResponse(url, response.statusCode, response.body);
          }
          
          if (response.statusCode == 200) {
            try {
              final Map<String, dynamic> responseData = jsonDecode(response.body);
              
              // Format 1: {"success": true, "agent": {...}}
              if (responseData.containsKey('success') && responseData['success'] == true && responseData.containsKey('agent')) {
                final agentData = responseData['agent'] as Map<String, dynamic>;
                debugPrint('Authentification réussie avec le format 1: ${agentData['nom']} ${agentData['prenom']}');
                
                return Agent.fromJson(agentData);
              }
              
              // Format 2: {"status": "success", "data": {...}}
              else if (responseData.containsKey('status') && responseData['status'] == 'success' && responseData.containsKey('data')) {
                final agentData = responseData['data'] as Map<String, dynamic>;
                debugPrint('Authentification réussie avec le format 2: ${agentData['nom']} ${agentData['prenom']}');
                
                return Agent.fromJson(agentData);
              }
              
              // Format 3: {"agent": {...}} (sans statut)
              else if (responseData.containsKey('agent')) {
                final agentData = responseData['agent'] as Map<String, dynamic>;
                debugPrint('Authentification réussie avec le format 3: ${agentData['nom'] ?? 'Nom inconnu'} ${agentData['prenom'] ?? 'Prénom inconnu'}');
                
                return Agent.fromJson(agentData);
              }
              
              // Format 4: Si la réponse est l'agent lui-même
              else if (responseData.containsKey('id') && (responseData.containsKey('nom') || responseData.containsKey('name'))) {
                debugPrint('Authentification réussie avec le format 4 (agent direct)');
                return Agent.fromJson(responseData);
              }
              
              // Si aucun format reconnu ou échec d'authentification
              debugPrint('Format de réponse non reconnu ou échec d\'authentification: $responseData');
            } catch (e) {
              debugPrint('Erreur lors du décodage JSON: $e');
              // Essayons d'interpréter la réponse comme un texte brut
              if (response.body.contains('success') && response.body.contains('id') && response.body.length > 20) {
                debugPrint('Tentative de traitement de la réponse comme texte: ${response.body}');
                // Si ça ressemble à du JSON mais n'est pas correctement formaté
                try {
                  String cleanJson = response.body.replaceAll("'", "\"");
                  var data = jsonDecode(cleanJson);
                  if (data is Map<String, dynamic> && data.containsKey('id')) {
                    return Agent.fromJson(data);
                  }
                } catch (e) {
                  debugPrint('Erreur lors du nettoyage JSON: $e');
                }
              }
            }
          }
        } catch (e, stackTrace) {
          ApiLogger.logError(url, e, stackTrace);
          debugPrint('Erreur avec URL $url: $e');
          lastException = e is Exception ? e : Exception(e.toString());
          // Continuer avec l'URL suivante
        }
      }
      
      // Si toutes les tentatives échouent, lever l'exception
      if (lastException != null) {
        throw lastException;
      } else {
        throw Exception('Échec d\'authentification avec toutes les URLs');
      }
    } catch (e, stackTrace) {
      ApiLogger.logError('authAgent', e, stackTrace);
      debugPrint('Erreur lors de l\'authentification: $e');
      throw Exception('Erreur lors de l\'authentification: $e');
    }
  }
  
  // Méthode pour récupérer les livraisons d'un agent
  Future<List<BonLivraison>> getLivraisonsByAgent(int agentId) async {
    try {
      // URL de base pour notre API
      debugPrint('Récupération des livraisons pour l\'agent $agentId avec l\'API réelle');
      
      // Utiliser les URLs fournies par la configuration
      List<String> urlsToTry = ApiConfig.getLivraisonUrls(agentId);
      
      Exception? lastException;
      
      // Essayer chaque URL jusqu'à ce qu'une fonctionne
      for (String url in urlsToTry) {
        try {
          // Journaliser la requête
          ApiLogger.logRequest(url, 'GET', headers: {'Accept': 'application/json'});
          
          final response = await http.get(
            Uri.parse(url),
            headers: {'Accept': 'application/json'},
          ).timeout(
            Duration(seconds: ApiConfig.timeout),
            onTimeout: () => throw TimeoutException('Délai d\'attente dépassé pour la récupération des livraisons')
          );
          
          // Journaliser la réponse
          ApiLogger.logResponse(url, response.statusCode, response.body);
          
          debugPrint('Réponse de $url: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            try {
              // Essayer de décoder le JSON
              final dynamic decodedJson = jsonDecode(response.body);
              List<BonLivraison> livraisons = [];
              
              // Si c'est une Map (objet JSON)
              if (decodedJson is Map<String, dynamic>) {
                final responseData = decodedJson;
                
                // Format 1: {"success": true, "commandes": [...]}
                if (responseData.containsKey('success') && responseData['success'] == true && responseData.containsKey('commandes')) {
                  final commandesData = responseData['commandes'] as List<dynamic>;
                  for (var item in commandesData) {
                    livraisons.add(BonLivraison.fromJson(item));
                  }
                  debugPrint('Livraisons récupérées avec succès (format 1): ${livraisons.length} livraisons');
                  return livraisons;
                }
                
                // Format 2: {"status": "success", "data": [...]}
                else if (responseData.containsKey('status') && responseData['status'] == 'success' && responseData.containsKey('data')) {
                  final commandesData = responseData['data'] as List<dynamic>;
                  for (var item in commandesData) {
                    livraisons.add(BonLivraison.fromJson(item));
                  }
                  debugPrint('Livraisons récupérées avec succès (format 2): ${livraisons.length} livraisons');
                  return livraisons;
                }
                
                // Format 3: {"commandes": [...]} (sans statut)
                else if (responseData.containsKey('commandes')) {
                  final commandesData = responseData['commandes'] as List<dynamic>;
                  for (var item in commandesData) {
                    livraisons.add(BonLivraison.fromJson(item));
                  }
                  debugPrint('Livraisons récupérées avec succès (format 3): ${livraisons.length} livraisons');
                  return livraisons;
                }
                
                // Format 5: La réponse est un tableau dans un objet
                else if (responseData.containsKey('items') || responseData.containsKey('results') || responseData.containsKey('list')) {
                  final key = responseData.containsKey('items') ? 'items' : (responseData.containsKey('results') ? 'results' : 'list');
                  final commandesData = responseData[key] as List<dynamic>;
                  for (var item in commandesData) {
                    livraisons.add(BonLivraison.fromJson(item));
                  }
                  debugPrint('Livraisons récupérées avec succès (format 5): ${livraisons.length} livraisons');
                  return livraisons;
                }
              }
              // Format 4: La réponse est un tableau direct
              else if (decodedJson is List) {
                for (var item in decodedJson) {
                  livraisons.add(BonLivraison.fromJson(item));
                }
                debugPrint('Livraisons récupérées avec succès (format 4): ${livraisons.length} livraisons');
                return livraisons;
              }
              
              // Si le format n'est pas reconnu, jeter une exception
              debugPrint('Format de réponse non reconnu: $decodedJson');
              throw Exception('Format de réponse non reconnu pour les livraisons');
              
            } catch (e) {
              debugPrint('Erreur lors du traitement des données: $e');
              // Si le décodage du JSON échoue, essayer de comprendre la structure
              if (response.body.startsWith('[') && response.body.endsWith(']')) {
                // C'est probablement un tableau JSON direct
                try {
                  final List<dynamic> items = jsonDecode(response.body);
                  List<BonLivraison> livraisons = [];
                  for (var item in items) {
                    livraisons.add(BonLivraison.fromJson(item));
                  }
                  debugPrint('Livraisons récupérées avec succès (format alternatif): ${livraisons.length} livraisons');
                  return livraisons;
                } catch (e) {
                  debugPrint('Erreur lors du décodage du tableau JSON: $e');
                }
              }
              
              throw Exception('Erreur de traitement des données de livraison: $e');
            }
          }
        } catch (e) {
          debugPrint('Erreur avec URL $url: $e');
          lastException = e is Exception ? e : Exception(e.toString());
          // Continuer avec l'URL suivante
        }
      }
      
      // Si toutes les tentatives échouent, lever l'exception
      if (lastException != null) {
        throw lastException;
      } else {
        throw Exception('Échec de récupération des livraisons avec toutes les URLs');
      }
    } catch (e) {
      debugPrint('Erreur lors de la récupération des livraisons: $e');
      throw Exception('Erreur lors de la récupération des livraisons: $e');
    }
  }
  
  // Méthode pour mettre à jour le statut d'une livraison
  Future<bool> updateLivraisonStatus(int livraisonId, String status, {String? commentaire}) async {
    try {
      debugPrint('Mise à jour du statut pour livraison $livraisonId: $status');
      
      // Préparer les données pour la requête
      final Map<String, dynamic> requestData = {
        'id': livraisonId,
        'statut': status,
      };
      
      // Ajouter le commentaire s'il est fourni
      if (commentaire != null && commentaire.isNotEmpty) {
        requestData['commentaire'] = commentaire;
      }
      
      debugPrint('Corps de la requête: ${jsonEncode(requestData)}');
      
      // Liste des URLs à essayer
      List<String> urlsToTry = [
        '$baseUrl/commandes/update_status.php',
        '$baseUrl/api/commandes/update_status.php',
        '${baseUrl.replaceAll('/api_php/api', '')}/api_php/api/commandes/update_status.php',
      ];
      
      Exception? lastException;
      
      // Essayer chaque URL jusqu'à ce qu'une fonctionne
      for (String url in urlsToTry) {
        try {
          debugPrint('Essai avec l\'URL: $url');
          
          // Essayer d'abord avec Content-Type: application/json
          var response = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestData),
          ).timeout(
            Duration(seconds: ApiConfig.timeout),
            onTimeout: () => throw TimeoutException('Délai d\'attente dépassé pour la mise à jour du statut')
          );
          
          // Si échec, essayer avec application/x-www-form-urlencoded
          if (response.statusCode != 200) {
            debugPrint('Réessai avec Content-Type: application/x-www-form-urlencoded');
            
            // Préparer les données au format form-urlencoded
            String formBody = '';
            requestData.forEach((key, value) {
              if (formBody.isNotEmpty) formBody += '&';
              formBody += '$key=$value';
            });
            
            response = await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/x-www-form-urlencoded'},
              body: formBody,
            ).timeout(
              Duration(seconds: ApiConfig.timeout),
              onTimeout: () => throw TimeoutException('Délai d\'attente dépassé pour la mise à jour du statut')
            );
          }
          
          debugPrint('Réponse de $url: ${response.statusCode}');
          debugPrint('Corps de la réponse: ${response.body}');
          
          if (response.statusCode == 200) {
            try {
              final responseData = jsonDecode(response.body);
              
              // Format 1: {"success": true}
              if (responseData is Map<String, dynamic> && responseData.containsKey('success') && responseData['success'] == true) {
                debugPrint('Mise à jour du statut réussie (format 1)');
                return true;
              }
              
              // Format 2: {"status": "success"}
              else if (responseData is Map<String, dynamic> && responseData.containsKey('status') && responseData['status'] == 'success') {
                debugPrint('Mise à jour du statut réussie (format 2)');
                return true;
              }
              
              // Format 3: true (booléen)
              else if (responseData is bool && responseData) {
                debugPrint('Mise à jour du statut réussie (format 3)');
                return true;
              }
              
              // Format 4: "success" (chaîne)
              else if (responseData is String && (responseData.toLowerCase() == 'success' || responseData.toLowerCase() == 'true')) {
                debugPrint('Mise à jour du statut réussie (format 4)');
                return true;
              }
              
              // Vérifier la réponse brute si les formats précédents ne correspondent pas
              if (response.body.toLowerCase().contains('success') || response.body.toLowerCase().contains('réussi')) {
                debugPrint('Mise à jour du statut réussie (vérification du texte brut)');
                return true;
              }
              
              debugPrint('Format de réponse non reconnu pour la mise à jour du statut: $responseData');
              return false;
              
            } catch (e) {
              debugPrint('Erreur lors du décodage JSON pour la mise à jour: $e');
              
              // Vérifier si la réponse brute indique un succès
              if (response.body.toLowerCase().contains('success') || response.body.toLowerCase().contains('réussi')) {
                debugPrint('Mise à jour du statut réussie (vérification du texte brut après erreur)');
                return true;
              }
              
              throw Exception('Erreur lors du décodage de la réponse pour la mise à jour du statut: $e');
            }
          }
        } catch (e) {
          debugPrint('Erreur avec URL $url: $e');
          lastException = e is Exception ? e : Exception(e.toString());
          // Continuer avec l'URL suivante
        }
      }
      
      // Si toutes les tentatives échouent, lever l'exception
      if (lastException != null) {
        throw lastException;
      } else {
        throw Exception('Échec de mise à jour du statut avec toutes les URLs');
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du statut: $e');
      throw Exception('Erreur lors de la mise à jour du statut: $e');
    }
  }
  
  // Méthode pour récupérer uniquement les livraisons en attente ou en cours
  Future<List<BonLivraison>> getLivraisonsEnAttente(int agentId) async {
    try {
      final livraisons = await getLivraisonsByAgent(agentId);
      return livraisons.where((livraison) => 
        livraison.status == 'en_attente' || livraison.status == 'en_cours').toList();
    } catch (e) {
      debugPrint('Erreur lors de la récupération des livraisons en attente: $e');
      throw Exception('Erreur lors de la récupération des livraisons en attente: $e');
    }
  }
  
  // Méthode pour tester la connexion à l'API
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ping.php'),
      ).timeout(
        Duration(seconds: 5),
        onTimeout: () => http.Response('timeout', 408)
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Erreur lors du test de connexion: $e');
      return false;
    }
  }
}

// Exception personnalisée pour les délais dépassés
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
} 