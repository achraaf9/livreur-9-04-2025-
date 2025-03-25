<?php
// Activer l'affichage des erreurs pour le débogage
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

// Logger les erreurs au lieu de les afficher
error_log("Début d'exécution de get_by_livreur.php");

// Inclure les en-têtes CORS pour permettre l'accès depuis n'importe quelle origine
require_once '../../cors_fix.php';

// Définir l'en-tête de réponse comme JSON
header('Content-Type: application/json; charset=UTF-8');

// Inclure les fichiers de configuration et le modèle
try {
    require_once '../../config/database.php';
    require_once '../../models/Commande.php';
    
    // Récupérer l'ID du livreur depuis les paramètres
    $livreur_id = isset($_GET['id']) ? $_GET['id'] : 
                (isset($_GET['livreur_id']) ? $_GET['livreur_id'] : null);
    
    error_log("Requête pour le livreur ID: " . $livreur_id);
    
    // Alternative pour JSON
    $data = json_decode(file_get_contents("php://input"));
    if(!$livreur_id && isset($data->id)) {
        $livreur_id = $data->id;
        error_log("ID récupéré du corps de la requête: " . $livreur_id);
    } elseif(!$livreur_id && isset($data->livreur_id)) {
        $livreur_id = $data->livreur_id;
        error_log("livreur_id récupéré du corps de la requête: " . $livreur_id);
    }
    
    // Si l'ID n'est pas fourni
    if(!$livreur_id){
        http_response_code(400);
        echo json_encode([
            "success" => false,
            "message" => "ID du livreur manquant"
        ]);
        error_log("Erreur: ID du livreur manquant");
        exit;
    }
    
    // Se connecter à la base de données
    $database = new Database();
    $db = $database->getConnection();
    error_log("Connexion à la base de données établie");
    
    // Initialiser le modèle
    $commande = new Commande($db);
    
    // Récupérer les commandes du livreur
    error_log("Tentative de récupération des commandes pour le livreur ID: " . $livreur_id);
    $stmt = $commande->getCommandesByLivreur($livreur_id);
    
    // Vérifier si des résultats sont trouvés
    $count = $stmt->rowCount();
    error_log("Nombre de commandes trouvées: " . $count);
    
    if($count > 0){
        // Tableau de commandes
        $commandes_arr = [];
        $debug_ids = [];
        
        // Récupération des données
        $row_counter = 0;
        while($row = $stmt->fetch(PDO::FETCH_ASSOC)){
            $row_counter++;
            error_log("Traitement de la ligne " . $row_counter . " avec ID: " . ($row['id'] ?? 'inconnu'));
            
            // Ajouter l'ID à la liste de débogage
            if (isset($row['id'])) {
                $debug_ids[] = $row['id'];
            }
            
            // Sanitiser les données pour éviter les problèmes de formatage JSON
            $nom_client = isset($row['nom_client']) ? htmlspecialchars($row['nom_client']) : '';
            $prenom_client = isset($row['prenom_client']) ? htmlspecialchars($row['prenom_client']) : '';
            $email_client = isset($row['email_client']) ? htmlspecialchars($row['email_client']) : '';
            $rue = isset($row['rue']) ? htmlspecialchars($row['rue']) : '';
            $tele = isset($row['tele']) ? htmlspecialchars($row['tele']) : '';
            $ville = isset($row['ville']) ? htmlspecialchars($row['ville']) : '';
            $code_postal = isset($row['code_postal']) ? htmlspecialchars($row['code_postal']) : '';
            $commentaire = isset($row['commentaire']) ? htmlspecialchars($row['commentaire']) : '';
            
            // Déterminer le statut
            $status = 'en_attente'; // Valeur par défaut
            if (isset($row['statut'])) {
                if ($row['statut'] == 'En attente') {
                    $status = 'en_attente';
                } elseif ($row['statut'] == 'Livrée') {
                    $status = 'livre';
                } elseif ($row['statut'] == 'Non livrée') {
                    $status = 'non_livre';
                }
            }
            
            // Construire le nom complet si le prénom est disponible
            $nom_complet = $nom_client;
            if (!empty($prenom_client)) {
                $nom_complet = $prenom_client . ' ' . $nom_client;
            }
            
            // Convertir les champs pour la compatibilité Flutter
            $commande_item = [
                "id" => (int)$row['id'],
                "reference" => $row['reference'] ?? 'Référence inconnue',
                "clientNom" => $nom_complet,
                "clientPrenom" => $prenom_client,
                "clientEmail" => $email_client,
                "clientAdresse" => $rue,
                "clientTelephone" => $tele,
                "villeClient" => $ville,
                "codePostal" => $code_postal,
                "status" => $status,
                "commentaire" => $commentaire,
                "dateCommande" => $row['date_commande'] ?? '',
                "dateLivraison" => $row['date_livraison_prevue'] ?? '',
                "montantTotal" => (float)($row['montant'] ?? 0)
            ];
            
            error_log("Commande ajoutée à la liste: ID " . $row['id'] . ", Client: " . $nom_complet);
            $commandes_arr[] = $commande_item;
        }
        
        // Retourner les données
        $response = [
            "success" => true,
            "commandes" => $commandes_arr,
            "debug" => [
                "count" => $count,
                "processed" => $row_counter,
                "ids" => $debug_ids
            ]
        ];
        
        // Vérifier que l'encodage se passe bien
        $json_result = json_encode($response, JSON_UNESCAPED_UNICODE | JSON_PARTIAL_OUTPUT_ON_ERROR);
        if ($json_result === false) {
            error_log("Erreur d'encodage JSON: " . json_last_error_msg());
            // En cas d'erreur, essayer d'encoder sans les caractères spéciaux
            $json_result = json_encode($response, JSON_PARTIAL_OUTPUT_ON_ERROR);
        }
        
        http_response_code(200);
        echo $json_result;
        error_log("Réponse envoyée avec succès: " . count($commandes_arr) . " commandes");
    } else {
        // Aucune commande trouvée
        http_response_code(404);
        echo json_encode([
            "success" => false,
            "message" => "Aucune commande trouvée pour ce livreur"
        ]);
        error_log("Aucune commande trouvée pour le livreur ID: " . $livreur_id);
    }
} catch (Exception $e) {
    // En cas d'erreur, retourner un message d'erreur
    http_response_code(500);
    echo json_encode([
        "success" => false,
        "message" => "Erreur serveur: " . $e->getMessage()
    ]);
    error_log("Exception dans get_by_livreur.php: " . $e->getMessage());
}
?> 