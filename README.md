# Application de Livraison

Application mobile pour les livreurs permettant de gérer les livraisons.

## Fonctionnalités

- Authentification des livreurs
- Liste des livraisons à effectuer
- Mise à jour du statut des livraisons (livré/non livré)
- Ajout de commentaires pour chaque livraison

## Installation

1. Assurez-vous d'avoir Flutter installé (version 3.0.0 ou supérieure)
2. Clonez ce dépôt
3. Exécutez `flutter pub get` pour installer les dépendances
4. Configurez l'API dans le fichier `lib/config/api_config.dart`
5. Exécutez `flutter run` pour lancer l'application

## Configuration de l'API

L'application utilise une API REST pour communiquer avec le serveur. Vous devez configurer l'URL de l'API dans le fichier `lib/config/api_config.dart` :

```dart
class ApiConfig {
  static const String baseUrl = 'http://votre-serveur.com/api';
}
```

## Déploiement de l'API

Voir le fichier `api/README.md` pour les instructions de déploiement de l'API.

## Structure du projet

- `lib/config/` : Fichiers de configuration
- `lib/models/` : Modèles de données
- `lib/screens/` : Écrans de l'application
- `lib/services/` : Services pour la communication avec l'API
- `api/` : Code source de l'API REST

## Utilisation

1. Connectez-vous avec les identifiants fournis (par défaut : karim.alami@example.com / password123)
2. Consultez la liste des livraisons à effectuer
3. Pour chaque livraison, vous pouvez :
   - Voir les détails de la livraison
   - Marquer la livraison comme "livrée" ou "non livrée"
   - Ajouter un commentaire

## Captures d'écran

(Ajoutez des captures d'écran ici)

## Développement

Pour contribuer au développement de l'application :

1. Créez une branche pour votre fonctionnalité
2. Développez et testez votre fonctionnalité
3. Soumettez une pull request

## Licence

(Ajoutez votre licence ici)
