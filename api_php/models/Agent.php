<?php
class Agent {
    // Connexion à la base de données et nom de la table
    private $conn;
    private $table_name = "livreurs";
    
    // Propriétés de l'objet
    public $id;
    public $nom;
    public $prenom;
    public $tele;
    public $email;
    public $password;
    
    // Constructeur avec $db pour la connexion à la base de données
    public function __construct($db) {
        $this->conn = $db;
    }
    
    // Méthode pour trouver un agent par son email
    public function findByEmail($email) {
        // Protéger contre les injections SQL
        $email = htmlspecialchars(strip_tags($email));
        
        // Requête pour vérifier si l'email existe
        $query = "SELECT id, nom, prenom, tele, email, password 
                  FROM " . $this->table_name . " 
                  WHERE email = ?";
        
        // Préparer la requête
        $stmt = $this->conn->prepare($query);
        
        // Lier l'email au paramètre
        $stmt->bindParam(1, $email);
        
        // Exécuter la requête
        $stmt->execute();
        
        // Vérifier si un enregistrement a été trouvé
        if($stmt->rowCount() > 0) {
            // Récupérer les données
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Définir les valeurs des propriétés
            $this->id = $row['id'];
            $this->nom = $row['nom'];
            $this->prenom = $row['prenom'];
            $this->tele = $row['tele'];
            $this->email = $row['email'];
            $this->password = $row['password'];
            
            return true;
        }
        
        return false;
    }
    
    // Méthode pour vérifier le mot de passe
    public function verifyPassword($password) {
        // En production, vous devriez utiliser password_verify si les mots de passe sont hashés
        // Pour cet exemple, on compare directement (non sécurisé)
        return $this->password === $password;
    }
    
    // Lire tous les agents
    public function readAll() {
        // Requête pour lire tous les agents
        $query = "SELECT id, nom, prenom, tele, email 
                  FROM " . $this->table_name . " 
                  ORDER BY id";
        
        // Préparer la requête
        $stmt = $this->conn->prepare($query);
        
        // Exécuter la requête
        $stmt->execute();
        
        return $stmt;
    }
    
    // Lire un agent spécifique par son ID
    public function readOne() {
        // Requête pour lire un seul agent
        $query = "SELECT id, nom, prenom, tele, email 
                  FROM " . $this->table_name . " 
                  WHERE id = ?";
        
        // Préparer la requête
        $stmt = $this->conn->prepare($query);
        
        // Lier l'ID au paramètre
        $stmt->bindParam(1, $this->id);
        
        // Exécuter la requête
        $stmt->execute();
        
        // Vérifier si un enregistrement a été trouvé
        if($stmt->rowCount() > 0) {
            // Récupérer les données
            $row = $stmt->fetch(PDO::FETCH_ASSOC);
            
            // Définir les valeurs des propriétés
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
?> 