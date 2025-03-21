import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'models/agent.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsScreen extends StatefulWidget {
  final Agent agent;

  const StatisticsScreen({super.key, required this.agent});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  bool _isLoading = true;
  Map<String, int> _livraisonsByStatus = {};
  double _completionRate = 0.0;
  int _totalLivraisons = 0;

  // Cache pour les données calculées
  List<BarChartGroupData>? _cachedBarGroups;
  List<PieChartSectionData>? _cachedPieSections;
  List<Widget>? _cachedLegendItems;
  DateTime? _lastRefreshTime;
  
  // Durée minimum entre les rafraîchissements
  static const Duration _minRefreshInterval = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    // Utiliser un délai court pour laisser l'interface se construire d'abord
    Future.delayed(const Duration(milliseconds: 100), _loadStatistics);
  }

  Future<void> _loadStatistics() async {
    // Vérifier s'il est nécessaire de rafraîchir (éviter les rafraîchissements trop fréquents)
    if (_lastRefreshTime != null) {
      final timeSinceLastRefresh = DateTime.now().difference(_lastRefreshTime!);
      if (timeSinceLastRefresh < _minRefreshInterval) {
        // Attendre un peu avant de rafraîchir à nouveau
        await Future.delayed(_minRefreshInterval - timeSinceLastRefresh);
      }
    }
    
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = await ApiService.getInstance();
      
      // Utiliser un timeout pour éviter les requêtes qui durent trop longtemps
      final livraisons = await apiService.getLivraisonsByAgent(widget.agent.id)
          .timeout(const Duration(seconds: 10), 
              onTimeout: () => throw Exception('Délai d'attente dépassé'));
      
      // Utilisation d'un traitement optimisé pour réduire le temps de calcul
      final Map<String, int> livraisonsByStatus = {
        'en_attente': 0, 'en_cours': 0, 'livre': 0, 'non_livre': 0,
      };
      
      int totalCompleted = 0;
      
      // Traitement optimisé en un seul passage
      for (final livraison in livraisons) {
        final status = livraison.status;
        if (livraisonsByStatus.containsKey(status)) {
          livraisonsByStatus[status] = (livraisonsByStatus[status] ?? 0) + 1;
          if (status == 'livre' || status == 'non_livre') {
            totalCompleted++;
          }
        }
      }
      
      final int total = livraisons.length;
      final double completionRate = total > 0 ? totalCompleted / total : 0.0;
      
      // Invalider le cache lorsque les données changent
      _cachedBarGroups = null;
      _cachedPieSections = null;
      _cachedLegendItems = null;
      
      // Enregistrer l'heure du dernier rafraîchissement
      _lastRefreshTime = DateTime.now();
      
      if (mounted) {
        setState(() {
          _livraisonsByStatus = livraisonsByStatus;
          _completionRate = completionRate;
          _totalLivraisons = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Erreur lors du chargement des statistiques: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Bouton de rafraîchissement manuel avec indicateur de dernière mise à jour
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: _lastRefreshTime != null 
              ? 'Dernière mise à jour: ${_formatDateTime(_lastRefreshTime!)}'
              : 'Rafraîchir',
            onPressed: _isLoading ? null : _loadStatistics,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Chargement des données...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadStatistics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre avec info de mise à jour
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Text(
                    'Statistiques de livraison pour ${widget.agent.prenom} ${widget.agent.nom}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                        if (_lastRefreshTime != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Mis à jour le: ${_formatDateTime(_lastRefreshTime!)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Utilisation de FutureBuilder pour rendre l'interface plus réactive
                    FutureBuilder<Widget>(
                      future: Future.microtask(() => _buildPerformanceCard()),
                      initialData: _buildLoadingCard('Performance globale'),
                      builder: (context, snapshot) {
                        return snapshot.data ?? _buildLoadingCard('Performance globale');
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    FutureBuilder<Widget>(
                      future: Future.microtask(() => _buildBarChart()),
                      initialData: _buildLoadingCard('Répartition des livraisons par statut'),
                      builder: (context, snapshot) {
                        return snapshot.data ?? _buildLoadingCard('Répartition des livraisons par statut');
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    FutureBuilder<Widget>(
                      future: Future.microtask(() => _buildPieChart()),
                      initialData: _buildLoadingCard('Répartition des livraisons (%)'),
                      builder: (context, snapshot) {
                        return snapshot.data ?? _buildLoadingCard('Répartition des livraisons (%)');
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
  
  Widget _buildLoadingCard(String title) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: SizedBox(
                height: 100,
                child: Text('Préparation des données...'),
              ),
            ),
                ],
              ),
            ),
    );
  }

  Widget _buildPerformanceCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance globale',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total de livraisons: $_totalLivraisons',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Taux de complétion: ${(_completionRate * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getPerformanceColor(_completionRate),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    children: [
                      CircularProgressIndicator(
                        value: _completionRate,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getPerformanceColor(_completionRate),
                        ),
                        strokeWidth: 8,
                      ),
                      Center(
                        child: Text(
                          '${(_completionRate * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  Widget _buildBarChart() {
    if (_livraisonsByStatus.isEmpty) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Répartition des livraisons par statut',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: Center(child: Text('Aucune donnée disponible')),
              ),
            ],
          ),
        ),
      );
    }
    
    // Utiliser le cache si disponible
    if (_cachedBarGroups == null) {
      final double maxY = _livraisonsByStatus.values.fold(0, (prev, element) => element > prev ? element : prev).toDouble();
      final List<String> statuses = _livraisonsByStatus.keys.toList();
      
      _cachedBarGroups = List.generate(
        _livraisonsByStatus.length,
        (index) {
          final status = statuses[index];
          final count = _livraisonsByStatus[status] ?? 0;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: count.toDouble(),
                color: _getStatusColor(status),
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        },
      );
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition des livraisons par statut',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _livraisonsByStatus.values.fold(0, (prev, element) => element > prev ? element : prev).toDouble(),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final statuses = _livraisonsByStatus.keys.toList();
                          if (value.toInt() >= 0 && value.toInt() < statuses.length) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 4.0,
                              child: Text(
                                _getStatusText(statuses[value.toInt()]),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                        reservedSize: 42,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value == value.roundToDouble()) {
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              space: 0,
                              child: Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: _cachedBarGroups!,
                ),
                swapAnimationDuration: const Duration(milliseconds: 150),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    if (_livraisonsByStatus.isEmpty) {
      return const Card(
        elevation: 4,
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Répartition des livraisons (%)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              SizedBox(
                height: 150,
                child: Center(child: Text('Aucune donnée disponible')),
              ),
            ],
          ),
        ),
      );
    }
    
    final totalLivraisons = _livraisonsByStatus.values.fold(0, (sum, count) => sum + count);
    
    // Utiliser le cache si disponible
    if (_cachedPieSections == null) {
      _cachedPieSections = _livraisonsByStatus.entries.map((entry) {
        final percentage = totalLivraisons > 0
            ? entry.value / totalLivraisons * 100
            : 0.0;
        
        return PieChartSectionData(
          color: _getStatusColor(entry.key),
          value: entry.value.toDouble(),
          title: '${percentage.toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        );
      }).toList();
    }
    
    // Utiliser le cache si disponible
    if (_cachedLegendItems == null) {
      _cachedLegendItems = _livraisonsByStatus.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                color: _getStatusColor(entry.key),
              ),
              const SizedBox(width: 8),
              Text(
                '${_getStatusText(entry.key)}: ${entry.value}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      }).toList();
    }
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartition des livraisons (%)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _cachedPieSections!,
                        pieTouchData: PieTouchData(enabled: false),
                      ),
                      swapAnimationDuration: const Duration(milliseconds: 150),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _cachedLegendItems!,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
  
  Color _getPerformanceColor(double value) {
    if (value >= 0.8) return Colors.green;
    if (value >= 0.5) return Colors.orange;
    return Colors.red;
  }
} 