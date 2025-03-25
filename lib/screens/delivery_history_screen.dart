import 'package:flutter/material.dart';
import '../models/agent.dart';
import '../models/bon_livraison.dart';
import '../services/api_service.dart';
import 'delivery_details_screen.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'package:provider/provider.dart';

class DeliveryHistoryScreen extends StatefulWidget {
  final Agent agent;
  final String? initialFilter;

  const DeliveryHistoryScreen({
    super.key, 
    required this.agent,
    this.initialFilter,
  });

  @override
  State<DeliveryHistoryScreen> createState() => _DeliveryHistoryScreenState();
}

class _DeliveryHistoryScreenState extends State<DeliveryHistoryScreen> {
  List<BonLivraison> _livraisons = [];
  bool _isLoading = true;
  String _searchQuery = '';
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'all';
    _loadLivraisons();
  }

  Future<void> _loadLivraisons() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Initialisation du service API
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Récupérer les livraisons depuis l'API
      final livraisons = await apiService.getLivraisonsByAgent(widget.agent.id);
      
      // Filtrer seulement les livraisons complétées (livrées ou non livrées)
      final livraisonsCompleted = livraisons
          .where((l) => l.status == 'livré' || l.status == 'non_livré')
          .toList();
      
      if (mounted) {
        setState(() {
          _livraisons = livraisonsCompleted;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement de l\'historique: $e'),
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
      case 'en_cours':
        return 'En cours';
      case 'non_livre':
        return 'Non livré';
      default:
        return 'Inconnu';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'en_attente':
        return Colors.orange;
      case 'livre':
        return Colors.green;
      case 'en_cours':
        return Colors.amber;
      case 'non_livre':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'en_attente':
        return Icons.pending;
      case 'livre':
        return Icons.check_circle;
      case 'en_cours':
        return Icons.local_shipping;
      case 'non_livre':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  List<BonLivraison> get _filteredLivraisons {
    List<BonLivraison> result = _livraisons;
    
    if (_selectedFilter != 'all') {
      result = result.where((livraison) => livraison.status == _selectedFilter).toList();
    }
    
    if (_searchQuery.isEmpty) return result;
    return result.where((livraison) {
      return livraison.reference.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             livraison.clientNom.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             _getStatusText(livraison.status).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des livraisons'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLivraisons,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Tous', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Livrées', 'livre'),
                  const SizedBox(width: 8),
                  _buildFilterChip('En attente', 'en_attente'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Non livrées', 'non_livre'),
                  const SizedBox(width: 8),
                  _buildFilterChip('En cours', 'en_cours'),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une livraison...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLivraisons.isEmpty
                    ? const Center(
                        child: Text('Aucune livraison trouvée'),
                      )
                    : ListView.builder(
                        itemCount: _filteredLivraisons.length,
                        itemBuilder: (context, index) {
                          final livraison = _filteredLivraisons[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(livraison.status).withOpacity(0.2),
                                child: Icon(
                                  _getStatusIcon(livraison.status),
                                  color: _getStatusColor(livraison.status),
                                ),
                              ),
                              title: Text(
                                livraison.reference,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(livraison.clientNom),
                                  Text(
                                    'Date: ${livraison.dateCommande}',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  if (livraison.commentaire.isNotEmpty)
                                    Text(
                                      'Commentaire: ${livraison.commentaire}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(livraison.status).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getStatusText(livraison.status),
                                  style: TextStyle(
                                    color: _getStatusColor(livraison.status),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              onTap: () {
                                _showDeliveryDetails(livraison);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFilterChip(String label, String value) {
    bool isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      checkmarkColor: Colors.white,
      selectedColor: Colors.blue,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.grey[200],
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
    );
  }

  void _showDeliveryDetails(BonLivraison livraison) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryDetailsScreen(
          livraison: livraison,
          onStatusChanged: (String newStatus) {
            _loadLivraisons(); // Recharger la liste après une mise à jour
          },
        ),
      ),
    );
  }
} 