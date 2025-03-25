<?php
class Database
{
    // Paramètres de connexion à la base de données
    private $host = "localhost";
    private $db_name = "app_livreur";
    private $username = "root"; // Utilisateur par défaut de XAMPP
    private $password = ""; // Mot de passe par défaut de XAMPP (vide)
    public $conn;

    // Méthode pour se connecter à la base de données
    public function getConnection()
    {
        $this->conn = null;

        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name,
                $this->username,
                $this->password
            );
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->exec("set names utf8");
        } catch (PDOException $e) {
            echo "Erreur de connexion: " . $e->getMessage();
        }

        return $this->conn;
    }
} 