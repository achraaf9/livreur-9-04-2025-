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

  @override
  void initState() {
    super.initState();
    _loadLivraisons();
  }

  Future<void> _loadLivraisons() async {
    setState(() {
      _isLoading = true;
    });

    print('Début du chargement des livraisons en attente pour l\'agent ID: ${widget.agent.id}');
    
    try {
      final apiService = await ApiService.getInstance();
      final livraisons = await apiService.getLivraisonsByAgent(widget.agent.id);
      
      print('Livraisons récupérées avec succès: ${livraisons.length}');
      
      if (mounted) {
        setState(() {
          _livraisons = livraisons.where((l) => l.status == 'en_attente' || l.status == 'en_cours').toList();
          _isLoading = false;
          _errorMessage = '';
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des livraisons: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Erreur: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Méthode pour générer des données de test
  void _generateTestData() {
    final random = Random();
    final statuses = ['en_attente', 'en_cours'];
    final villes = ['Casablanca', 'Rabat', 'Marrakech', 'Agadir', 'Tanger', 'Fès'];
    
    // Générer 5 livraisons en attente aléatoires
    _livraisons = List.generate(5, (index) {
      final id = index + 1;
      final status = statuses[random.nextInt(statuses.length)];
      
      final dateCommande = DateTime.now().subtract(Duration(days: random.nextInt(7)));
      final dateLivraison = dateCommande.add(Duration(days: random.nextInt(3) + 1));
      
      return BonLivraison(
        id: id,
        reference: 'BL-${2023}-${1000 + id}',
        clientNom: 'Client ${id}',
        clientAdresse: 'Adresse ${id}, Rue ${random.nextInt(100)}',
        clientTelephone: '06${random.nextInt(90000000) + 10000000}',
        villeClient: villes[random.nextInt(villes.length)],
        status: status,
        commentaire: '',
        dateCommande: '${dateCommande.day}/${dateCommande.month}/${dateCommande.year}',
        dateLivraison: '${dateLivraison.day}/${dateLivraison.month}/${dateLivraison.year}',
        montantTotal: (random.nextDouble() * 1000 + 500).roundToDouble(),
      );
    });
  }

  Future<void> _updateLivraisonStatus(BonLivraison livraison, String status, [String? commentaire]) async {
    if (commentaire == null || commentaire.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter un commentaire avant de changer le statut'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      print('Mise à jour du statut de la livraison ID: ${livraison.id} vers $status');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mise à jour du statut en cours...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      final apiService = await ApiService.getInstance();
      final success = await apiService.updateLivraisonStatus(
        livraison.id,
        status,
        commentaire: commentaire,
      );

      print('Résultat de la mise à jour: $success');
      if (success && mounted) {
        await _loadLivraisons();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'livre' 
                ? 'Livraison confirmée avec succès' 
                : 'Livraison marquée comme non livrée'),
            backgroundColor: status == 'livre' ? Colors.green : Colors.orange,
          ),
        );
      } else if (mounted) {
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour du statut: $e'),
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

  Future<void> _createTestData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Générer des données de test
      _generateTestData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données de test créées avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors de la création des données de test: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
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
              ),
            ),
          );
          
          // Si le résultat est true, cela signifie que le statut a été mis à jour
          if (result == true) {
            _loadLivraisons(); // Recharger les livraisons
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