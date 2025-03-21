import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/agent.dart';
import '../models/bon_livraison.dart';

class ApiService {
  static ApiService? _instance;
  
  // Constructeur privé pour empêcher l'instantiation directe
  ApiService._();
  
  // Méthode d'usine pour récupérer l'instance unique
  static Future<ApiService> getInstance() async {
    if (_instance == null) {
      _instance = ApiService._();
      debugPrint('ApiService initialisé avec succès (données statiques)');
    }
    return _instance!;
  }
  
  // Liste statique d'agents
  final List<Agent> _agents = [
    Agent(
      id: 1,
      nom: 'Alami',
      prenom: 'Karim',
      email: 'karim.alami@gmail.com',
      telephone: '0612345678',
      role: 'livreur',
    ),
    Agent(
      id: 2,
      nom: 'Benani',
      prenom: 'Fatima',
      email: 'fatima.benani@gmail.com',
      telephone: '0698765432',
      role: 'livreur',
    ),
    Agent(
      id: 3,
      nom: 'Chraibi',
      prenom: 'Youssef',
      email: 'youssef.chraibi@gmail.com',
      telephone: '0654321098',
      role: 'admin',
    ),
  ];
  
  // Liste statique de bons de livraison
  final List<BonLivraison> _livraisons = [
    BonLivraison(
      id: 1,
      reference: 'BL-2023-001',
      clientNom: 'Mohammed Tazi',
      clientAdresse: '12 Avenue Hassan II',
      clientTelephone: '0611223344',
      villeClient: 'Casablanca',
      status: 'en_attente',
      dateCommande: '2023-03-15',
      dateLivraison: '2023-03-17',
      montantTotal: 1254.50,
    ),
    BonLivraison(
      id: 2,
      reference: 'BL-2023-002',
      clientNom: 'Nadia Lahlou',
      clientAdresse: '5 Rue Mohammed V',
      clientTelephone: '0622334455',
      villeClient: 'Rabat',
      status: 'en_cours',
      dateCommande: '2023-03-16',
      dateLivraison: '2023-03-18',
      montantTotal: 867.00,
    ),
    BonLivraison(
      id: 3,
      reference: 'BL-2023-003',
      clientNom: 'Hassan Benjelloun',
      clientAdresse: '20 Boulevard Zerktouni',
      clientTelephone: '0633445566',
      villeClient: 'Marrakech',
      status: 'livré',
      commentaire: 'Livré en mains propres',
      dateCommande: '2023-03-14',
      dateLivraison: '2023-03-16',
      montantTotal: 1950.75,
    ),
    BonLivraison(
      id: 4,
      reference: 'BL-2023-004',
      clientNom: 'Samir Bennani',
      clientAdresse: '7 Rue Ibn Battouta',
      clientTelephone: '0644556677',
      villeClient: 'Fès',
      status: 'en_attente',
      dateCommande: '2023-03-17',
      dateLivraison: '2023-03-19',
      montantTotal: 425.30,
    ),
    BonLivraison(
      id: 5,
      reference: 'BL-2023-005',
      clientNom: 'Laila Fassi',
      clientAdresse: '3 Avenue Mohammed VI',
      clientTelephone: '0655667788',
      villeClient: 'Tanger',
      status: 'annulé',
      commentaire: 'Client injoignable',
      dateCommande: '2023-03-13',
      dateLivraison: '2023-03-15',
      montantTotal: 765.20,
    ),
    BonLivraison(
      id: 6,
      reference: 'BL-2023-006',
      clientNom: 'Rachid Naciri',
      clientAdresse: '42 Boulevard Anfa',
      clientTelephone: '0666778899',
      villeClient: 'Casablanca',
      status: 'en_attente',
      dateCommande: '2023-03-18',
      dateLivraison: '2023-03-20',
      montantTotal: 1320.00,
    ),
    BonLivraison(
      id: 7,
      reference: 'BL-2023-007',
      clientNom: 'Amina Drissi',
      clientAdresse: '15 Rue Tariq Ibn Ziad',
      clientTelephone: '0677889900',
      villeClient: 'Agadir',
      status: 'en_cours',
      dateCommande: '2023-03-17',
      dateLivraison: '2023-03-19',
      montantTotal: 550.60,
    ),
  ];
  
  // Méthode pour authentifier un agent
  Future<Agent> authenticateAgent(String email, String password) async {
    try {
      debugPrint('Tentative d\'authentification pour $email avec données statiques');
      
      // Simuler un délai d'authentification
      await Future.delayed(const Duration(seconds: 1));
      
      // Pour cet exemple, le mot de passe est toujours "password123"
      if (password != 'password123') {
        throw Exception('Mot de passe incorrect');
      }
      
      final agent = _agents.firstWhere(
        (agent) => agent.email == email,
        orElse: () => throw Exception('Email ou mot de passe incorrect'),
      );
      
      debugPrint('Authentification réussie pour: ${agent.nomComplet}');
      return agent;
    } catch (e) {
      debugPrint('Erreur d\'authentification: $e');
      throw Exception('Email ou mot de passe incorrect');
    }
  }
  
  // Méthode pour récupérer les livraisons d'un agent
  Future<List<BonLivraison>> getLivraisonsByAgent(int agentId) async {
    try {
      debugPrint('Récupération des livraisons pour l\'agent $agentId avec données statiques');
      
      // Simuler un délai réseau
      await Future.delayed(const Duration(seconds: 1));
      
      // Dans cet exemple, toutes les livraisons sont assignées à tous les agents
      return _livraisons;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des livraisons: $e');
      throw Exception('Erreur lors de la récupération des livraisons: $e');
    }
  }
  
  // Méthode pour mettre à jour le statut d'une livraison
  Future<bool> updateLivraisonStatus(int livraisonId, String status, {String? commentaire}) async {
    try {
      debugPrint('Mise à jour du statut de la livraison $livraisonId à $status');
      
      // Simuler un délai réseau
      await Future.delayed(const Duration(seconds: 1));
      
      final index = _livraisons.indexWhere((livraison) => livraison.id == livraisonId);
      
      if (index != -1) {
        _livraisons[index] = _livraisons[index].copyWith(
          status: status,
          commentaire: commentaire ?? _livraisons[index].commentaire,
        );
        debugPrint('Statut de livraison mis à jour avec succès');
        return true;
      } else {
        debugPrint('Livraison non trouvée: $livraisonId');
        return false;
      }
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du statut: $e');
      return false;
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
  
  // Méthode pour tester la connexion à l'API (toujours réussie avec données statiques)
  Future<bool> testConnection() async {
    debugPrint('Test de connexion réussi (données statiques)');
    return true;
  }
  
  // Méthode pour tester la connexion au serveur sans authentification (toujours réussie avec données statiques)
  Future<bool> pingServer() async {
    debugPrint('Ping serveur réussi (données statiques)');
    return true;
  }
} 