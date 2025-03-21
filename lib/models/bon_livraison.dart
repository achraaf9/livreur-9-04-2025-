class BonLivraison {
  final int id;
  final String reference;
  final String clientNom;
  final String clientAdresse;
  final String clientTelephone;
  final String villeClient;
  final String status;
  final String commentaire;
  final String dateCommande;
  final String dateLivraison;
  final double montantTotal;

  BonLivraison({
    required this.id,
    required this.reference,
    required this.clientNom,
    required this.clientAdresse,
    required this.clientTelephone,
    required this.villeClient,
    required this.status,
    this.commentaire = '',
    this.dateCommande = '',
    this.dateLivraison = '',
    this.montantTotal = 0,
  });

  factory BonLivraison.fromJson(Map<String, dynamic> json) {
    // Afficher les données reçues pour le débogage
    print('Données JSON reçues: $json');
    
    // Gérer les différents types possibles pour l'ID
    int parsedId;
    if (json['id'] is int) {
      parsedId = json['id'];
    } else if (json['id'] is String) {
      parsedId = int.tryParse(json['id']) ?? 0;
    } else {
      parsedId = 0;
    }
    
    // Gérer les différents types possibles pour le montant total
    double parsedMontant = 0;
    if (json['montant_total'] != null) {
      if (json['montant_total'] is double) {
        parsedMontant = json['montant_total'];
      } else if (json['montant_total'] is int) {
        parsedMontant = json['montant_total'].toDouble();
      } else if (json['montant_total'] is String) {
        parsedMontant = double.tryParse(json['montant_total']) ?? 0;
      }
    }
    
    return BonLivraison(
      id: parsedId,
      reference: json['reference']?.toString() ?? 'Sans référence',
      clientNom: json['client_nom']?.toString() ?? 'Client inconnu',
      clientAdresse: json['client_adresse']?.toString() ?? 'Adresse inconnue',
      clientTelephone: json['client_telephone']?.toString() ?? 'Téléphone inconnu',
      villeClient: json['ville_client']?.toString() ?? 'Ville inconnue',
      status: json['status']?.toString() ?? 'en_attente',
      commentaire: json['commentaire']?.toString() ?? '',
      dateCommande: json['date_commande']?.toString() ?? '',
      dateLivraison: json['date_livraison']?.toString() ?? '',
      montantTotal: parsedMontant,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'client_nom': clientNom,
      'client_adresse': clientAdresse,
      'client_telephone': clientTelephone,
      'ville_client': villeClient,
      'status': status,
      'commentaire': commentaire,
      'date_commande': dateCommande,
      'date_livraison': dateLivraison,
      'montant_total': montantTotal,
    };
  }

  BonLivraison copyWith({
    int? id,
    String? reference,
    String? clientNom,
    String? clientAdresse,
    String? clientTelephone,
    String? villeClient,
    String? status,
    String? commentaire,
    String? dateCommande,
    String? dateLivraison,
    double? montantTotal,
  }) {
    return BonLivraison(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      clientNom: clientNom ?? this.clientNom,
      clientAdresse: clientAdresse ?? this.clientAdresse,
      clientTelephone: clientTelephone ?? this.clientTelephone,
      villeClient: villeClient ?? this.villeClient,
      status: status ?? this.status,
      commentaire: commentaire ?? this.commentaire,
      dateCommande: dateCommande ?? this.dateCommande,
      dateLivraison: dateLivraison ?? this.dateLivraison,
      montantTotal: montantTotal ?? this.montantTotal,
    );
  }
} 