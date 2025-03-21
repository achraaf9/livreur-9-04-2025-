import 'package:flutter/material.dart';
import '../models/agent.dart';
import '../models/bon_livraison.dart';
import '../services/api_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class StatisticsScreen extends StatefulWidget {
  final Agent agent;

  const StatisticsScreen({super.key, required this.agent});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<BonLivraison> _livraisons = [];
  bool _isLoading = true;
  int _totalLivraisons = 0;
  int _livraisonsLivrees = 0;
  int _livraisonsNonLivrees = 0;
  int _livraisonsEnAttente = 0;
  double _tauxReussite = 0.0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final apiService = await ApiService.getInstance();
      final livraisons = await apiService.getLivraisonsByAgent(widget.agent.id);
      
      if (mounted) {
        setState(() {
          _livraisons = livraisons;
          _totalLivraisons = livraisons.length;
          _livraisonsLivrees = livraisons.where((l) => l.status == 'livre').length;
          _livraisonsNonLivrees = livraisons.where((l) => l.status == 'non_livre').length;
          _livraisonsEnAttente = livraisons.where((l) => l.status == 'en_attente' || l.status == 'en_cours').length;
          
          final completed = _livraisonsLivrees + _livraisonsNonLivrees;
          _tauxReussite = completed > 0 
              ? (_livraisonsLivrees / completed) * 100 
              : 0.0;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Générer des données de test en cas d'échec
          _generateTestData();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement des statistiques: $e\nUtilisation de données de test.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  
  // Méthode pour générer des données de test en cas d'échec de l'API
  void _generateTestData() {
    final random = Random();
    final statuses = ['en_attente', 'en_cours', 'livre', 'non_livre'];
    final villes = ['Casablanca', 'Rabat', 'Marrakech', 'Agadir', 'Tanger', 'Fès'];
    
    // Générer 15 livraisons aléatoires
    _livraisons = List.generate(15, (index) {
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
    
    // Mettre à jour les statistiques
    _totalLivraisons = _livraisons.length;
    _livraisonsLivrees = _livraisons.where((l) => l.status == 'livre').length;
    _livraisonsNonLivrees = _livraisons.where((l) => l.status == 'non_livre').length;
    _livraisonsEnAttente = _livraisons.where((l) => l.status == 'en_attente' || l.status == 'en_cours').length;
    
    final completed = _livraisonsLivrees + _livraisonsNonLivrees;
    _tauxReussite = completed > 0 
        ? (_livraisonsLivrees / completed) * 100 
        : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carte de résumé
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Résumé des livraisons',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildStatRow('Total des livraisons', _totalLivraisons.toString()),
                            _buildStatRow('Livraisons réussies', _livraisonsLivrees.toString()),
                            _buildStatRow('Livraisons échouées', _livraisonsNonLivrees.toString()),
                            _buildStatRow('Livraisons en attente', _livraisonsEnAttente.toString()),
                            _buildStatRow(
                              'Taux de réussite', 
                              '${_tauxReussite.toStringAsFixed(1)}%',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Graphique des statuts
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Répartition des livraisons',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: _buildStatusChart(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Performances récentes
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Performances récentes',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildPerformanceIndicator(
                              'Taux de réussite',
                              _tauxReussite / 100,
                              _getPerformanceColor(_tauxReussite / 100),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChart() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _buildChartBar('Livrées', _livraisonsLivrees, _totalLivraisons, Colors.green),
        _buildChartBar('Non livrées', _livraisonsNonLivrees, _totalLivraisons, Colors.red),
        _buildChartBar('En attente', _livraisonsEnAttente, _totalLivraisons, Colors.orange),
      ],
    );
  }

  Widget _buildChartBar(String label, int value, int total, Color color) {
    final double percentage = total > 0 ? value / total : 0;
    final double height = 150 * percentage;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 60,
          height: height > 0 ? height : 10,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(label),
      ],
    );
  }

  Widget _buildPerformanceIndicator(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 10,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('0%'),
            Text('${(value * 100).toStringAsFixed(1)}%'),
            const Text('100%'),
          ],
        ),
      ],
    );
  }

  Color _getPerformanceColor(double value) {
    if (value >= 0.8) return Colors.green;
    if (value >= 0.5) return Colors.orange;
    return Colors.red;
  }
} 