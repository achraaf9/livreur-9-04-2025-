<?php
// VERSION CORRIGÉE - 25/03/2025
class Commande {
    // Connexion à la base de données et nom de la table
    private $conn;
    private $table_name = "commandes";
    private $table_affectations = "affectations_livreur";
    private $table_clients = "clients";
    private $table_adresses = "adresses";

    // Propriétés de l'objet Commande
    public $id;
    public $reference;
    public $client_id;
    public $adresse_id;
    public $date_commande;
    public $date_livraison_prevue;
    public $montant;
    public $statut;
    public $commentaire;
    public $created_at;
    public $updated_at;

    // Propriétés supplémentaires pour les jointures
    public $nom_client;
    public $telephone_client;
    public $ligne1;
    public $ligne2;
    public $ville;
    public $code_postal;
    public $pays;

    // Constructeur avec connexion à la base de données
    public function __construct($db) {
        $this->conn = $db;
    }

    // Récupérer les commandes par livreur
    public function getCommandesByLivreur($livreur_id) {
        // Requête pour récupérer les commandes assignées à un livreur avec les informations du client et de l'adresse
        $query = "
            SELECT c.id, c.reference, c.date_commande, c.date_livraison_prevue, c.montant, c.statut, c.commentaire,
                   cl.nom as nom_client, cl.prenom as prenom_client, cl.tele as tele, cl.email as email_client,
                   a.rue, a.ville, a.code_postal
            FROM " . $this->table_name . " c
            INNER JOIN " . $this->table_affectations . " al ON c.id = al.commande_id
            INNER JOIN " . $this->table_clients . " cl ON c.client_id = cl.id
            INNER JOIN " . $this->table_adresses . " a ON c.adresse_id = a.id
            WHERE al.livreur_id = ?
            ORDER BY c.date_livraison_prevue DESC";
        
        // Log pour le débogage
        error_log("Requête SQL: " . $query);
        error_log("Table affectations: " . $this->table_affectations);
        error_log("Table clients: " . $this->table_clients);
        error_log("Table adresses: " . $this->table_adresses);
        
        // Préparer la requête
        $stmt = $this->conn->prepare($query);
        
        // Nettoyer la donnée
        $livreur_id = htmlspecialchars(strip_tags($livreur_id));
        
        // Lier l'ID du livreur
        $stmt->bindParam(1, $livreur_id);
        
        // Exécuter la requête
        try {
            $stmt->execute();
            error_log("Requête exécutée avec succès");
            return $stmt;
        } catch (PDOException $e) {
            error_log("Erreur lors de l'exécution de la requête: " . $e->getMessage());
            throw $e;
        }
    }

    // Mettre à jour le statut d'une commande
    public function updateStatus($id, $status, $commentaire = null) {
        // Convertir le statut si nécessaire
        if ($status == 'en_attente') {
            $statut_db = 'En attente';
        } else if ($status == 'livre') {
            $statut_db = 'Livrée';
        } else if ($status == 'non_livre') {
            $statut_db = 'Non livrée';
        } else {
            $statut_db = $status;
        }
        
        // Requête pour mettre à jour le statut
        $query = "UPDATE " . $this->table_name . " SET statut = ?";
        
        // Ajouter le commentaire si fourni
        if ($commentaire !== null) {
            $query .= ", commentaire = ?";
        }
        
        $query .= " WHERE id = ?";
        
        // Préparer la requête
        $stmt = $this->conn->prepare($query);
        
        // Nettoyer les données
        $statut_db = htmlspecialchars(strip_tags($statut_db));
        $id = htmlspecialchars(strip_tags($id));
        
        // Lier les paramètres
        $stmt->bindParam(1, $statut_db);
        
        if ($commentaire !== null) {
            $commentaire = htmlspecialchars(strip_tags($commentaire));
            $stmt->bindParam(2, $commentaire);
            $stmt->bindParam(3, $id);
        } else {
            $stmt->bindParam(2, $id);
        }
        
        // Exécuter la requête
        if($stmt->execute()) {
            return true;
        }
        
        return false;
    }

    // Récupérer les détails d'une commande spécifique
    public function readOne() {
        // Requête pour lire une seule commande avec les informations du client et de l'adresse
        $query = "
            SELECT c.id, c.reference, c.date_commande, c.date_livraison_prevue, c.montant, c.statut, c.commentaire,
                   cl.id as client_id, cl.nom as nom_client, cl.prenom as prenom_client, cl.email as email_client, cl.tele as tele,
                   a.id as adresse_id, a.rue, a.ville, a.code_postal, a.quartier, a.complement
            FROM " . $this->table_name . " c
            INNER JOIN clients cl ON c.client_id = cl.id
            INNER JOIN adresses a ON c.adresse_id = a.id
            WHERE c.id = ?";
        
        // Préparer la requête
        $stmt = $this->conn->prepare($query);
        
        // Lier l'ID
        $stmt->bindParam(1, $this->id);
        
        // Exécuter la requête
        $stmt->execute();
        
        return $stmt;
    }
} 