import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'onboarding_screen.dart';
import 'warehouse_3d_screen.dart';
import 'admin_clients_screen.dart';
import 'new_sale_order_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'products_screen.dart';
import 'purchase_orders_screen.dart';
import 'sale_orders_screen.dart';
import 'stock_takes_screen.dart';
import 'wave_picks_screen.dart';
import 'warehouse_locations_screen.dart';
import 'scan_allocate_screen.dart';
import 'scan_order_screen.dart';
import 'customer_screen.dart';
import 'new_purchase_order_screen.dart';
import '../services/benny_data_seeder.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedClient = 'All Clients';
  final List<String> clients = ['All Clients', 'Client A', 'Client B']; // TODO: Replace with real client list

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/Breadcrumb.png', height: 36),
            const SizedBox(width: 12),
            const Text('Admin Panel'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Quick Add'),
            Tab(text: 'Warehouse'),
            Tab(text: 'Customer'),
            Tab(text: 'Reports & More'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Dashboard Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Sale Orders (Daily)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: selectedClient,
                      items: clients.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (v) => setState(() => selectedClient = v ?? 'All Clients'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: _SaleOrdersLineChart(selectedClient: selectedClient),
                ),
                const SizedBox(height: 32),
                const Text('Sale Orders: Fulfilled vs Open', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: _SaleOrdersPieChart(selectedClient: selectedClient),
                ),
              ],
            ),
          ),
          // Quick Add Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart),
                  label: const Text('New Sale Order'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NewSaleOrderScreen()),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_business),
                  label: const Text('New Purchase Order'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const NewPurchaseOrderScreen()),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add),
                  label: const Text('Create New Account'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.group_add),
                  label: const Text('Onboard New Client'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const OnboardingScreen()),
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.data_usage),
                  label: const Text('Seed Benny Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _seedBennyData(),
                ),
              ],
            ),
          ),
          // Warehouse Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.inventory),
                  title: const Text('Products (CV)'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ProductsScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.shopping_bag),
                  title: const Text('Purchase Orders (CV)'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PurchaseOrdersScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.sell),
                  title: const Text('Sale Orders (CV)'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SaleOrdersScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.fact_check),
                  title: const Text('Stock Takes (PV)'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StockTakesScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.waves),
                  title: const Text('Wave Picks (PV)'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WavePicksScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.location_on),
                  title: const Text('Warehouse Locations (PV)'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WarehouseLocationsScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text('Scan Allocate (PV)'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanAllocateScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: const Text('Scan Order (PV)'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanOrderScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.view_in_ar),
                  title: const Text('3D Warehouse Editor'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const Warehouse3DScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          // Customer Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Customer'),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerScreen()),
              ),
            ),
          ),
          // Reports & More Tab
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: const Icon(Icons.receipt_long),
                  title: const Text('Invoices (CV)'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.bar_chart),
                  title: const Text('Stock Report'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StockReportScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.receipt),
                  title: const Text('Bills'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.credit_card),
                  title: const Text('Rate Cards'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.settings_applications),
                  title: const Text('Warehouse Settings'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.business),
                  title: const Text('Organisation Settings'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.people),
                  title: const Text('Clients Overview'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminClientsScreen()),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.home),
                  title: const Text('Addresses'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Product Settings'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Documents (CV)'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Cash on Delivery'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.import_export),
                  title: const Text('Import Log'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.print),
                  title: const Text('Print Log (PV)'),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.label),
                  title: const Text('Bulk Pallet Label Printing (PV)'),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Seed Benny data for demonstration
  Future<void> _seedBennyData() async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Seeding Benny data...'),
              ],
            ),
          );
        },
      );

      // Seed the data
      await BennyDataSeeder.seedAllData();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Benny data seeded successfully! Check all tabs to see the data.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );

        // Refresh the UI
        setState(() {});
      }
    } catch (e) {
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error seeding data: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }
}

class _SaleOrdersLineChart extends StatelessWidget {
  final String selectedClient;
  const _SaleOrdersLineChart({required this.selectedClient});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('saleOrders').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        // Filter by client if not 'All Clients'
        final filtered = selectedClient == 'All Clients'
            ? docs
            : docs.where((d) => d['clientId'] == selectedClient).toList();
        // Group by day
        final Map<String, int> dailyCounts = {};
        for (final doc in filtered) {
          final ts = doc['createdAt'];
          DateTime date;
          if (ts is Timestamp) {
            date = ts.toDate();
          } else if (ts is DateTime) {
            date = ts;
          } else {
            continue;
          }
          final day = DateTime(date.year, date.month, date.day);
          final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
          dailyCounts[key] = (dailyCounts[key] ?? 0) + 1;
        }
        final sortedKeys = dailyCounts.keys.toList()..sort();
        final spots = <FlSpot>[];
        for (int i = 0; i < sortedKeys.length; i++) {
          spots.add(FlSpot(i.toDouble(), dailyCounts[sortedKeys[i]]!.toDouble()));
        }
        if (spots.isEmpty) {
          return const Center(child: Text('No sale orders found.'));
        }
        return LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= sortedKeys.length) return const SizedBox();
                    final label = sortedKeys[idx].substring(5); // MM-DD
                    return Text(label, style: const TextStyle(fontSize: 10));
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue,
                barWidth: 3,
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SaleOrdersPieChart extends StatelessWidget {
  final String selectedClient;
  const _SaleOrdersPieChart({required this.selectedClient});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('saleOrders').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        final filtered = selectedClient == 'All Clients'
            ? docs
            : docs.where((d) => d['clientId'] == selectedClient).toList();
        int fulfilled = 0, open = 0;
        for (final doc in filtered) {
          final status = (doc['status'] ?? '').toString().toLowerCase();
          if (status == 'fulfilled' || status == 'complete' || status == 'closed') {
            fulfilled++;
          } else {
            open++;
          }
        }
        if (fulfilled + open == 0) {
          return const Center(child: Text('No sale orders found.'));
        }
        return PieChart(
          PieChartData(
            sections: [
              PieChartSectionData(
                value: fulfilled.toDouble(),
                color: Colors.green,
                title: 'Fulfilled ($fulfilled)',
                radius: 60,
                titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              PieChartSectionData(
                value: open.toDouble(),
                color: Colors.orange,
                title: 'Open ($open)',
                radius: 60,
                titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
            sectionsSpace: 4,
            centerSpaceRadius: 30,
          ),
        );
      },
    );
  }
} 