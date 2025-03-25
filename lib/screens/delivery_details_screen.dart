import 'package:flutter/material.dart';
import '../models/bon_livraison.dart';
import '../services/api_service.dart';
import 'package:provider/provider.dart';

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
      String? commentaire;
      
      // Si le statut est non_livre, demander un commentaire
      if (newStatus == 'non_livre' && _commentaireController.text.isNotEmpty) {
        commentaire = _commentaireController.text;
      }
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de la livraison'),
        backgroundColor: Colors.blue,
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations du client',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations de la commande',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          _buildInfoRow('Référence', widget.livraison.reference),
                          _buildInfoRow('Date de commande', widget.livraison.dateCommande),
                          _buildInfoRow('Date de livraison', widget.livraison.dateLivraison),
                          _buildInfoRow('Montant total', '${widget.livraison.montantTotal.toStringAsFixed(2)} DH'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Statut:', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  _getStatusText(_selectedStatus),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: _getStatusColor(_selectedStatus),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Commentaire',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Divider(),
                          TextField(
                            controller: _commentaireController,
                            decoration: const InputDecoration(
                              hintText: 'Ajouter un commentaire',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        _selectedStatus == 'livre' ? 'Déjà livré' : 'Livré',
                        Colors.green,
                        _selectedStatus == 'livre' ? Icons.check_circle : Icons.check_circle_outline,
                        () => _updateStatus('livre'),
                      ),
                      _buildActionButton(
                        _selectedStatus == 'non_livre' ? 'Déjà marqué comme non livré' : 'Non livré',
                        Colors.red,
                        _selectedStatus == 'non_livre' ? Icons.cancel : Icons.cancel_outlined,
                        () => _updateStatus('non_livre'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        disabledBackgroundColor: Colors.grey,
      ),
    );
  }
} 