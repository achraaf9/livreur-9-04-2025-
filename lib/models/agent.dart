import 'package:flutter/foundation.dart';

class Agent {
  final int id;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String role;
  final String statut;

  Agent({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.email,
    this.telephone = '',
    this.role = 'livreur',
    this.statut = 'actif',
  });

  String get nomComplet => '$prenom $nom';

  String get initiales => prenom.isNotEmpty && nom.isNotEmpty 
      ? '${prenom[0].toUpperCase()}${nom[0].toUpperCase()}'
      : 'A';

  factory Agent.fromJson(Map<String, dynamic> json) {
    // Vérifier si les données sont nulles ou vides
    if (json == null || json.isEmpty) {
      return Agent(
        id: 0,
        nom: '',
        prenom: '',
        email: '',
      );
    }
    
    // Afficher les données pour le débug
    debugPrint('Conversion JSON vers Agent: $json');
    
    // Gestion de l'ID qui peut être un entier, une chaîne ou absent
    int agentId;
    if (json.containsKey('id') && json['id'] != null) {
      if (json['id'] is int) {
        agentId = json['id'];
      } else if (json['id'] is String) {
        agentId = int.tryParse(json['id']) ?? 0;
      } else {
        agentId = 0;
      }
    } else if (json.containsKey('agent_id') && json['agent_id'] != null) {
      // Certaines APIs peuvent utiliser agent_id au lieu de id
      if (json['agent_id'] is int) {
        agentId = json['agent_id'];
      } else if (json['agent_id'] is String) {
        agentId = int.tryParse(json['agent_id']) ?? 0;
      } else {
        agentId = 0;
      }
    } else if (json.containsKey('user_id') && json['user_id'] != null) {
      // Ou user_id
      if (json['user_id'] is int) {
        agentId = json['user_id'];
      } else if (json['user_id'] is String) {
        agentId = int.tryParse(json['user_id']) ?? 0;
      } else {
        agentId = 0;
      }
    } else {
      agentId = 0;
    }
    
    // Nom peut être sous différentes clés
    String nom = '';
    if (json.containsKey('nom') && json['nom'] != null) {
      nom = json['nom'].toString();
    } else if (json.containsKey('name') && json['name'] != null) {
      nom = json['name'].toString();
    } else if (json.containsKey('lastname') && json['lastname'] != null) {
      nom = json['lastname'].toString();
    } else if (json.containsKey('nom_agent') && json['nom_agent'] != null) {
      nom = json['nom_agent'].toString();
    }
    
    // Prénom peut être sous différentes clés
    String prenom = '';
    if (json.containsKey('prenom') && json['prenom'] != null) {
      prenom = json['prenom'].toString();
    } else if (json.containsKey('firstname') && json['firstname'] != null) {
      prenom = json['firstname'].toString();
    } else if (json.containsKey('first_name') && json['first_name'] != null) {
      prenom = json['first_name'].toString();
    } else if (json.containsKey('prenom_agent') && json['prenom_agent'] != null) {
      prenom = json['prenom_agent'].toString();
    }
    
    // Email peut être sous différentes clés
    String email = '';
    if (json.containsKey('email') && json['email'] != null) {
      email = json['email'].toString();
    } else if (json.containsKey('mail') && json['mail'] != null) {
      email = json['mail'].toString();
    } else if (json.containsKey('courriel') && json['courriel'] != null) {
      email = json['courriel'].toString();
    } else if (json.containsKey('email_agent') && json['email_agent'] != null) {
      email = json['email_agent'].toString();
    }
    
    // Téléphone peut être sous différentes clés
    String telephone = '';
    if (json.containsKey('telephone') && json['telephone'] != null) {
      telephone = json['telephone'].toString();
    } else if (json.containsKey('phone') && json['phone'] != null) {
      telephone = json['phone'].toString();
    } else if (json.containsKey('tel') && json['tel'] != null) {
      telephone = json['tel'].toString();
    } else if (json.containsKey('mobile') && json['mobile'] != null) {
      telephone = json['mobile'].toString();
    }
    
    // Rôle peut être sous différentes clés
    String role = 'livreur';
    if (json.containsKey('role') && json['role'] != null) {
      role = json['role'].toString();
    } else if (json.containsKey('role_agent') && json['role_agent'] != null) {
      role = json['role_agent'].toString();
    } else if (json.containsKey('type') && json['type'] != null) {
      role = json['type'].toString();
    }
    
    // Statut peut être sous différentes clés
    String statut = 'actif';
    if (json.containsKey('statut') && json['statut'] != null) {
      statut = json['statut'].toString();
    } else if (json.containsKey('status') && json['status'] != null) {
      statut = json['status'].toString();
    } else if (json.containsKey('etat') && json['etat'] != null) {
      statut = json['etat'].toString();
    }
    
    // Logique pour inferrer les valeurs manquantes si possible
    if (email.isEmpty && json.containsKey('username') && json['username'] != null) {
      final username = json['username'].toString();
      if (username.contains('@')) {
        email = username;
      }
    }
    
    return Agent(
      id: agentId,
      nom: nom,
      prenom: prenom,
      email: email,
      telephone: telephone,
      role: role,
      statut: statut,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'role': role,
      'statut': statut,
    };
  }
} 