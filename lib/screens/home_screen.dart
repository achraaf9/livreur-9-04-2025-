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

  @override
  void initState() {
    super.initState();
    _loadLivraisons();
  }

  Future<void> _loadLivraisons() async {
    setState(() {
      _isLoading = true;
    });

    print('Début du chargement des livraisons pour l\'agent ID: ${widget.agent.id}');
    
    try {
      // Récupérer les livraisons depuis l'API
      final apiService = await ApiService.getInstance();
      final livraisons = await apiService.getLivraisonsByAgent(widget.agent.id);
      
      print('Livraisons récupérées avec succès: ${livraisons.length}');
      
      if (mounted) {
      setState(() {
        _livraisons = livraisons;
          
          // Compter les livraisons par statut
        _livraisonsEnAttente = livraisons.where((l) => l.status == 'en_attente' || l.status == 'en_cours').length;
        _livraisonsLivrees = livraisons.where((l) => l.status == 'livre').length;
        _livraisonsNonLivrees = livraisons.where((l) => l.status == 'non_livre').length;
          
        _isLoading = false;
      });
      }
    } catch (e) {
      print('Erreur lors du chargement des livraisons: $e');
      if (mounted) {
      setState(() {
        _isLoading = false;
          // Générer des données de test en cas d'échec de connexion à l'API
          _generateTestData();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des données: $e\nUtilisation de données de test.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  // Méthode qui génère des données de test
  void _generateTestData() {
    final random = Random();
    final statuses = ['en_attente', 'en_cours', 'livre', 'non_livre'];
    final villes = ['Casablanca', 'Rabat', 'Marrakech', 'Agadir', 'Tanger', 'Fès'];
    
    // Générer 10 livraisons aléatoires
    _livraisons = List.generate(10, (index) {
      final id = index + 1;
      final status = statuses[random.nextInt(statuses.length)];
      
      final dateCommande = DateTime.now().subtract(Duration(days: random.nextInt(30)));
      final dateLivraison = dateCommande.add(Duration(days: random.nextInt(7) + 1));
      
      return BonLivraison(
        id: id,
        reference: 'BL-${2023}-${1000 + id}',
        clientNom: 'Client ${id}',
        clientAdresse: 'Adresse ${id}, Rue ${random.nextInt(100)}',
        clientTelephone: '06${random.nextInt(90000000) + 10000000}',
        villeClient: villes[random.nextInt(villes.length)],
        status: status,
        commentaire: status == 'non_livre' ? 'Client absent' : '',
        dateCommande: '${dateCommande.day}/${dateCommande.month}/${dateCommande.year}',
        dateLivraison: '${dateLivraison.day}/${dateLivraison.month}/${dateLivraison.year}',
        montantTotal: (random.nextDouble() * 1000 + 500).roundToDouble(),
      );
    });
    
    // Mettre à jour les compteurs
    _livraisonsEnAttente = _livraisons.where((l) => l.status == 'en_attente' || l.status == 'en_cours').length;
    _livraisonsLivrees = _livraisons.where((l) => l.status == 'livre').length;
    _livraisonsNonLivrees = _livraisons.where((l) => l.status == 'non_livre').length;
  }

  Future<void> _updateLivraisonStatus(BonLivraison livraison, String status, [String? commentaire]) async {
    try {
      final apiService = await ApiService.getInstance();
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
          clientAdresse: livraison.clientAdresse,
          clientTelephone: livraison.clientTelephone,
          villeClient: livraison.villeClient,
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
          _livraisonsEnAttente = _livraisons.where((l) => l.status == 'en_attente' || l.status == 'en_cours').length;
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
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de la mise à jour du statut'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Erreur lors de la mise à jour du statut: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la mise à jour: $e'),
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
            onPressed: _loadLivraisons,
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
              onRefresh: _loadLivraisons,
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
                                  .take(5)
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
      case 'en_cours':
        statusColor = Colors.blue;
        statusIcon = Icons.local_shipping;
        statusText = 'En cours';
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      livraison.reference,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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
              Text(
                livraison.clientNom,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${livraison.clientAdresse}, ${livraison.villeClient}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
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

  // Méthode pour créer des données de test
  Future<void> _createTestData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      // Générer de nouvelles données de test
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
          SnackBar(content: Text('Erreur: $e')),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 