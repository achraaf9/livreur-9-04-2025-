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
    // Gestion de l'ID qui peut être un entier ou une chaîne
    int agentId;
    if (json['id'] is int) {
      agentId = json['id'];
    } else if (json['id'] is String) {
      agentId = int.tryParse(json['id']) ?? 0;
    } else {
      agentId = 0;
    }
    
    return Agent(
      id: agentId,
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'] ?? '',
      role: json['role'] ?? 'livreur',
      statut: json['statut'] ?? 'actif',
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