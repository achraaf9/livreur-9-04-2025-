<?php
// Inclure les en-têtes CORS pour permettre l'accès depuis n'importe quelle origine
require_once '../../cors_fix.php';

// Inclure les fichiers nécessaires
require_once '../../config/database.php';
require_once '../../models/Agent.php';

// Afficher des informations détaillées pour le débogage (à enlever en production)
error_log("Requête de connexion reçue");
error_log("Méthode: " . $_SERVER['REQUEST_METHOD']);

// Se connecter à la base de données
$database = new Database();
$db = $database->getConnection();

// Récupérer les données du corps de la requête POST
$data = json_decode(file_get_contents("php://input"));
error_log("Données reçues: " . json_encode($data));

// Si aucune donnée n'est fournie, essayer de récupérer depuis $_POST
if (!$data) {
    $data = (object) $_POST;
    error_log("Utilisation des données POST: " . json_encode($data));
}

// Vérifier que les informations de connexion sont fournies
if (!isset($data->email) || !isset($data->password)) {
    // Informations de connexion manquantes
    http_response_code(400);
    echo json_encode([
        "success" => false,
        "message" => "Email et mot de passe requis pour la connexion"
    ]);
    exit;
}

// Instancier l'objet Agent
$agent = new Agent($db);

// Vérifier si l'agent existe avec l'email fourni
if ($agent->findByEmail($data->email)) {
    // Vérifier si le mot de passe correspond
    if ($agent->verifyPassword($data->password)) {
        // Authentification réussie
        http_response_code(200);
        echo json_encode([
            "success" => true,
            "message" => "Authentification réussie",
            "agent" => [
                "id" => $agent->id,
                "nom" => $agent->nom,
                "prenom" => $agent->prenom,
                "email" => $agent->email,
                "telephone" => $agent->tele
            ]
        ]);
        error_log("Authentification réussie pour l'email: " . $data->email);
    } else {
        // Mot de passe incorrect
        http_response_code(401);
        echo json_encode([
            "success" => false,
            "message" => "Mot de passe incorrect"
        ]);
        error_log("Échec d'authentification: mot de passe incorrect pour " . $data->email);
    }
} else {
    // Agent non trouvé
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Aucun agent trouvé avec cet email"
    ]);
    error_log("Échec d'authentification: aucun agent trouvé avec l'email " . $data->email);
}
?>
