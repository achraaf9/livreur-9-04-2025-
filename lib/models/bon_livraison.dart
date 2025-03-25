class BonLivraison {
  final int id;
  final String reference;
  final String clientNom;
  final String clientPrenom;
  final String clientEmail;
  final String clientAdresse;
  final String clientTelephone;
  final String villeClient;
  final String codePostal;
  String status;
  String commentaire;
  final String dateCommande;
  final String dateLivraison;
  final double montantTotal;

  BonLivraison({
    required this.id,
    required this.reference,
    required this.clientNom,
    this.clientPrenom = '',
    this.clientEmail = '',
    required this.clientAdresse,
    required this.clientTelephone,
    required this.villeClient,
    this.codePostal = '',
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
    
    // Gérer les différents formats pour le nom client
    String nomClient = '';
    if (json['clientNom'] != null) {
      nomClient = json['clientNom'].toString();
    } else if (json['client_nom'] != null) {
      nomClient = json['client_nom'].toString();
    } else if (json['nom_client'] != null) {
      nomClient = json['nom_client'].toString();
    } else if (json.containsKey('client') && json['client'] is Map && json['client']['nom'] != null) {
      nomClient = json['client']['nom'].toString();
    }
    
    // Gérer les différents formats pour le prénom client
    String prenomClient = '';
    if (json['clientPrenom'] != null) {
      prenomClient = json['clientPrenom'].toString();
    } else if (json['client_prenom'] != null) {
      prenomClient = json['client_prenom'].toString();
    } else if (json['prenom_client'] != null) {
      prenomClient = json['prenom_client'].toString();
    } else if (json.containsKey('client') && json['client'] is Map && json['client']['prenom'] != null) {
      prenomClient = json['client']['prenom'].toString();
    }
    
    // Gérer les différents formats pour l'email client
    String emailClient = '';
    if (json['clientEmail'] != null) {
      emailClient = json['clientEmail'].toString();
    } else if (json['client_email'] != null) {
      emailClient = json['client_email'].toString();
    } else if (json['email_client'] != null) {
      emailClient = json['email_client'].toString();
    } else if (json.containsKey('client') && json['client'] is Map && json['client']['email'] != null) {
      emailClient = json['client']['email'].toString();
    }
    
    // Gérer les différents formats pour l'adresse client
    String adresseClient = '';
    if (json['clientAdresse'] != null) {
      adresseClient = json['clientAdresse'].toString();
    } else if (json['client_adresse'] != null) {
      adresseClient = json['client_adresse'].toString();
    } else if (json['rue'] != null) {
      adresseClient = json['rue'].toString();
    } else if (json.containsKey('adresse') && json['adresse'] is Map && json['adresse']['rue'] != null) {
      adresseClient = json['adresse']['rue'].toString();
    }
    
    // Gérer les différents formats pour le téléphone client
    String telephoneClient = '';
    if (json['clientTelephone'] != null) {
      telephoneClient = json['clientTelephone'].toString();
    } else if (json['client_telephone'] != null) {
      telephoneClient = json['client_telephone'].toString();
    } else if (json['tele'] != null) {
      telephoneClient = json['tele'].toString();
    } else if (json.containsKey('client') && json['client'] is Map && json['client']['telephone'] != null) {
      telephoneClient = json['client']['telephone'].toString();
    }
    
    // Gérer les différents formats pour la ville
    String ville = '';
    if (json['villeClient'] != null) {
      ville = json['villeClient'].toString();
    } else if (json['ville_client'] != null) {
      ville = json['ville_client'].toString();
    } else if (json['ville'] != null) {
      ville = json['ville'].toString();
    } else if (json.containsKey('adresse') && json['adresse'] is Map && json['adresse']['ville'] != null) {
      ville = json['adresse']['ville'].toString();
    }
    
    // Gérer les différents formats pour le code postal
    String codePostal = '';
    if (json['codePostal'] != null) {
      codePostal = json['codePostal'].toString();
    } else if (json['code_postal'] != null) {
      codePostal = json['code_postal'].toString();
    } else if (json.containsKey('adresse') && json['adresse'] is Map && json['adresse']['code_postal'] != null) {
      codePostal = json['adresse']['code_postal'].toString();
    }
    
    // Gérer les différents formats pour le statut
    String statut = 'en_attente';
    if (json['status'] != null) {
      statut = json['status'].toString();
    } else if (json['statut'] != null) {
      // Convertir le statut du format de la base de données au format attendu par l'app
      String statutBD = json['statut'].toString();
      if (statutBD == 'En attente') {
        statut = 'en_attente';
      } else if (statutBD == 'Livrée') {
        statut = 'livre';
      } else if (statutBD == 'Non livrée') {
        statut = 'non_livre';
      } else {
        statut = statutBD.toLowerCase();
      }
    }
    
    // Gérer les différents formats pour les dates
    String dateCmd = '';
    if (json['dateCommande'] != null) {
      dateCmd = json['dateCommande'].toString();
    } else if (json['date_commande'] != null) {
      dateCmd = json['date_commande'].toString();
    }
    
    String dateLiv = '';
    if (json['dateLivraison'] != null) {
      dateLiv = json['dateLivraison'].toString();
    } else if (json['date_livraison_prevue'] != null) {
      dateLiv = json['date_livraison_prevue'].toString();
    } else if (json['date_livraison'] != null) {
      dateLiv = json['date_livraison'].toString();
    }
    
    // Gérer les différents types possibles pour le montant total
    double parsedMontant = 0;
    if (json['montantTotal'] != null) {
      if (json['montantTotal'] is double) {
        parsedMontant = json['montantTotal'];
      } else if (json['montantTotal'] is int) {
        parsedMontant = json['montantTotal'].toDouble();
      } else if (json['montantTotal'] is String) {
        parsedMontant = double.tryParse(json['montantTotal']) ?? 0;
      }
    } else if (json['montant'] != null) {
      if (json['montant'] is double) {
        parsedMontant = json['montant'];
      } else if (json['montant'] is int) {
        parsedMontant = json['montant'].toDouble();
      } else if (json['montant'] is String) {
        parsedMontant = double.tryParse(json['montant']) ?? 0;
      }
    } else if (json['montant_total'] != null) {
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
      clientNom: nomClient.isNotEmpty ? nomClient : 'Client inconnu',
      clientPrenom: prenomClient,
      clientEmail: emailClient,
      clientAdresse: adresseClient.isNotEmpty ? adresseClient : 'Adresse inconnue',
      clientTelephone: telephoneClient.isNotEmpty ? telephoneClient : 'Téléphone inconnu',
      villeClient: ville.isNotEmpty ? ville : 'Ville inconnue',
      codePostal: codePostal,
      status: statut,
      commentaire: json['commentaire']?.toString() ?? '',
      dateCommande: dateCmd,
      dateLivraison: dateLiv,
      montantTotal: parsedMontant,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'client_nom': clientNom,
      'client_prenom': clientPrenom,
      'client_email': clientEmail,
      'client_adresse': clientAdresse,
      'client_telephone': clientTelephone,
      'ville_client': villeClient,
      'code_postal': codePostal,
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
    String? clientPrenom,
    String? clientEmail,
    String? clientAdresse,
    String? clientTelephone,
    String? villeClient,
    String? codePostal,
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
      clientPrenom: clientPrenom ?? this.clientPrenom,
      clientEmail: clientEmail ?? this.clientEmail,
      clientAdresse: clientAdresse ?? this.clientAdresse,
      clientTelephone: clientTelephone ?? this.clientTelephone,
      villeClient: villeClient ?? this.villeClient,
      codePostal: codePostal ?? this.codePostal,
      status: status ?? this.status,
      commentaire: commentaire ?? this.commentaire,
      dateCommande: dateCommande ?? this.dateCommande,
      dateLivraison: dateLivraison ?? this.dateLivraison,
      montantTotal: montantTotal ?? this.montantTotal,
    );
  }
} 