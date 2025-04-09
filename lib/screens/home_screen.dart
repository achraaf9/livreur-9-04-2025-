import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/agent.dart';
import '../models/bon_livraison.dart';
import '../config/app_theme.dart';
import 'delivery_list_screen.dart';
import 'statistics_screen.dart';
import 'delivery_details_screen.dart';
import 'package:intl/intl.dart';
import 'delivery_history_screen.dart';
import 'dart:math';
import '../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../utils/permission_utils.dart';
import 'package:permission_handler/permission_handler.dart';

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
  int _selectedIndex = 0;

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
              backgroundColor: AppTheme.primaryColor,
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
            backgroundColor: AppTheme.errorColor,
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
    // Liste des écrans pour la navigation du bas
    final List<Widget> _screens = [
      _buildHomeTab(),
      DeliveryListScreen(agent: widget.agent),
      DeliveryHistoryScreen(agent: widget.agent),
      StatisticsScreen(agent: widget.agent),
    ];

    return Scaffold(
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
        : _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt_outlined),
              activeIcon: Icon(Icons.list_alt),
              label: 'Livraisons',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Historique',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Statistiques',
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour construire l'onglet d'accueil
  Widget _buildHomeTab() {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _fetchLivraisons,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // En-tête avec salutation
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            
            // Cartes de statistiques
            SliverToBoxAdapter(
              child: _buildStatsCards(),
            ),
            
            // En-tête des livraisons en attente
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Livraisons en attente',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
            onPressed: () {
                        setState(() {
                          _selectedIndex = 1; // Naviguer vers l'écran des livraisons
                        });
            },
                      child: const Text('Voir tout'),
          ),
        ],
      ),
              ),
            ),
            
            // Liste des livraisons en attente
            _livraisons.isEmpty
              ? SliverToBoxAdapter(
                  child: _buildEmptyState(),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final livraison = _livraisons[index];
                      return _buildDeliveryCard(livraison);
                    },
                    childCount: _livraisons.length > 3 ? 3 : _livraisons.length,
                  ),
                ),
                
            // Espace en bas
            const SliverToBoxAdapter(
              child: SizedBox(height: 30),
            ),
          ],
        ),
      ),
    );
  }

  // En-tête avec salutation
  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Bonjour';
    } else if (hour < 18) {
      greeting = 'Bon après-midi';
    } else {
      greeting = 'Bonsoir';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$greeting,',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.agent.prenom} ${widget.agent.nom}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'En ligne',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: IconButton(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Actualiser',
                      onPressed: _fetchLivraisons,
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      tooltip: 'Déconnexion',
                      onPressed: () {
                        _showLogoutConfirmationDialog();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Aujourd\'hui: ${_getCurrentDate()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Obtenir la date actuelle formatée
  String _getCurrentDate() {
    final now = DateTime.now();
    final formatter = DateFormat('d MMMM yyyy', 'fr_FR');
    return formatter.format(now);
  }

  // Dialogue de confirmation de déconnexion
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context); // Fermer la boîte de dialogue
              Navigator.pushReplacementNamed(context, '/login'); // Rediriger vers l'écran de connexion
            },
            child: const Text('DÉCONNEXION'),
          ),
        ],
      ),
    );
  }
                    
                      // Cartes de statistiques
  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'En attente',
                            _livraisonsEnAttente.toString(),
                  AppTheme.pendingColor,
                              Icons.pending_actions,
                  'Livraisons à effectuer',
                          ),
                        ),
              const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            'Livrées',
                            _livraisonsLivrees.toString(),
                  AppTheme.successColor,
                  Icons.check_circle_outline,
                  'Livraisons complétées',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
                        Expanded(
                          child: _buildStatCard(
                            'Non livrées',
                            _livraisonsNonLivrees.toString(),
                  AppTheme.errorColor,
                  Icons.highlight_off,
                  'Échecs de livraison',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Total',
                  (_livraisonsEnAttente + _livraisonsLivrees + _livraisonsNonLivrees).toString(),
                  AppTheme.secondaryColor,
                  Icons.inventory_2_outlined,
                  'Toutes les livraisons',
                          ),
                        ),
                      ],
                    ),
        ],
      ),
    );
  }

  // Carte de statistique individuelle
  Widget _buildStatCard(String title, String value, Color color, IconData icon, String subtitle) {
    // Déterminer le statut en fonction du titre
    String status = '';
    if (title == 'En attente') {
      status = 'en_attente';
    } else if (title == 'Livrées') {
      status = 'livre';
    } else if (title == 'Non livrées') {
      status = 'non_livre';
    } else {
      status = 'all'; // Pour "Total"
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedIndex = 2; // Index de l'écran d'historique
                  });
                  // Naviguer vers l'historique avec le filtre approprié
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DeliveryHistoryScreen(
                        agent: widget.agent,
                        initialFilter: status,
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 24,
                  width: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: color.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: color,
                      size: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  // Carte de livraison
  Widget _buildDeliveryCard(BonLivraison livraison) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _navigateToDeliveryDetails(livraison),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppTheme.lightColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Statut et urgence
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.pendingColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.pendingColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pending_actions,
                          size: 14,
                          color: AppTheme.pendingColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'En attente',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.pendingColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.warningColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Aujourd\'hui',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.warningColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // En-tête avec référence et montant
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Référence',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          livraison.reference,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.darkColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Montant',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryColor.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          '${livraison.montantTotal.toStringAsFixed(2)} DH',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    ),
                  ],
                  ),
              
              const Divider(height: 24),
              
              // Informations du client
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
      child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                        Text(
                          'Client',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '${livraison.clientPrenom} ${livraison.clientNom}',
                style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => _callClient(livraison.clientTelephone),
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.successColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_outlined,
                        size: 18,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Adresse
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Adresse',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          livraison.clientAdresse,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.darkColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${livraison.villeClient}, ${livraison.codePostal}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.map_outlined,
                      size: 18,
                      color: AppTheme.darkColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Date de livraison
              Row(
          children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: AppTheme.accentColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
            Text(
                        'Date de livraison',
              style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
              ),
            ),
            Text(
                        livraison.dateLivraison,
              style: const TextStyle(
                fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkColor,
              ),
            ),
          ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showConfirmationDialog(livraison),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Livré'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showNonLivreDialog(livraison),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Non livré'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _navigateToDeliveryDetails(livraison),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor.withOpacity(0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.visibility_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('Voir les détails'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // État vide lorsqu'il n'y a pas de livraisons
  Widget _buildEmptyState() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.lightColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 70,
              color: AppTheme.primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune livraison en attente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Toutes vos livraisons ont été traitées. Revenez plus tard pour voir les nouvelles livraisons.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchLivraisons,
            icon: const Icon(Icons.refresh_outlined),
            label: const Text('ACTUALISER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
              ),
            ),
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
      _fetchLivraisons();
    });
  }

  void _showConfirmationDialog(BonLivraison livraison) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                          child: Text(
                      'Confirmer la livraison',
                      style: TextStyle(
                        fontSize: 18,
                              fontWeight: FontWeight.bold,
                        color: AppTheme.darkColor,
                            ),
                          ),
                        ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Information client
                  Container(
                padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  border: Border.all(
                    color: Colors.grey[200]!,
                  ),
                ),
                child: Column(
                      children: [
                    _buildDialogInfoRow(
                      Icons.person,
                      'Client',
                      '${livraison.clientPrenom} ${livraison.clientNom}',
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDialogInfoRow(
                            Icons.phone,
                            'Téléphone',
                            livraison.clientTelephone,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _callClient(livraison.clientTelephone),
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.call,
                              size: 16,
                              color: AppTheme.successColor,
                            ),
                          ),
                          tooltip: 'Appeler le client',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildDialogInfoRow(
                      Icons.receipt_long,
                      'Référence',
                      livraison.reference,
                    ),
                    const SizedBox(height: 8),
                    _buildDialogInfoRow(
                      Icons.attach_money,
                      'Montant',
                      '${livraison.montantTotal.toStringAsFixed(2)} DH',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              const Text(
                'Commentaire (obligatoire)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Ajouter des détails sur la livraison...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    borderSide: BorderSide(color: AppTheme.successColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                        ),
                      ),
                      child: const Text('ANNULER'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (commentController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(Icons.error_outline, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Veuillez ajouter un commentaire avant de confirmer'),
                                  ),
                                ],
                              ),
                              backgroundColor: AppTheme.errorColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context);
                        _updateLivraisonStatus(livraison, 'livre', commentController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                        ),
                      ),
                      child: const Text('CONFIRMER'),
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

  // Ligne d'information pour les dialogues
  Widget _buildDialogInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
                  Expanded(
                    child: Text(
            value,
                      style: const TextStyle(
                        fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.darkColor,
                      ),
            overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
    );
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
            backgroundColor: AppTheme.errorColor,
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

  void _showNonLivreDialog(BonLivraison livraison) {
    final commentController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.errorColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cancel_outlined,
                      color: AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Marquer comme non livré',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Information client
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  border: Border.all(
                    color: Colors.grey[200]!,
                  ),
                ),
                child: Column(
                  children: [
                    _buildDialogInfoRow(
                      Icons.person,
                      'Client',
                      '${livraison.clientPrenom} ${livraison.clientNom}',
                    ),
                    const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                          child: _buildDialogInfoRow(
                            Icons.phone,
                            'Téléphone',
                            livraison.clientTelephone,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _callClient(livraison.clientTelephone),
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.successColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.call,
                              size: 16,
                              color: AppTheme.successColor,
                            ),
                          ),
                          tooltip: 'Appeler le client',
                  ),
                ],
              ),
                    const SizedBox(height: 8),
                    _buildDialogInfoRow(
                      Icons.receipt_long,
                      'Référence',
                      livraison.reference,
                    ),
                    const SizedBox(height: 8),
                    _buildDialogInfoRow(
                      Icons.attach_money,
                      'Montant',
                      '${livraison.montantTotal.toStringAsFixed(2)} DH',
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              const Text(
                'Raison (obligatoire)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                decoration: InputDecoration(
                  hintText: 'Précisez la raison pour laquelle la livraison n\'a pas pu être effectuée...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    borderSide: BorderSide(color: AppTheme.errorColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Boutons d'action
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                        ),
                      ),
                      child: const Text('ANNULER'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (commentController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: const [
                                  Icon(Icons.error_outline, color: Colors.white),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text('Veuillez ajouter une raison avant de confirmer'),
                                  ),
                                ],
                              ),
                              backgroundColor: AppTheme.errorColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
                          return;
                        }
                        Navigator.pop(context);
                        _updateLivraisonStatus(livraison, 'non_livre', commentController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                        ),
                      ),
                      child: const Text('CONFIRMER'),
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