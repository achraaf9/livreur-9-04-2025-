<?php
// Script pour corriger les problèmes de CORS
// Inclure ce fichier au début de chaque fichier API PHP

// Permettre les requêtes depuis n'importe quelle origine (utile pour le développement)
header("Access-Control-Allow-Origin: *");

// Spécifier les méthodes HTTP autorisées
header("Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS");

// Autoriser certains en-têtes dans la requête
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Autoriser les cookies dans les requêtes cross-origin
header("Access-Control-Allow-Credentials: true");

// Définir le type de contenu par défaut comme JSON
header("Content-Type: application/json; charset=UTF-8");

// Répondre automatiquement aux requêtes OPTIONS préliminaires
// Les navigateurs envoient souvent une requête OPTIONS avant POST/PUT pour vérifier les permissions
if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    // Juste besoin de renvoyer les en-têtes et quitter pour les requêtes OPTIONS
    http_response_code(200);
    exit;
}

// Logger la requête pour le débogage
if (isset($_SERVER['REQUEST_URI'])) {
    error_log("Requête reçue: " . $_SERVER['REQUEST_METHOD'] . " " . $_SERVER['REQUEST_URI']);
}

// Vérifier BOM et caractères non-UTF8 pour éviter des problèmes JSON
if (isset($GLOBALS['HTTP_RAW_POST_DATA']) || isset($_POST)) {
    $raw_data = $GLOBALS['HTTP_RAW_POST_DATA'] ?? file_get_contents('php://input');
    if ($raw_data && strlen($raw_data) > 0) {
        // Vérifier si commence avec BOM
        if (substr($raw_data, 0, 3) === "\xEF\xBB\xBF") {
            // Supprimer BOM
            $raw_data = substr($raw_data, 3);
            // Stocker la version nettoyée
            $GLOBALS['HTTP_RAW_POST_DATA'] = $raw_data;
        }
    }
}

// Afficher un message de confirmation que le fichier est bien inclus
if (isset($_GET['test'])) {
    echo json_encode([
        'success' => true,
        'message' => 'CORS headers are enabled on this endpoint',
        'headers' => [
            'Access-Control-Allow-Origin' => '*',
            'Access-Control-Allow-Methods' => 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers' => 'Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With',
            'Access-Control-Allow-Credentials' => 'true',
            'Content-Type' => 'application/json; charset=UTF-8'
        ]
    ]);
    exit;
}
?> 