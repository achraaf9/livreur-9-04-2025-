import 'package:flutter/material.dart';
import '../models/bon_livraison.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import '../utils/permission_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  BonLivraison livraison;
  final Function(String)? onStatusChanged;

  DeliveryDetailsScreen({Key? key, required this.livraison, this.onStatusChanged}) : super(key: key);

  @override
  State<DeliveryDetailsScreen> createState() => _DeliveryDetailsScreenState();
}

class _DeliveryDetailsScreenState extends State<DeliveryDetailsScreen> {
  bool _isLoading = false;
  String _selectedStatus = '';
  final TextEditingController _commentaireController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.livraison.status;
    _commentaireController.text = widget.livraison.commentaire;
  }

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  void _updateStatus(String newStatus) async {
    // Ne rien faire si le statut est déjà le même
    if (_selectedStatus == newStatus) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce statut est déjà sélectionné'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Initialisation du service API
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Mise à jour du statut de la livraison
      String? commentaire = _commentaireController.text.isEmpty ? null : _commentaireController.text;
      
      final success = await apiService.updateLivraisonStatus(
        widget.livraison.id, 
        newStatus,
        commentaire: commentaire,
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (success) {
            // Mettre à jour l'état local
            _selectedStatus = newStatus;
            
            // Au lieu de modifier les propriétés directement, utiliser la méthode copyWith
            final updatedLivraison = widget.livraison.copyWith(
              status: newStatus,
              commentaire: commentaire ?? widget.livraison.commentaire
            );
            
            // Mettre à jour la référence à la livraison
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  // Cette astuce permet de mettre à jour la référence sans erreur de type
                  // car nous ne pouvons pas modifier directement widget.livraison
                  widget.livraison = updatedLivraison;
                });
              }
            });
            
            // Appeler le callback si disponible
            if (widget.onStatusChanged != null) {
              widget.onStatusChanged!(newStatus);
            }
          }
        });
        
        // Afficher un message de confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                ? 'Statut mis à jour avec succès' 
                : 'Erreur lors de la mise à jour du statut'
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        
        // Si la mise à jour est réussie, revenir à l'écran précédent
        if (success) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'en_attente':
        return 'En attente';
      case 'livre':
        return 'Livré';
      case 'non_livre':
        return 'Non livré';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return Colors.orange;
      case 'livre':
        return Colors.green;
      case 'non_livre':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Fonction pour appeler le client
  Future<void> _callClient(String phoneNumber) async {
    // Vérifier et demander la permission si nécessaire
    bool hasPermission = await PermissionUtils.checkAndRequestPhonePermission(context);
    if (!hasPermission) {
      return;
    }
    
    try {
      // Nettoyer le numéro de téléphone (enlever les espaces, tirets, etc.)
      String cleanPhoneNumber = phoneNumber.replaceAll(RegExp(r'\s+|-|\(|\)'), '');
      
      // Vérifier si le numéro commence par 0, le remplacer par le code pays +212 (Maroc)
      if (cleanPhoneNumber.startsWith('0')) {
        cleanPhoneNumber = '+212${cleanPhoneNumber.substring(1)}';
      }
      
      // S'assurer que le numéro commence par +
      if (!cleanPhoneNumber.startsWith('+')) {
        cleanPhoneNumber = '+$cleanPhoneNumber';
      }
      
      debugPrint('Essai d\'appel au numéro: $cleanPhoneNumber');
      
      // Essayer différentes façons de former l'URI en fonction des appareils
      bool launched = false;
      
      // Méthode 1: utiliser scheme tel: avec le numéro formaté
      try {
        final Uri phoneUri = Uri(scheme: 'tel', path: cleanPhoneNumber);
        launched = await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
      } catch (e) {
        debugPrint('Méthode 1 a échoué: $e');
      }
      
      // Méthode 2: utiliser une chaîne URI directe
      if (!launched) {
        try {
          final String uriString = 'tel:$cleanPhoneNumber';
          launched = await launchUrl(Uri.parse(uriString), mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Méthode 2 a échoué: $e');
        }
      }
      
      // Méthode 3: essayer sans le signe +
      if (!launched) {
        try {
          String numberWithoutPlus = cleanPhoneNumber;
          if (numberWithoutPlus.startsWith('+')) {
            numberWithoutPlus = numberWithoutPlus.substring(1);
          }
          final Uri phoneUri = Uri(scheme: 'tel', path: numberWithoutPlus);
          launched = await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Méthode 3 a échoué: $e');
        }
      }
      
      if (!launched) {
        throw Exception('Impossible de lancer l\'application téléphone');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Erreur lors de l\'appel: $e. Essayez de donner à nouveau la permission dans les paramètres de l\'application.'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'PARAMÈTRES',
              textColor: Colors.white,
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la livraison'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Carte d'information du client
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: AppTheme.primaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Informations du client',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkColor,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildInfoRow('Nom', widget.livraison.clientPrenom.isNotEmpty 
                              ? '${widget.livraison.clientPrenom} ${widget.livraison.clientNom}'
                              : widget.livraison.clientNom),
                          _buildInfoRow('Adresse', widget.livraison.clientAdresse),
                          _buildInfoRow('Téléphone', widget.livraison.clientTelephone),
                          _buildInfoRow('Ville', widget.livraison.villeClient),
                          if (widget.livraison.codePostal.isNotEmpty)
                            _buildInfoRow('Code Postal', widget.livraison.codePostal),
                          if (widget.livraison.clientEmail.isNotEmpty)
                            _buildInfoRow('Email', widget.livraison.clientEmail),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Carte d'information de la commande
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.receipt_long,
                                  color: AppTheme.secondaryColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Informations de la commande',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkColor,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildInfoRow('Référence', widget.livraison.reference),
                          _buildInfoRow('Date de commande', widget.livraison.dateCommande),
                          _buildInfoRow('Date de livraison', widget.livraison.dateLivraison),
                          _buildInfoRow('Montant total', '${widget.livraison.montantTotal.toStringAsFixed(2)} DH'),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Statut:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(_selectedStatus).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getStatusColor(_selectedStatus).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _selectedStatus == 'livre' 
                                        ? Icons.check_circle 
                                        : _selectedStatus == 'non_livre' 
                                          ? Icons.cancel 
                                          : Icons.pending,
                                      size: 16,
                                      color: _getStatusColor(_selectedStatus),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _getStatusText(_selectedStatus),
                                      style: TextStyle(
                                        color: _getStatusColor(_selectedStatus),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Champ de commentaire
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.comment,
                                  color: AppTheme.accentColor,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Commentaire',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.darkColor,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          TextField(
                            controller: _commentaireController,
                            decoration: InputDecoration(
                              hintText: 'Ajouter un commentaire',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                              ),
                              filled: true,
                              fillColor: Colors.grey[50],
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Boutons d'action
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedStatus == 'livre' ? null : () => _updateStatus('livre'),
                            icon: Icon(_selectedStatus == 'livre' ? Icons.check_circle : Icons.check_circle_outline),
                            label: Text(_selectedStatus == 'livre' ? 'Déjà livré' : 'Livré'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                              ),
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[600],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _selectedStatus == 'non_livre' ? null : () => _updateStatus('non_livre'),
                            icon: Icon(_selectedStatus == 'non_livre' ? Icons.cancel : Icons.cancel_outlined),
                            label: Text(_selectedStatus == 'non_livre' ? 'Déjà non livré' : 'Non livré'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.errorColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                              ),
                              disabledBackgroundColor: Colors.grey[300],
                              disabledForegroundColor: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    // Vérifier si c'est un numéro de téléphone
    bool isPhoneNumber = label.toLowerCase() == 'téléphone';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: isPhoneNumber
                ? InkWell(
                    onTap: () => _callClient(value),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.successColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.call,
                            size: 16,
                            color: AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : Text(value),
          ),
        ],
      ),
    );
  }
} 