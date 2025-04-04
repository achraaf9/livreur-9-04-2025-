-- Script de création de la base de données pour l'application de livraison
-- Version complète avec exemples et table d'adresses

-- Commandes pour supprimer les tables existantes
DROP TABLE IF EXISTS `affectations_livreur`;
DROP TABLE IF EXISTS `commandes`;
DROP TABLE IF EXISTS `adresses`;
DROP TABLE IF EXISTS `clients`;
DROP TABLE IF EXISTS `livreurs`;

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données: `app_livreur`
--
CREATE DATABASE IF NOT EXISTS `app_livreur` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `app_livreur`;

-- --------------------------------------------------------

--
-- Structure de la table `livreurs`
--

CREATE TABLE `livreurs` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nom` varchar(255) NOT NULL,
  `prenom` varchar(255) NOT NULL,
  `tele` varchar(255) NOT NULL,
  `email` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `livreurs_email_unique` (`email`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `clients`
--

CREATE TABLE `clients` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `nom` varchar(255) NOT NULL,
  `prenom` varchar(255) NOT NULL,
  `tele` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `adresses`
--

CREATE TABLE `adresses` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `rue` varchar(255) NOT NULL,
  `ville` varchar(255) NOT NULL,
  `code_postal` varchar(10) DEFAULT NULL,
  `quartier` varchar(255) DEFAULT NULL,
  `complement` varchar(255) DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `adresses_client_id_foreign` (`client_id`),
  CONSTRAINT `adresses_client_id_foreign` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `commandes`
--

CREATE TABLE `commandes` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `reference` varchar(255) NOT NULL,
  `client_id` bigint(20) UNSIGNED NOT NULL,
  `adresse_id` bigint(20) UNSIGNED NOT NULL,
  `date_commande` date NOT NULL,
  `date_livraison_prevue` date NOT NULL,
  `montant` decimal(10,2) DEFAULT NULL,
  `statut` enum('En attente','Livrée','Non livrée') NOT NULL DEFAULT 'En attente',
  `commentaire` text DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `commandes_client_id_foreign` (`client_id`),
  KEY `commandes_adresse_id_foreign` (`adresse_id`),
  CONSTRAINT `commandes_client_id_foreign` FOREIGN KEY (`client_id`) REFERENCES `clients` (`id`) ON DELETE CASCADE,
  CONSTRAINT `commandes_adresse_id_foreign` FOREIGN KEY (`adresse_id`) REFERENCES `adresses` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------

--
-- Structure de la table `affectations_livreur`
--

CREATE TABLE `affectations_livreur` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `commande_id` bigint(20) UNSIGNED NOT NULL,
  `livreur_id` bigint(20) UNSIGNED NOT NULL,
  `date_affectation` date NOT NULL,
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `affectations_livreur_commande_id_foreign` (`commande_id`),
  KEY `affectations_livreur_livreur_id_foreign` (`livreur_id`),
  CONSTRAINT `affectations_livreur_commande_id_foreign` FOREIGN KEY (`commande_id`) REFERENCES `commandes` (`id`) ON DELETE CASCADE,
  CONSTRAINT `affectations_livreur_livreur_id_foreign` FOREIGN KEY (`livreur_id`) REFERENCES `livreurs` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- Ajout de données d'exemple complètes
-- --------------------------------------------------------

-- Insertion des livreurs avec emails gmail et mot de passe en clair
INSERT INTO `livreurs` (`nom`, `prenom`, `tele`, `email`, `password`, `created_at`, `updated_at`) VALUES
('Alaoui', 'Youssef', '0601234567', 'youssef.alaoui@gmail.com', 'password123', NOW(), NOW()),
('Benani', 'Achraf', '0602345678', 'achraf.benani@gmail.com', 'password123', NOW(), NOW()),
('Chaoui', 'Fatima', '0603456789', 'fatima.chaoui@gmail.com', 'password123', NOW(), NOW()),
('Doukkali', 'Mohammed', '0604567890', 'mohammed.doukkali@gmail.com', 'password123', NOW(), NOW()),
('El Fassi', 'Amina', '0605678901', 'amina.elfassi@gmail.com', 'password123', NOW(), NOW());

-- Insertion des clients avec des noms arabes
INSERT INTO `clients` (`nom`, `prenom`, `tele`, `created_at`, `updated_at`) VALUES
('Youssef' ,'Benani', '0522225588', NOW(), NOW()),
('Achraf' ,'Mourad', '0522336699', NOW(), NOW()),
('Hamza' ,'El Alami', '0537112233', NOW(), NOW()),
('Karim' ,'Tahiri', '0537445566', NOW(), NOW()),
('Omar' ,'Moutawakil', '0524778899', NOW(), NOW()),
('Nadia' ,'Cherkaoui', '0528223344', NOW(), NOW()),
('Samir' ,'El Gharbi', '0539334455', NOW(), NOW()),
('Laila' ,'Benjelloun', '0535667788', NOW(), NOW()),
('Ali' ,'El Idrissi', '0536778899', NOW(), NOW()),
('Najat' ,'Mansouri', '0538889900', NOW(), NOW());
-- Insetion des adresses - Approche simplifié
-- Client 1: Youssef Benani (ID 1)
INSERT INTO `adresses` (`client_id`, `rue`, `ville`, `code_postal`, `quartier`, `complement`, `created_at`, `updated_at`) VALUES
(1, '123 Avenue Hassan II', 'Casablanca', '20000', 'Maârif', 'Immeuble Telecom, 3ème étage', NOW(), NOW()),
(1, '45 Avenue Mohammed V', 'Casablanca', '20050', 'Centre Ville', 'Agence principale', NOW(), NOW());

-- Client 2: Achraf Mourad (ID 2)
INSERT INTO `adresses` (`client_id`, `rue`, `ville`, `code_postal`, `quartier`, `complement`, `created_at`, `updated_at`) VALUES
(2, '78 Rue Ibn Sina', 'Rabat', '10000', 'Agdal', 'À côté de la banque BMCE', NOW(), NOW());

-- Client 3: Hamza El Alami (ID 3)
INSERT INTO `adresses` (`client_id`, `rue`, `ville`, `code_postal`, `quartier`, `complement`, `created_at`, `updated_at`) VALUES
(3, '15 Boulevard Zerktouni', 'Marrakech', '40000', 'Guéliz', 'En face du jardin public', NOW(), NOW());

-- Client 4: Karim Tahiri (ID 4)
INSERT INTO `adresses` (`client_id`, `rue`, `ville`, `code_postal`, `quartier`, `complement`, `created_at`, `updated_at`) VALUES
(4, '32 Rue Al Madina', 'Tanger', '90000', 'Centre', 'Près de la grande mosquée',NOW(), NOW());

-- Client 5: Omar Moutawakil (ID 5)
INSERT INTO `adresses` (`client_id`, `rue`, `ville`, `code_postal`, `quartier`, `complement`, `created_at`, `updated_at`) VALUES
(5, '88 Avenue Mohammed VI', 'Agadir', '80000', 'Charaf', 'À côté de la station service',  NOW(), NOW());

-- Client 6: Nadia Cherkaoui (ID 6)
INSERT INTO `adresses` (`client_id`, `rue`, `ville`, `code_postal`, `quartier`, `complement`, `created_at`, `updated_at`) VALUES
(6, '5 Boulevard de la Corniche', 'Casablanca', '20180', 'Aïn Diab', 'Face à la mer', NOW(), NOW());

-- Client 7: Samir El Gharbi (ID 7)
INSERT INTO `adresses` (`client_id`, `rue`, `ville`, `code_postal`, `quartier`, `complement`, `created_at`, `updated_at`) VALUES
(7, '17 Rue Allal Ben Abdellah', 'Fès', '30000', 'Ville Nouvelle', 'Près du marché central',  NOW(), NOW());

-- Client 8: Laila Benjelloun (ID 8)
INSERT INTO `adresses` (`client_id`, `rue`, `ville`, `code_postal`, `quartier`, `complement`, `created_at`, `updated_at`) VALUES
(8, '63 Avenue des FAR', 'Meknès', '50000', 'Hamria', 'À côté du cinéma', NOW(), NOW());

-- Client 9: Ali El Idrissi (ID 9)
INSERT INTO `adresses` (`client_id`, `rue`, `ville`, `code_postal`, `quartier`, `complement`, `created_at`, `updated_at`) VALUES
(9, '24 Rue de l\'Atlas', 'Oujda', '60000', 'Al Qods', 'Derrière la mosquée', NOW(), NOW());

-- Client 10: Najat Mansouri (ID 10)
INSERT INTO `adresses` (`client_id`, `rue`, `ville`, `code_postal`, `quartier`, `complement`, `created_at`, `updated_at`) VALUES
(10, '9 Boulevard Hassan II', 'Tétouan', '93000', 'Centre Ville', 'À côté de l\'hôtel Plaza', NOW(), NOW()),
(10, '102 Avenue Mohammed V', 'Tétouan', '93000', 'M\'diq', 'Près du port', NOW(), NOW());

-- Commandes historiques (2023) - Approche simplifiée
INSERT INTO `commandes` (`reference`, `client_id`, `adresse_id`, `date_commande`, `date_livraison_prevue`, `montant`, `statut`, `commentaire`, `created_at`, `updated_at`) VALUES
('CMD-001-2023', 1, 1, '2023-10-15', '2023-10-16', 1250.00, 'Livrée', NULL, NOW(), NOW()),
('CMD-002-2023', 2, 3, '2023-10-15', '2023-10-17', 875.50, 'En attent', NULL, NOW(), NOW()),
('CMD-003-2023', 3, 4, '2023-10-16', '2023-10-18', 3200.75, 'En attent', NULL, NOW(), NOW()),
('CMD-004-2023', 4, 5, '2023-10-18', '2023-10-19', 950.00, 'En attent',NULL , NOW(), NOW()),
('CMD-005-2023', 5, 6, '2023-10-20', '2023-10-22', 1780.25, 'En attent', NULL, NOW(), NOW()),
('CMD-006-2023', 6, 7, '2023-10-21', '2023-10-23', 2340.00, 'En attent', NULL, NOW(), NOW()),
('CMD-007-2023', 7, 8, '2023-10-25', '2023-10-26', 675.50, 'En attent', NULL, NOW(), NOW()),
('CMD-008-2023', 8, 9, '2023-10-27', '2023-10-29', 1450.75, 'En attent', NULL, NOW(), NOW()),
('CMD-009-2023', 9, 10, '2023-10-28', '2023-10-30', 890.00, 'En attent', NULL, NOW(), NOW()),
('CMD-010-2023', 10, 11, '2023-10-29', '2023-10-31', 2760.25, 'En attent', NULL, NOW(), NOW());

-- Commandes en cours (2024) avec statut "En attente" et commentaires vides
INSERT INTO `commandes` (`reference`, `client_id`, `adresse_id`, `date_commande`, `date_livraison_prevue`, `montant`, `statut`, `commentaire`, `created_at`, `updated_at`) VALUES
('CMD-001-2024', 1, 2, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 DAY), 1500.00, 'En attente', NULL, NOW(), NOW()),
('CMD-002-2024', 3, 4, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 2 DAY), 980.50, 'En attente', NULL, NOW(), NOW()),
('CMD-003-2024', 5, 6, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 DAY), 750.25, 'En attente', NULL, NOW(), NOW()),
('CMD-004-2024', 7, 8, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 3 DAY), 1650.75, 'En attente', NULL, NOW(), NOW()),
('CMD-005-2024', 9, 10, CURDATE(), DATE_ADD(CURDATE(), INTERVAL 1 DAY), 2200.00, 'En attente', NULL, NOW(), NOW());

-- Affectation des commandes historiques (2023) aux livreurs
INSERT INTO `affectations_livreur` (`commande_id`, `livreur_id`, `date_affectation`, `created_at`, `updated_at`) VALUES
(1, 1, '2023-10-15', '2023-10-15 08:00:00', '2023-10-15 08:00:00'),
(2, 1, '2023-10-15', '2023-10-15 08:00:00', '2023-10-15 08:00:00'),
(3, 2, '2023-10-16', '2023-10-16 08:00:00', '2023-10-16 08:00:00'),
(4, 2, '2023-10-18', '2023-10-18 08:00:00', '2023-10-18 08:00:00'),
(5, 3, '2023-10-20', '2023-10-20 08:00:00', '2023-10-20 08:00:00'),
(6, 3, '2023-10-21', '2023-10-21 08:00:00', '2023-10-21 08:00:00'),
(7, 4, '2023-10-25', '2023-10-25 08:00:00', '2023-10-25 08:00:00'),
(8, 4, '2023-10-27', '2023-10-27 08:00:00', '2023-10-27 08:00:00'),
(9, 5, '2023-10-28', '2023-10-28 08:00:00', '2023-10-28 08:00:00'),
(10, 5, '2023-10-29', '2023-10-29 08:00:00', '2023-10-29 08:00:00');

-- Affectation des commandes actuelles (2024) aux livreurs
INSERT INTO `affectations_livreur` (`commande_id`, `livreur_id`, `date_affectation`, `created_at`, `updated_at`) VALUES
(11, 1, CURDATE(), NOW(), NOW()),
(12, 2, CURDATE(), NOW(), NOW()),
(13, 3, CURDATE(), NOW(), NOW()),
(14, 4, CURDATE(), NOW(), NOW()),
(15, 5, CURDATE(), NOW(), NOW());

COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;