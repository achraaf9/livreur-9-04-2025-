<?php
// Inclure les en-têtes CORS pour permettre l'accès depuis n'importe quelle origine
require_once '../../cors_fix.php';

// Inclure les fichiers nécessaires
require_once '../../config/database.php';
require_once '../../models/Agent.php';

// Se connecter à la base de données
$database = new Database();
$db = $database->getConnection();

// Instancier l'objet Agent
$agent = new Agent($db);

// Récupérer les agents
$stmt = $agent->readAll();

// Vérifier si des agents ont été trouvés
if($stmt->rowCount() > 0) {
    // Tableau d'agents
    $agents_arr = [];
    
    // Récupération des données
    while($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $agent_item = [
            "id" => $row['id'],
            "nom" => $row['nom'],
            "prenom" => $row['prenom'],
            "email" => $row['email'],
            "telephone" => $row['tele']
        ];
        
        $agents_arr[] = $agent_item;
    }
    
    // Retourner les données
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "livreurs" => $agents_arr
    ]);
} else {
    // Aucun agent trouvé
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Aucun livreur trouvé"
    ]);
}
?> 