<?php
// Autoriser les requêtes cross-origin depuis n'importe quelle origine
header("Access-Control-Allow-Origin: *");
header("Content-Type: application/json; charset=UTF-8");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS, DELETE, PUT");
header("Access-Control-Max-Age: 3600");
header("Access-Control-Allow-Headers: Content-Type, Access-Control-Allow-Headers, Authorization, X-Requested-With");

// Définir le fuseau horaire
date_default_timezone_set("Africa/Casablanca");

// En cas de requête OPTIONS (pre-flight), renvoyer un 200 OK
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
} 