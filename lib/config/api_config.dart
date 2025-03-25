class ApiConfig {
  // URL de base de l'API PHP
  static String get baseUrl {
    // Détection automatique de l'environnement
    bool isWeb = identical(0, 0.0);  // Simple méthode pour détecter si on est sur le web
    bool isEmulator = !isWeb && false; // Vous pouvez ajouter une détection spécifique d'émulateur si nécessaire
    
    // Si exécution sur le web
    if (isWeb) {
      return "http://localhost/livraison_api/api_php/api";
    }
    
    // Si exécution sur un émulateur Android
    if (isEmulator) {
      return "http://10.0.2.2/livraison_api/api_php/api";
    }
    
    // Pour les appareils physiques, utiliser l'adresse IP du serveur dans le réseau local
    // Votre adresse IP selon ipconfig
    return "http://192.168.100.140/livraison_api/api_php/api";
  }
  
  // URL complète pour la connexion - plusieurs tentatives
  static List<String> get loginUrls {
    // Essayer plusieurs chemins possibles pour trouver le bon endpoint
    return [
      '$baseUrl/agents/login.php',     // Chemin qui fonctionne selon les logs
      '${baseUrl.replaceAll('/api', '')}/login.php', // Autre possibilité
      '$baseUrl/../login.php',         // Niveau supérieur
      '${baseUrl.replaceAll('/api_php/api', '')}/login.php', // Racine
      // Ajouter une option qui ignore complètement le chemin précédent
      'http://192.168.100.140/livraison_api/api_php/api/agents/login.php',
    ];
  }
  
  // Point d'entrée principal pour l'authentification
  static String get loginUrl => loginUrls[0];
  
  // Activer l'utilisation de plusieurs URLs d'authentification si la première échoue
  static const bool tryMultipleLoginUrls = true;
  
  // Timeout pour les requêtes HTTP (en secondes)
  static const int timeout = 30; // Augmenté pour donner plus de temps aux requêtes
  
  // Désactivation complète des données statiques
  static const bool useStaticDataOnFailure = false;
  static const bool useStaticDataByDefault = false;
  
  // Liste des URLs à essayer pour récupérer les livraisons d'un agent
  static List<String> getLivraisonUrls(int agentId) {
    return [
      // Utiliser en priorité le script de débogage qui corrige le problème d'affichage
      '${baseUrl.replaceAll('/api_php/api', '')}/debug_bon_livraison.php?id=$agentId',
      
      // Anciennes URLs comme fallback
      '$baseUrl/commandes/get_by_livreur.php?id=$agentId',
      '$baseUrl/commandes/get_by_livreur.php?livreur_id=$agentId',
      '$baseUrl/../commandes/get_by_livreur.php?id=$agentId',
      '${baseUrl.replaceAll('/api_php/api', '')}/api_php/api/commandes/get_by_livreur.php?id=$agentId',
      'http://192.168.100.140/livraison_api/api_php/api/commandes/get_by_livreur.php?id=$agentId',
    ];
  }
  
  // Désactivation du mot de passe par défaut
  static const bool allowDefaultPassword = false;
  
  // Mot de passe par défaut pour les tests (inutilisé mais conservé pour la compatibilité)
  static const String defaultPassword = "password123";
} 