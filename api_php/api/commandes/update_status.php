<?php
// Headers requis
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Inclure les fichiers de configuration et le modèle
include_once '../../config/database.php';
include_once '../../models/Commande.php';

// Vérifier la méthode de requête
if($_SERVER['REQUEST_METHOD'] == 'OPTIONS'){
    http_response_code(200);
    exit;
}

// Vérifier si la méthode est POST
if($_SERVER['REQUEST_METHOD'] !== 'POST'){
    http_response_code(405);
    echo json_encode(["message" => "Méthode non autorisée"]);
    exit;
}

// Se connecter à la base de données
$database = new Database();
$db = $database->getConnection();

// Initialiser le modèle
$commande = new Commande($db);

// Récupérer les données
$data = json_decode(file_get_contents("php://input"));

// Si aucune donnée n'est fournie, essayer de récupérer depuis POST
if(!$data) {
    $data = new stdClass();
    $data->id = isset($_POST['id']) ? intval($_POST['id']) : null;
    $data->statut = isset($_POST['statut']) ? $_POST['statut'] : null;
    $data->commentaire = isset($_POST['commentaire']) ? $_POST['commentaire'] : null;
}

// Vérifier que les données requises sont présentes
if(!isset($data->id) || !isset($data->statut)) {
    http_response_code(400);
    echo json_encode(["success" => false, "message" => "Données incomplètes. ID et statut requis."]);
    exit;
}

// Récupérer les valeurs
$id = $data->id;
$statut = $data->statut;
$commentaire = isset($data->commentaire) ? $data->commentaire : null;

// Ajouter des logs pour déboguer
error_log("Mise à jour du statut - ID: $id, Statut: $statut, Commentaire: " . ($commentaire ?? 'aucun'));

// Mettre à jour le statut
if($commande->updateStatus($id, $statut, $commentaire)) {
    http_response_code(200);
    echo json_encode(["success" => true, "message" => "Statut mis à jour avec succès"]);
} else {
    http_response_code(500);
    echo json_encode(["success" => false, "message" => "Impossible de mettre à jour le statut"]);
}
?> 