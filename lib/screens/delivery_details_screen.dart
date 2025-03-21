import 'package:flutter/material.dart';
import '../models/bon_livraison.dart';
import '../services/api_service.dart';

class DeliveryDetailsScreen extends StatefulWidget {
  final BonLivraison livraison;
  final Function(String)? onStatusChanged;

  const DeliveryDetailsScreen({Key? key, required this.livraison, this.onStatusChanged}) : super(key: key);

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

  Future<void> _updateLivraisonStatus(String status) async {
    String commentaire = _commentaireController.text.trim();

    if (commentaire.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter un commentaire avant de mettre à jour le statut'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Mise à jour du statut de la livraison ID: ${widget.livraison.id} vers $status');
      
      final apiService = await ApiService.getInstance();
      final success = await apiService.updateLivraisonStatus(
        widget.livraison.id,
        status,
        commentaire: commentaire,
      );

      print('Résultat de la mise à jour: $success');
      
      if (success && mounted) {
        setState(() {
          _selectedStatus = status;
          _isLoading = false;
        });
        
        // Appeler le callback si disponible
        if (widget.onStatusChanged != null) {
          widget.onStatusChanged!(status);
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Statut mis à jour avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la mise à jour du statut'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour du statut: $e'),
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
      case 'en_cours':
        return 'En cours';
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
      case 'en_cours':
        return Colors.blue;
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
                          _buildInfoRow('Nom', widget.livraison.clientNom),
                          _buildInfoRow('Adresse', widget.livraison.clientAdresse),
                          _buildInfoRow('Téléphone', widget.livraison.clientTelephone),
                          _buildInfoRow('Ville', widget.livraison.villeClient),
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
                        'Livré',
                        Colors.green,
                        Icons.check_circle,
                        () => _updateLivraisonStatus('livre'),
                      ),
                      _buildActionButton(
                        'Non livré',
                        Colors.red,
                        Icons.cancel,
                        () => _updateLivraisonStatus('non_livre'),
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
      onPressed: _selectedStatus == 'livre' || _selectedStatus == 'non_livre'
          ? null
          : onPressed,
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