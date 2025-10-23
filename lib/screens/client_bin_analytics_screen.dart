import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ClientBinAnalyticsScreen extends StatefulWidget {
  const ClientBinAnalyticsScreen({super.key});

  @override
  State<ClientBinAnalyticsScreen> createState() => _ClientBinAnalyticsScreenState();
}

class _ClientBinAnalyticsScreenState extends State<ClientBinAnalyticsScreen> {
  Map<String, dynamic> binAnalytics = {};
  List<Map<String, dynamic>> binDetails = [];
  bool isLoading = true;
  String selectedTimeframe = '30 days';

  @override
  void initState() {
    super.initState();
    _loadBinAnalytics();
  }

  Future<void> _loadBinAnalytics() async {
    setState(() => isLoading = true);
    try {
      // Get current user's client ID
      final userId = 'client@gmail.com'; // This should come from auth service
      
      // Get all bins used by this client
      final locationsSnapshot = await FirebaseFirestore.instance
          .collection('locations')
          .where('clientId', isEqualTo: userId)
          .get();
      
      // Get products for this client
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('clientId', isEqualTo: userId)
          .get();
      
      // Calculate analytics
      final totalBins = locationsSnapshot.docs.length;
      final activeBins = locationsSnapshot.docs
          .where((doc) => doc.data()['status'] == 'active')
          .length;
      
      final totalProducts = productsSnapshot.docs.length;
      final totalValue = productsSnapshot.docs.fold<double>(0, (sum, doc) {
        final data = doc.data();
        return sum + ((data['price'] ?? 0) * (data['stock'] ?? 0));
      });
      
      // Calculate bin utilization
      final binUtilization = totalBins > 0 ? (activeBins / totalBins) * 100 : 0.0;
      
      // Calculate cost savings
      final averageBinCost = 15.0; // Monthly cost per bin
      final monthlyBinCost = activeBins * averageBinCost;
      final potentialSavings = (totalBins - activeBins) * averageBinCost;
      
      setState(() {
        binAnalytics = {
          'totalBins': totalBins,
          'activeBins': activeBins,
          'utilizationRate': binUtilization,
          'totalProducts': totalProducts,
          'totalValue': totalValue,
          'monthlyBinCost': monthlyBinCost,
          'potentialSavings': potentialSavings,
        };
        
        binDetails = locationsSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'binId': doc.id,
            'location': 'Z${data['zone']}-A${data['aisle']}-S${data['shelf']}-B${data['bin']}',
            'status': data['status'],
            'capacity': data['capacity'] ?? 0,
            'currentStock': data['currentStock'] ?? 0,
            'utilization': data['capacity'] > 0 
                ? ((data['currentStock'] ?? 0) / data['capacity']) * 100 
                : 0.0,
            'lastUpdated': data['updatedAt'],
          };
        }).toList();
        
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bin Analytics & Cost Savings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBinAnalytics,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeframe Selector
                  Row(
                    children: [
                      const Text('Timeframe:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: selectedTimeframe,
                        items: const [
                          DropdownMenuItem(value: '7 days', child: Text('7 days')),
                          DropdownMenuItem(value: '30 days', child: Text('30 days')),
                          DropdownMenuItem(value: '90 days', child: Text('90 days')),
                        ],
                        onChanged: (value) {
                          setState(() => selectedTimeframe = value ?? '30 days');
                          _loadBinAnalytics();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Key Metrics Cards
                  _buildMetricsCards(),
                  const SizedBox(height: 24),
                  
                  // Cost Savings Section
                  _buildCostSavingsSection(),
                  const SizedBox(height: 24),
                  
                  // Bin Utilization Chart
                  _buildUtilizationChart(),
                  const SizedBox(height: 24),
                  
                  // Bin Details Table
                  _buildBinDetailsTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricsCards() {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'Total Bins',
            value: '${binAnalytics['totalBins']}',
            icon: Icons.inventory_2,
            color: Colors.blue,
            subtitle: '${binAnalytics['activeBins']} active',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Utilization',
            value: '${binAnalytics['utilizationRate'].toStringAsFixed(1)}%',
            icon: Icons.trending_up,
            color: Colors.green,
            subtitle: 'Bin efficiency',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            title: 'Products',
            value: '${binAnalytics['totalProducts']}',
            icon: Icons.shopping_bag,
            color: Colors.orange,
            subtitle: 'In warehouse',
          ),
        ),
      ],
    );
  }

  Widget _buildCostSavingsSection() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.savings, color: Colors.green.shade600, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Cost Savings Analysis',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _CostCard(
                    title: 'Monthly Bin Cost',
                    value: '\$${binAnalytics['monthlyBinCost'].toStringAsFixed(2)}',
                    color: Colors.red,
                    icon: Icons.payments,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _CostCard(
                    title: 'Potential Savings',
                    value: '\$${binAnalytics['potentialSavings'].toStringAsFixed(2)}',
                    color: Colors.green,
                    icon: Icons.trending_down,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.green.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Optimize your bin usage to save \$${binAnalytics['potentialSavings'].toStringAsFixed(2)} monthly!',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUtilizationChart() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bin Utilization Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: (binAnalytics['utilizationRate'] ?? 0).toDouble(),
                      color: Colors.green,
                      title: 'Used\n${binAnalytics['utilizationRate'].toStringAsFixed(1)}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: (100 - (binAnalytics['utilizationRate'] ?? 0)).toDouble(),
                      color: Colors.grey.shade300,
                      title: 'Available\n${(100 - (binAnalytics['utilizationRate'] ?? 0)).toStringAsFixed(1)}%',
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBinDetailsTable() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bin Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Bin ID')),
                  DataColumn(label: Text('Location')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Utilization')),
                  DataColumn(label: Text('Stock/Capacity')),
                ],
                rows: binDetails.map((bin) {
                  return DataRow(
                    cells: [
                      DataCell(Text(bin['binId'].substring(0, 8))),
                      DataCell(Text(bin['location'])),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: bin['status'] == 'active' ? Colors.green.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            bin['status'],
                            style: TextStyle(
                              color: bin['status'] == 'active' ? Colors.green.shade700 : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text('${bin['utilization'].toStringAsFixed(1)}%')),
                      DataCell(Text('${bin['currentStock']}/${bin['capacity']}')),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CostCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _CostCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
