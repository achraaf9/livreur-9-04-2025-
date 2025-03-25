<?php
// Inclure les en-têtes CORS pour permettre l'accès depuis le navigateur
require_once '../cors_fix.php';

// Retourner une simple réponse pour confirmer que l'API fonctionne
echo json_encode([
    'success' => true,
    'message' => 'API is working!',
    'timestamp' => date('Y-m-d H:i:s'),
    'cors_enabled' => true
]);
?> 