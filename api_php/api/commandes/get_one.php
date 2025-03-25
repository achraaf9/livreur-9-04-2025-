<?php
// Headers requis
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: GET");
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

// Se connecter à la base de données
$database = new Database();
$db = $database->getConnection();

// Initialiser le modèle
$commande = new Commande($db);

// Récupérer l'ID de la commande
$id = isset($_GET['id']) ? $_GET['id'] : null;

// Alternative pour JSON
$data = json_decode(file_get_contents("php://input"));
if(!$id && isset($data->id)) {
    $id = $data->id;
}

// Si l'ID n'est pas fourni
if(!$id){
    http_response_code(400);
    echo json_encode(["message" => "ID de la commande manquant"]);
    exit;
}

// Définir l'ID pour récupérer la commande
$commande->id = $id;

// Récupérer les détails de la commande
$stmt = $commande->readOne();

if($stmt->rowCount() > 0){
    // Récupérer les données de la commande
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    
    // Sanitiser les données pour éviter les problèmes de formatage JSON
    $nom_client = isset($row['nom_client']) ? htmlspecialchars($row['nom_client']) : '';
    $prenom_client = isset($row['prenom_client']) ? htmlspecialchars($row['prenom_client']) : '';
    $email_client = isset($row['email_client']) ? htmlspecialchars($row['email_client']) : '';
    
    // Construire le nom complet si le prénom est disponible
    $nom_complet = $nom_client;
    if (!empty($prenom_client)) {
        $nom_complet = $prenom_client . ' ' . $nom_client;
    }
    
    // Créer un tableau pour la réponse
    $commande_arr = [
        "id" => (int)$row['id'],
        "reference" => $row['reference'],
        "client" => [
            "id" => (int)$row['client_id'],
            "nom" => $nom_complet,
            "prenom" => $prenom_client,
            "email" => $email_client,
            "telephone" => $row['tele']
        ],
        "adresse" => [
            "id" => (int)$row['adresse_id'],
            "rue" => $row['rue'],
            "complement" => $row['complement'] ?? '',
            "ville" => $row['ville'],
            "code_postal" => $row['code_postal'] ?? '',
            "quartier" => $row['quartier'] ?? ''
        ],
        "dateCommande" => $row['date_commande'],
        "dateLivraison" => $row['date_livraison_prevue'],
        "montant" => (float)$row['montant'],
        "statut" => $row['statut'],
        "commentaire" => $row['commentaire'] ?? ''
    ];

    // Réponse avec succès
    http_response_code(200);
    echo json_encode([
        "success" => true,
        "commande" => $commande_arr
    ]);
} else {
    // Commande non trouvée
    http_response_code(404);
    echo json_encode([
        "success" => false,
        "message" => "Commande non trouvée"
    ]);
}
?>