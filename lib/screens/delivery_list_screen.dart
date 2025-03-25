import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/agent.dart';
import '../models/bon_livraison.dart';
import '../services/api_service.dart';
import 'delivery_details_screen.dart';
import 'dart:math';

class DeliveryListScreen extends StatefulWidget {
  final Agent agent;

  const DeliveryListScreen({super.key, required this.agent});

  @override
  State<DeliveryListScreen> createState() => _DeliveryListScreenState();
}

class _DeliveryListScreenState extends State<DeliveryListScreen> {
  List<BonLivraison> _livraisons = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isUpdating = false;
  // Variable pour stocker les informations de débogage (gardée pour référence mais non affichée)
  Map<String, dynamic> _debugInfo = {};

  @override
  void initState() {
    super.initState();
    _loadLivraisons();
  }

  Future<void> _loadLivraisons() async {
    setState(() {
      _isLoading = true;
      _debugInfo = {}; // Réinitialiser les infos de débogage
    });
    
    try {
      // Initialisation du service API
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Récupérer les livraisons depuis l'API
      final livraisons = await apiService.getLivraisonsByAgent(widget.agent.id);
      
      // Afficher le nombre de livraisons récupérées
      debugPrint('🚚 Nombre de livraisons récupérées: ${livraisons.length}');
      
      // Stocker les IDs des livraisons pour le débogage
      List<int> livraisonsIds = livraisons.map((l) => l.id).toList();
      debugPrint('🚚 IDs des livraisons: $livraisonsIds');
      
      // Stocker ces informations pour l'affichage de débogage
      _debugInfo = {
        'totalRecupere': livraisons.length,
        'ids': livraisonsIds,
      };
      
      if (mounted) {
        setState(() {
          // Ne garder que les livraisons en attente ou en cours
          _livraisons = livraisons.where((livraison) => 
            livraison.status == 'en_attente' || 
            livraison.status == 'en_cours').toList();
          
          // Ajouter le nombre de livraisons filtrées aux infos de débogage
          _debugInfo['totalEnAttente'] = _livraisons.length;
          
          _isLoading = false;
          _errorMessage = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur lors du chargement des livraisons: $e';
          _debugInfo['error'] = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshLivraisons() async {
    // Initialisation du service API
    final apiService = Provider.of<ApiService>(context, listen: false);
    
    try {
      final livraisons = await apiService.getLivraisonsByAgent(widget.agent.id);
      
      if (mounted) {
        setState(() {
          // Ne garder que les livraisons en attente ou en cours
          _livraisons = livraisons.where((livraison) => 
            livraison.status == 'en_attente' || 
            livraison.status == 'en_cours').toList();
          _errorMessage = '';
        });
      }
      
      return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur lors de l\'actualisation: $e';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      throw e; // Pour indiquer à RefreshIndicator que le rafraîchissement a échoué
    }
  }

  Future<void> _updateLivraisonStatus(BonLivraison livraison, String status, [String? commentaire]) async {
    setState(() {
      _isUpdating = true;
    });
    
    try {
      // Initialisation du service API
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Mise à jour du statut
      final success = await apiService.updateLivraisonStatus(
        livraison.id,
        status,
        commentaire: commentaire,
      );
      
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        
        if (success) {
          // Mettre à jour l'état local
          setState(() {
            livraison.status = status;
            if (commentaire != null) {
              livraison.commentaire = commentaire;
            }
            
            // Retirer la livraison de la liste si son statut n'est plus en attente ou en cours
            if (status != 'en_attente' && status != 'en_cours') {
              _livraisons.removeWhere((l) => l.id == livraison.id);
            }
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Statut mis à jour avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Échec de la mise à jour du statut'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showConfirmationDialog(BonLivraison livraison) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${livraison.clientNom}'),
            Text('Produit: ${livraison.reference}'),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Commentaire (obligatoire)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez ajouter un commentaire avant de confirmer'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _updateLivraisonStatus(livraison, 'livre', commentController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    );
  }

  void _showNonLivreDialog(BonLivraison livraison) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Commentaire pour la livraison'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Client: ${livraison.clientNom}'),
            Text('Produit: ${livraison.reference}'),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Commentaire (obligatoire)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              if (commentController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez ajouter un commentaire avant de confirmer'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              Navigator.pop(context);
              _updateLivraisonStatus(livraison, 'non_livre', commentController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('CONFIRMER'),
          ),
        ],
      ),
    );
  }

  void _navigateToDeliveryDetails(BonLivraison livraison) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryDetailsScreen(
          livraison: livraison,
        ),
      ),
    ).then((_) {
      // Rafraîchir la liste des livraisons après retour de la page détails
      _loadLivraisons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Livraisons en attente'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLivraisons,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage, textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLivraisons,
                        child: const Text('Réessayer'),
                      ),
                    ],
                  ),
                )
              : _livraisons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Aucune livraison en attente trouvée'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadLivraisons,
                            child: const Text('Actualiser'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLivraisons,
                      child: ListView.builder(
                        itemCount: _livraisons.length,
                        itemBuilder: (context, index) {
                          final livraison = _livraisons[index];
                          return _buildDeliveryCard(context, livraison);
                        },
                      ),
                    ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, BonLivraison livraison) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () async {
          // Naviguer vers l'écran de détails et attendre le résultat
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryDetailsScreen(
                livraison: livraison,
                onStatusChanged: (newStatus) {
                  // Cette fonction est appelée si le statut est changé depuis l'écran de détails
                  setState(() {
                    // Mettre à jour le statut localement
                    livraison.status = newStatus;
                    
                    // Retirer la livraison de la liste si son statut n'est plus en attente ou en cours
                    if (newStatus != 'en_attente' && newStatus != 'en_cours') {
                      _livraisons.removeWhere((l) => l.id == livraison.id);
                    }
                  });
                },
              ),
            ),
          );
          
          // Si le résultat est true, cela signifie que le statut a été mis à jour
          if (result == true) {
            // Vérifier si la livraison doit être retirée de la liste
            if (livraison.status != 'en_attente' && livraison.status != 'en_cours') {
              setState(() {
                _livraisons.removeWhere((l) => l.id == livraison.id);
              });
            }
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(livraison.status),
                  child: Icon(_getStatusIcon(livraison.status), color: Colors.white),
                ),
                title: Text(livraison.clientNom),
                subtitle: Text('Réf: ${livraison.reference}'),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Adresse: ${livraison.clientAdresse}, ${livraison.villeClient}')),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('Date commande: ${livraison.dateCommande.isNotEmpty ? livraison.dateCommande : "Non spécifiée"}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.event, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('Date livraison: ${livraison.dateLivraison.isNotEmpty ? livraison.dateLivraison : "Non spécifiée"}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('Montant: ${livraison.montantTotal.toStringAsFixed(2)} DH'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text('Statut: ${_getStatusText(livraison.status)}'),
                      ],
                    ),
                  ],
                ),
              ),
              ButtonBar(
                alignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      _navigateToDeliveryDetails(livraison);
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('DÉTAILS'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue,
                    ),
                  ),
                  if (livraison.status == 'en_attente' || livraison.status == 'en_cours')
                    ElevatedButton.icon(
                      onPressed: () => _showConfirmationDialog(livraison),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('LIVRÉ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (livraison.status == 'en_attente' || livraison.status == 'en_cours')
                    TextButton.icon(
                      onPressed: () => _showNonLivreDialog(livraison),
                      icon: const Icon(Icons.cancel),
                      label: const Text('NON LIVRÉ'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'livre':
        return Colors.green;
      case 'non_livre':
        return Colors.orange;
      case 'en_cours':
        return Colors.amber;
      case 'en_attente':
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'livre':
        return Icons.check_circle;
      case 'non_livre':
        return Icons.cancel;
      case 'en_cours':
        return Icons.local_shipping;
      case 'en_attente':
      default:
        return Icons.pending;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'livre':
        return 'Livré';
      case 'non_livre':
        return 'Non livré';
      case 'en_cours':
        return 'En cours de livraison';
      case 'en_attente':
        return 'En attente';
      default:
        return status;
    }
  }
} 