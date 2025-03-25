import 'dart:developer' as developer;
import 'dart:convert';

class ApiLogger {
  static bool isEnabled = true;
  
  // Journaliser les requêtes API
  static void logRequest(String url, String method, {Map<String, dynamic>? body, Map<String, String>? headers}) {
    if (!isEnabled) return;
    
    developer.log(
      '📤 API REQUEST [$method] $url',
      name: 'ApiLogger',
      time: DateTime.now(),
    );
    
    if (headers != null) {
      developer.log(
        '📤 Headers: ${jsonEncode(headers)}',
        name: 'ApiLogger',
        time: DateTime.now(),
      );
    }
    
    if (body != null) {
      developer.log(
        '📤 Body: ${jsonEncode(body)}',
        name: 'ApiLogger',
        time: DateTime.now(),
      );
    }
  }
  
  // Journaliser les réponses API
  static void logResponse(String url, int statusCode, String responseBody) {
    if (!isEnabled) return;
    
    final emoji = statusCode >= 200 && statusCode < 300 ? '✅' : '❌';
    
    developer.log(
      '$emoji API RESPONSE [$statusCode] $url',
      name: 'ApiLogger',
      time: DateTime.now(),
    );
    
    try {
      // Essayer de formater la réponse JSON pour une meilleure lisibilité
      final dynamic json = jsonDecode(responseBody);
      developer.log(
        '$emoji Response: ${const JsonEncoder.withIndent('  ').convert(json)}',
        name: 'ApiLogger',
        time: DateTime.now(),
      );
    } catch (e) {
      // Si la réponse n'est pas du JSON, l'afficher telle quelle
      developer.log(
        '$emoji Response (non-JSON): $responseBody',
        name: 'ApiLogger', 
        time: DateTime.now(),
      );
    }
  }
  
  // Journaliser les erreurs API
  static void logError(String url, dynamic error, StackTrace? stackTrace) {
    if (!isEnabled) return;
    
    developer.log(
      '❌ API ERROR for $url: $error',
      name: 'ApiLogger',
      time: DateTime.now(),
      error: error,
      stackTrace: stackTrace,
    );
  }
} 