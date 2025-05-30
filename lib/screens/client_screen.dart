import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../constants/theme.dart';
import '../widgets/shop_connect_dialog.dart';
import '../services/ai_insights_service.dart';
import '../services/shopify_service.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedCompetitor = 'CartonCloud';
  final List<String> competitors = ['CartonCloud', 'ShipBob', 'Flexport'];
  String aiInsight = '';
  bool loadingInsight = false;
  bool hasConnectedShop = false;
  Map<String, dynamic>? shopData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAIInsight();
    // TODO: Check backend if user has connected any shops and fetch data if so
    // For now, hasConnectedShop = false; (simulate no connection)
  }

  Future<void> fetchAIInsight() async {
    setState(() => loadingInsight = true);
    aiInsight = await AIInsightsService.getClientPortalInsight(selectedCompetitor);
    setState(() => loadingInsight = false);
  }

  void onShopConnected() async {
    // TODO: Implement real connection logic and fetch data from backend
    setState(() {
      hasConnectedShop = true;
      shopData = null; // Will be set after fetching real data
    });
    // TODO: Fetch real data from APIs and update shopData
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Portal'),
        elevation: 0,
        backgroundColor: kBackgroundColor,
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPastelOrange,
          unselectedLabelColor: kTextColor,
          indicatorColor: kPastelOrange,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.compare), text: 'Competitor'),
          ],
        ),
      ),
      body: hasConnectedShop
          ? _buildDashboardWithData()
          : _buildConnectShopPrompt(),
    );
  }

  Widget _buildConnectShopPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.link, color: kPastelOrange, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Connect your shop to get started!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'To see your sales, orders, and shipping analytics, connect your Shopify, Etsy, Amazon, WooCommerce, or TikTok Shop account.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_link),
              label: const Text('Connect Shop'),
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => ShopConnectDialog(onConnected: onShopConnected),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPastelOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardWithData() {
    // TODO: Replace with widgets that use real shopData
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.analytics, color: kPastelOrange, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Your shop data will appear here!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Once you connect a shop, your sales, orders, and shipping analytics will be shown here in real time.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OrdersList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _metricCard('Sales (This Month)', '1,240', Icons.attach_money),
        _metricCard('Packages Shipped', '980', Icons.local_shipping),
        _metricCard('Avg Delivery Time', '2.3 days', Icons.timer),
        _metricCard('Platforms', '4', Icons.storefront),
      ],
    );
  }

  Widget _metricCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kPastelOrange, size: 32),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    return Row(
      children: [
        Expanded(child: _salesLineChart()),
        const SizedBox(width: 24),
        Expanded(child: _platformPieChart()),
      ],
    );
  }

  Widget _salesLineChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sales Over Time', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        FlSpot(0, 10),
                        FlSpot(1, 30),
                        FlSpot(2, 50),
                        FlSpot(3, 40),
                        FlSpot(4, 80),
                        FlSpot(5, 100),
                        FlSpot(6, 120),
                      ],
                      isCurved: true,
                      color: kPastelOrange,
                      barWidth: 4,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _platformPieChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Orders by Platform', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: 40, color: kPastelOrange, title: 'Amazon'),
                    PieChartSectionData(value: 30, color: Colors.orangeAccent, title: 'Etsy'),
                    PieChartSectionData(value: 20, color: Colors.deepOrangeAccent, title: 'TikTok'),
                    PieChartSectionData(value: 10, color: Colors.amber, title: 'Woo'),
                  ],
                  sectionsSpace: 2,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopConnectSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            const Icon(Icons.link, color: kPastelOrange, size: 32),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Connect your shop to import sales orders directly from your favorite platforms.',
                style: TextStyle(fontSize: 16),
              ),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_link),
              label: const Text('Connect Shop'),
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const ShopConnectDialog(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: kPastelOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIInsightsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: loadingInsight
            ? const Center(child: CircularProgressIndicator())
            : Row(
                children: [
                  const Icon(Icons.insights, color: kPastelOrange, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      aiInsight,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: kPastelOrange),
                    onPressed: fetchAIInsight,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCompetitorTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Icon(Icons.compare_arrows, color: kPastelOrange, size: 32),
                  const SizedBox(width: 16),
                  const Text('Compare with competitor:', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: selectedCompetitor,
                    items: competitors.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedCompetitor = val;
                        });
                        fetchAIInsight();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildCompetitorChart(),
          const SizedBox(height: 32),
          _buildAIInsightsSection(),
        ],
      ),
    );
  }

  Widget _buildCompetitorChart() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Avg Delivery Time: You vs $selectedCompetitor', style: const TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 5,
                  barGroups: [
                    BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 2.3, color: kPastelOrange)],
                      showingTooltipIndicators: [0]),
                    BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 3.1, color: Colors.grey)],
                      showingTooltipIndicators: [0]),
                  ],
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('You');
                            case 1:
                              return Text(selectedCompetitor);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OrdersList extends StatefulWidget {
  const OrdersList({super.key});

  @override
  State<OrdersList> createState() => _OrdersListState();
}

class _OrdersListState extends State<OrdersList> {
  late Future<List<dynamic>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = ShopifyService.fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _ordersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No orders found.'));
        }
        final orders = snapshot.data!;
        return ListView.builder(
          shrinkWrap: true,
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index]['node'];
            return ListTile(
              title: Text(order['name']),
              subtitle: Text('Created: ${order['createdAt']}'),
              trailing: Text('${order['totalPriceSet']['shopMoney']['amount']} ${order['totalPriceSet']['shopMoney']['currencyCode']}'),
            );
          },
        );
      },
    );
  }
} 