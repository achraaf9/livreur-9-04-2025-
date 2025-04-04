import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_theme.dart';

class PermissionUtils {
  /// Vérifie et demande la permission téléphone
  static Future<bool> checkAndRequestPhonePermission(BuildContext context) async {
    // Vérifier si la permission est déjà accordée
    PermissionStatus status = await Permission.phone.status;
    
    if (status.isGranted) {
      return true;
    }
    
    // Si la permission a été définitivement refusée, afficher un message
    if (status.isPermanentlyDenied) {
      await _showPermissionExplanationDialog(
        context: context,
        title: 'Permission requise',
        message: 'Pour vous permettre de contacter rapidement vos clients lors des livraisons, notre application a besoin d\'accéder à la fonction téléphone de votre appareil. Veuillez autoriser cette permission dans les paramètres de votre téléphone pour profiter pleinement de toutes les fonctionnalités de l\'application.',
        openSettings: true,
      );
      return false;
    }
    
    // Demander la permission
    status = await Permission.phone.request();
    
    // Si la permission est toujours refusée après demande, afficher un message explicatif
    if (!status.isGranted) {
      await _showPermissionExplanationDialog(
        context: context,
        title: 'Permission refusée',
        message: 'Pour vous permettre de contacter rapidement vos clients lors des livraisons, notre application a besoin d\'accéder à la fonction téléphone de votre appareil. Sans cette permission, vous ne pourrez pas appeler les clients directement depuis l\'application.',
        openSettings: status.isPermanentlyDenied,
      );
      return false;
    }
    
    return true;
  }

  /// Vérifie et demande toutes les permissions nécessaires à l'application
  static Future<void> checkAllPermissions(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final bool alreadyShown = prefs.getBool('permissions_info_shown') ?? false;
    
    if (!alreadyShown) {
      await showPermissionsInfoDialog(context);
      await prefs.setBool('permissions_info_shown', true);
    }
  }
  
  /// Affiche un dialogue d'information sur les permissions nécessaires
  static Future<void> showPermissionsInfoDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppTheme.primaryColor,
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Permissions requises',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pour vous permettre de profiter pleinement de toutes les fonctionnalités de l\'application, veuillez accorder les permissions suivantes lorsqu\'elles vous seront demandées :',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildPermissionItem(
                context,
                Icons.call,
                'Téléphone',
                'Pour appeler vos clients directement depuis l\'application'
              ),
              _buildPermissionItem(
                context,
                Icons.location_on,
                'Localisation',
                'Pour vous aider à naviguer vers les adresses de livraison'
              ),
              _buildPermissionItem(
                context,
                Icons.notifications,
                'Notifications',
                'Pour vous alerter des nouvelles livraisons'
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Compris', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construit un élément de permission dans la liste
  static Widget _buildPermissionItem(
    BuildContext context, 
    IconData icon, 
    String title, 
    String description
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.darkColor,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Affiche un dialogue expliquant pourquoi la permission est nécessaire
  static Future<void> _showPermissionExplanationDialog({
    required BuildContext context,
    required String title,
    required String message,
    bool openSettings = false,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          if (openSettings)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Ouvrir les paramètres'),
            ),
        ],
      ),
    );
  }

  /// Vérifier et afficher le statut de la permission téléphone
  static Future<void> checkPhonePermissionStatus(BuildContext context) async {
    final PermissionStatus status = await Permission.phone.status;
    
    String statusMessage;
    Color statusColor;
    
    switch (status) {
      case PermissionStatus.granted:
        statusMessage = 'La permission téléphone est accordée.';
        statusColor = Colors.green;
        break;
      case PermissionStatus.denied:
        statusMessage = 'La permission téléphone est refusée. Veuillez l\'accorder.';
        statusColor = Colors.orange;
        break;
      case PermissionStatus.permanentlyDenied:
        statusMessage = 'La permission téléphone est définitivement refusée. Veuillez l\'activer dans les paramètres.';
        statusColor = Colors.red;
        break;
      case PermissionStatus.restricted:
        statusMessage = 'La permission téléphone est restreinte.';
        statusColor = Colors.red;
        break;
      case PermissionStatus.limited:
        statusMessage = 'La permission téléphone est limitée.';
        statusColor = Colors.orange;
        break;
      default:
        statusMessage = 'Statut de permission inconnu.';
        statusColor = Colors.grey;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              status.isGranted ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(statusMessage)),
          ],
        ),
        backgroundColor: statusColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        action: status.isPermanentlyDenied ? SnackBarAction(
          label: 'PARAMÈTRES',
          textColor: Colors.white,
          onPressed: openAppSettings,
        ) : null,
      ),
    );
  }
} 