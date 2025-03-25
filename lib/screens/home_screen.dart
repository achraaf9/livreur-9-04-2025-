import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/agent.dart';
import '../models/bon_livraison.dart';
import 'delivery_list_screen.dart';
import 'statistics_screen.dart';
import 'delivery_details_screen.dart';
import 'package:intl/intl.dart';
import 'delivery_history_screen.dart';
import 'dart:math';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final Agent agent;

  const HomeScreen({super.key, required this.agent});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BonLivraison> _livraisons = [];
  bool _isLoading = true;
  int _livraisonsEnAttente = 0;
  int _livraisonsLivrees = 0;
  int _livraisonsNonLivrees = 0;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchLivraisons();
  }

  Future<void> _fetchLivraisons() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Initialisation du service API
      final apiService = Provider.of<ApiService>(context, listen: false);
      
      // Récupération de toutes les livraisons de l'agent pour calculer les statistiques
      final allLivraisons = await apiService.getLivraisonsByAgent(widget.agent.id);
      
      // Récupération uniquement des livraisons en attente ou en cours pour l'affichage
      final enAttenteLivraisons = await apiService.getLivraisonsEnAttente(widget.agent.id);
      
      if (mounted) {
        setState(() {
          _livraisons = enAttenteLivraisons;
          
          // Mise à jour des compteurs basée sur toutes les livraisons
          _livraisonsEnAttente = allLivraisons.where((l) => 
              l.status == 'en_attente').length;
          _livraisonsLivrees = allLivraisons.where((l) => 
              l.status == 'livre').length;
          _livraisonsNonLivrees = allLivraisons.where((l) => 
              l.status == 'non_livre').length;
          
          _isLoading = false;
        });
        
        // Afficher un message si des livraisons ont été chargées
        if (allLivraisons.isNotEmpty && _livraisonsEnAttente > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vous avez $_livraisonsEnAttente livraisons en attente'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur: ${e.toString()}';
          _isLoading = false;
          // Réinitialiser les compteurs en cas d'erreur
          _livraisonsEnAttente = 0;
          _livraisonsLivrees = 0;
          _livraisonsNonLivrees = 0;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des livraisons: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _updateLivraisonStatus(BonLivraison livraison, String status, [String? commentaire]) async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final success = await apiService.updateLivraisonStatus(
        livraison.id,
        status,
        commentaire: commentaire
      );

      if (success && mounted) {
        // Mettre à jour la liste locale avec le nouveau statut
        final updatedLivraison = BonLivraison(
          id: livraison.id,
          reference: livraison.reference,
          clientNom: livraison.clientNom,
          clientPrenom: livraison.clientPrenom,
          clientEmail: livraison.clientEmail,
          clientAdresse: livraison.clientAdresse,
          clientTelephone: livraison.clientTelephone,
          villeClient: livraison.villeClient,
          codePostal: livraison.codePostal,
          status: status,
          commentaire: commentaire ?? livraison.commentaire,
          dateCommande: livraison.dateCommande,
          dateLivraison: livraison.dateLivraison,
          montantTotal: livraison.montantTotal,
        );
        
        // Mettre à jour la livraison dans la liste locale
        setState(() {
          _livraisons = _livraisons.map((l) => l.id == livraison.id ? updatedLivraison : l).toList();
          
          // Mettre à jour les compteurs
          _livraisonsEnAttente = _livraisons.where((l) => l.status == 'en_attente').length;
          _livraisonsLivrees = _livraisons.where((l) => l.status == 'livre').length;
          _livraisonsNonLivrees = _livraisons.where((l) => l.status == 'non_livre').length;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'livre' 
                ? 'Livraison confirmée avec succès' 
                : 'Livraison non livrée enregistrée'),
            backgroundColor: status == 'livre' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
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

  void _openDrawer() {
    Scaffold.of(context).openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord'),
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchLivraisons,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text('${widget.agent.prenom} ${widget.agent.nom}'),
              accountEmail: Text(widget.agent.email),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  '${widget.agent.prenom[0]}${widget.agent.nom[0]}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Tableau de bord'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping),
              title: const Text('Livraisons en attente'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryListScreen(agent: widget.agent),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historique des livraisons'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveryHistoryScreen(agent: widget.agent),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart),
              title: const Text('Statistiques'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StatisticsScreen(agent: widget.agent),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: () async {
                // Déconnexion directe
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchLivraisons,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height - AppBar().preferredSize.height,
                  ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Message de bienvenue
                    Card(
                        elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Bonjour ${widget.agent.prenom} ${widget.agent.nom}',
                          style: const TextStyle(
                              fontSize: 20,
                            fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    
                    // Notification des livraisons en attente
                    Card(
                        elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Vous avez $_livraisonsEnAttente livraisons en attente aujourd\'hui',
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    
                    // Aperçu des livraisons
                    const Text(
                      'Aperçu des livraisons',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                      const SizedBox(height: 16),
                    
                      // Cartes de statistiques
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'En attente',
                            _livraisonsEnAttente.toString(),
                              Icons.pending_actions,
                              Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Livrées',
                            _livraisonsLivrees.toString(),
                              Icons.check_circle,
                            Colors.green,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildStatCard(
                            'Non livrées',
                            _livraisonsNonLivrees.toString(),
                              Icons.cancel,
                            Colors.red,
                          ),
                        ),
                      ],
                    ),
                      const SizedBox(height: 24),
                    
                    // Livraisons récentes
                        const Text(
                          'Livraisons récentes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                    _livraisons.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text('Aucune livraison récente'),
                            ),
                          )
                        : Column(
                            children: _livraisons
                                  .take(3)
                                  .map((livraison) => _buildLivraisonCard(livraison))
                                .toList(),
                          ),
                      
                    const SizedBox(height: 24),
                    
                    // Boutons d'action
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                              icon: const Icon(Icons.list),
                              label: const Text('VOIR TOUTES LES LIVRAISONS'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeliveryListScreen(agent: widget.agent),
                                ),
                              );
                            },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.bar_chart),
                              label: const Text('STATISTIQUES'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                              ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StatisticsScreen(agent: widget.agent),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(widget.agent.nomComplet),
            accountEmail: Text(widget.agent.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                widget.agent.initiales,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Tableau de bord'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_shipping),
            title: const Text('Livraisons en attente'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeliveryListScreen(agent: widget.agent),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Historique des livraisons'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DeliveryHistoryScreen(agent: widget.agent),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Statistiques'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StatisticsScreen(agent: widget.agent),
                ),
              );
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Déconnexion'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivraisonCard(BonLivraison livraison) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (livraison.status) {
      case 'en_attente':
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
        statusText = 'En attente';
        break;
      case 'livre':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Livrée';
        break;
      case 'non_livre':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Non livrée';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
        statusText = 'Inconnu';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DeliveryDetailsScreen(
                livraison: livraison,
                onStatusChanged: (String newStatus) {
                  _updateLivraisonStatus(livraison, newStatus);
                },
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ID Commande (Référence) et statut
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.receipt, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            "ID: ${livraison.reference}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Nom du client
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Client: ${livraison.clientNom}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Ville
              Row(
                children: [
                  const Icon(Icons.location_city, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Ville: ${livraison.villeClient}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Adresse (région)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Adresse: ${livraison.clientAdresse}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
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
} 