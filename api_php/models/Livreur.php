<?php
class Livreur {
    // Connexion à la base de données et nom de la table
    private $conn;
    private $table_name = "livreurs";

    // Propriétés de l'objet Livreur
    public $id;
    public $nom;
    public $prenom;
    public $tele;
    public $email;
    public $password;
    public $created_at;
    public $updated_at;

    // Constructeur avec la connexion à la base de données
    public function __construct($db) {
        $this->conn = $db;
    }

    // Vérifier si l'email existe
    public function emailExists() {
        // Requête pour vérifier si l'email existe
        $query = "SELECT id, nom, prenom, tele, email, password 
                FROM " . $this->table_name . " 
                WHERE email = ?
                LIMIT 0,1";

        // Préparer la requête
        $stmt = $this->conn->prepare($query);

        // Nettoyer l'email (sécurité)
        $this->email = htmlspecialchars(strip_tags($this->email));

        // Lier l'email au paramètre de la requête
        $stmt->bindParam(1, $this->email);

        // Exécuter la requête
        $stmt->execute();

        // Vérifier si on a trouvé un résultat
        $num = $stmt->rowCount();

        // Si l'email existe, affecter les valeurs aux propriétés de l'objet
        if($num > 0) {
            // Récupérer les détails
            $row = $stmt->fetch(PDO::FETCH_ASSOC);

            // Assigner les valeurs aux propriétés de l'objet
            $this->id = $row['id'];
            $this->nom = $row['nom'];
            $this->prenom = $row['prenom'];
            $this->tele = $row['tele'];
            $this->email = $row['email'];
            $this->password = $row['password'];

            // Retourner true car l'email existe dans la base
            return true;
        }

        // Retourner false si l'email n'existe pas
        return false;
    }

    // Récupérer tous les livreurs
    public function read() {
        // Requête pour lire tous les livreurs
        $query = "SELECT * FROM " . $this->table_name;

        // Préparer la requête
        $stmt = $this->conn->prepare($query);

        // Exécuter la requête
        $stmt->execute();

        return $stmt;
    }

    // Récupérer un livreur par son ID
    public function readOne() {
        // Requête pour lire un seul livreur
        $query = "SELECT * FROM " . $this->table_name . " WHERE id = ? LIMIT 0,1";

        // Préparer la requête
        $stmt = $this->conn->prepare($query);

        // Lier l'ID à la requête
        $stmt->bindParam(1, $this->id);

        // Exécuter la requête
        $stmt->execute();

        // Récupérer le résultat
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        // Si on a trouvé un résultat, assigner les valeurs
        if($row) {
            $this->id = $row['id'];
            $this->nom = $row['nom'];
            $this->prenom = $row['prenom'];
            $this->tele = $row['tele'];
            $this->email = $row['email'];
            return true;
        }

        return false;
    }
} 