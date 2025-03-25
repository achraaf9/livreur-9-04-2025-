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
    required this.clientPrenom,
    required this.clientEmail,
    required this.clientAdresse,
    required this.clientTelephone,
    required this.villeClient,
    required this.codePostal,
    required this.status,
    required this.commentaire,
    required this.dateCommande,
    required this.dateLivraison,
    required this.montantTotal,
  });

  factory BonLivraison.fromJson(Map<String, dynamic> json) {
    return BonLivraison(
      id: json['id'] ?? 0,
      reference: json['reference'] ?? '',
      clientNom: json['clientNom'] ?? '',
      clientPrenom: json['clientPrenom'] ?? '',
      clientEmail: json['clientEmail'] ?? '',
      clientAdresse: json['clientAdresse'] ?? '',
      clientTelephone: json['clientTelephone'] ?? '',
      villeClient: json['villeClient'] ?? '',
      codePostal: json['codePostal'] ?? '',
      status: json['status'] ?? 'en_attente',
      commentaire: json['commentaire'] ?? '',
      dateCommande: json['dateCommande'] ?? '',
      dateLivraison: json['dateLivraison'] ?? '',
      montantTotal: (json['montantTotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'clientNom': clientNom,
      'clientPrenom': clientPrenom,
      'clientEmail': clientEmail,
      'clientAdresse': clientAdresse,
      'clientTelephone': clientTelephone,
      'villeClient': villeClient,
      'codePostal': codePostal,
      'status': status,
      'commentaire': commentaire,
      'dateCommande': dateCommande,
      'dateLivraison': dateLivraison,
      'montantTotal': montantTotal,
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