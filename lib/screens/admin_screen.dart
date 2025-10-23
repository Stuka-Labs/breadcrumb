import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';
import 'onboarding_screen.dart';
import 'warehouse_3d_screen.dart';
import 'admin_clients_screen.dart';
import 'client_management_screen.dart';
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
import '../services/warehouse_demo_seeder.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String selectedClient = 'All Clients';
  String selectedTimePeriod = 'Daily';
  List<Map<String, dynamic>> clients = [];
  bool isLoadingClients = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadClients();
  }

  Future<void> _loadClients() async {
    try {
      // Get all users with role 'client' from Firestore
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'client')
          .get();
      
      final clientList = usersSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'] ?? data['email'] ?? 'Unknown Client',
          'email': data['email'] ?? '',
          'role': data['role'] ?? 'client',
        };
      }).toList();
      
      setState(() {
        clients = clientList;
        isLoadingClients = false;
      });
    } catch (e) {
      debugPrint('Error loading clients: $e');
      setState(() {
        isLoadingClients = false;
      });
    }
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
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: () {
              setState(() {
                // This will trigger a rebuild of the charts
              });
            },
          ),
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
                    Text('Sale Orders ($selectedTimePeriod)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: selectedClient,
                      items: [
                        const DropdownMenuItem(value: 'All Clients', child: Text('All Clients')),
                        ...clients.map((c) => DropdownMenuItem<String>(
                          value: c['id'], 
                          child: Text(c['name'])
                        )).toList(),
                      ],
                      onChanged: isLoadingClients ? null : (v) => setState(() => selectedClient = v ?? 'All Clients'),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: selectedTimePeriod,
                      items: const [
                        DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                        DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                        DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                      ],
                      onChanged: (v) => setState(() => selectedTimePeriod = v ?? 'Daily'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: _SaleOrdersLineChart(
                    selectedClient: selectedClient, 
                    timePeriod: selectedTimePeriod,
                  ),
                ),
                const SizedBox(height: 32),
                const Text('Sale Orders: Fulfilled vs Open', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: _SaleOrdersPieChart(
                    selectedClient: selectedClient,
                    timePeriod: selectedTimePeriod,
                  ),
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.warehouse),
                  label: const Text('Seed Warehouse Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _seedWarehouseData(),
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
          const ClientManagementScreen(),
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

  // Seed warehouse data for demonstration
  Future<void> _seedWarehouseData() async {
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
                Text('Seeding warehouse data...'),
              ],
            ),
          );
        },
      );

      // Seed the warehouse data
      await WarehouseDemoSeeder.seedWarehouseDemoData();
      await WarehouseDemoSeeder.assignProductsToLocations();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Warehouse data seeded successfully! Check warehouse locations and picking system.'),
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
            content: Text('❌ Error seeding warehouse data: $e'),
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
  final String timePeriod;
  const _SaleOrdersLineChart({required this.selectedClient, required this.timePeriod});

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
        List<Map<String, dynamic>> filtered;
        if (selectedClient == 'All Clients') {
          filtered = docs.map((d) => d.data() as Map<String, dynamic>).toList();
        } else {
          // Check if this is the demo client
          final isDemoClient = selectedClient == 'client@gmail.com';
          
          if (isDemoClient) {
            // For demo client, use demo data
            filtered = _getDemoSaleOrders();
          } else {
            // For real clients, use actual data
            filtered = docs.where((d) => (d.data() as Map<String, dynamic>)['clientId'] == selectedClient)
                .map((d) => d.data() as Map<String, dynamic>).toList();
          }
        }
        
        // Group by time period
        final Map<String, int> periodCounts = {};
        
        for (final doc in filtered) {
          final ts = doc['createdAt'];
          DateTime date;
          if (ts is Timestamp) {
            date = ts.toDate();
          } else if (ts is DateTime) {
            date = ts;
          } else if (ts is Map && ts.containsKey('seconds')) {
            // Handle Firestore timestamp from JSON
            date = DateTime.fromMillisecondsSinceEpoch(ts['seconds'] * 1000);
          } else {
            continue;
          }
          
          String key;
          switch (timePeriod) {
            case 'Daily':
              key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
              break;
            case 'Weekly':
              // Get the start of the week (Monday)
              final weekStart = date.subtract(Duration(days: date.weekday - 1));
              key = '${weekStart.year}-W${_getWeekNumber(weekStart)}';
              break;
            case 'Monthly':
              key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
              break;
            default:
              key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
          }
          
          periodCounts[key] = (periodCounts[key] ?? 0) + 1;
        }
        
        final sortedKeys = periodCounts.keys.toList()..sort();
        final spots = <FlSpot>[];
        for (int i = 0; i < sortedKeys.length; i++) {
          spots.add(FlSpot(i.toDouble(), periodCounts[sortedKeys[i]]!.toDouble()));
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
                    final label = _formatTimeLabel(sortedKeys[idx], timePeriod);
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
  
  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysSinceFirstDay = date.difference(firstDayOfYear).inDays;
    return (daysSinceFirstDay / 7).ceil();
  }
  
  String _formatTimeLabel(String key, String period) {
    switch (period) {
      case 'Daily':
        return key.substring(5); // MM-DD
      case 'Weekly':
        return key.split('-W')[1]; // Week number
      case 'Monthly':
        return key.substring(5); // MM
      default:
        return key.substring(5);
    }
  }
  
  List<Map<String, dynamic>> _getDemoSaleOrders() {
    final now = DateTime.now();
    return [
      {
        'id': 'demo-1',
        'clientId': 'client@gmail.com',
        'status': 'fulfilled',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'total': 145.28,
        'customerName': 'Alex Chen',
        'orderNumber': 'BENNY-2024-001',
      },
      {
        'id': 'demo-2',
        'clientId': 'client@gmail.com',
        'status': 'open',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'total': 89.99,
        'customerName': 'Maya Rodriguez',
        'orderNumber': 'BENNY-2024-002',
      },
      {
        'id': 'demo-3',
        'clientId': 'client@gmail.com',
        'status': 'fulfilled',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'total': 219.98,
        'customerName': 'Jordan Kim',
        'orderNumber': 'BENNY-2024-003',
      },
      {
        'id': 'demo-4',
        'clientId': 'client@gmail.com',
        'status': 'open',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
        'total': 79.99,
        'customerName': 'Taylor Swift',
        'orderNumber': 'BENNY-2024-004',
      },
      {
        'id': 'demo-5',
        'clientId': 'client@gmail.com',
        'status': 'fulfilled',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'total': 129.99,
        'customerName': 'Drake',
        'orderNumber': 'BENNY-2024-005',
      },
      {
        'id': 'demo-6',
        'clientId': 'client@gmail.com',
        'status': 'fulfilled',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 6))),
        'total': 39.99,
        'customerName': 'Olivia Green',
        'orderNumber': 'BENNY-2024-006',
      },
      {
        'id': 'demo-7',
        'clientId': 'client@gmail.com',
        'status': 'open',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        'total': 24.99,
        'customerName': 'Noah Wilson',
        'orderNumber': 'BENNY-2024-007',
      },
      {
        'id': 'demo-8',
        'clientId': 'client@gmail.com',
        'status': 'fulfilled',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 8))),
        'total': 179.97,
        'customerName': 'Emma Davis',
        'orderNumber': 'BENNY-2024-008',
      },
    ];
  }
}

class _SaleOrdersPieChart extends StatelessWidget {
  final String selectedClient;
  final String timePeriod;
  const _SaleOrdersPieChart({required this.selectedClient, required this.timePeriod});

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
        List<Map<String, dynamic>> clientFiltered;
        if (selectedClient == 'All Clients') {
          clientFiltered = docs.map((d) => d.data() as Map<String, dynamic>).toList();
        } else {
          // Check if this is the demo client
          final isDemoClient = selectedClient == 'client@gmail.com';
          
          if (isDemoClient) {
            // For demo client, use demo data
            clientFiltered = _getDemoSaleOrders();
          } else {
            // For real clients, use actual data
            clientFiltered = docs.where((d) => (d.data() as Map<String, dynamic>)['clientId'] == selectedClient)
                .map((d) => d.data() as Map<String, dynamic>).toList();
          }
        }
        
        // Filter by time period
        final now = DateTime.now();
        final filtered = clientFiltered.where((doc) {
          final ts = doc['createdAt'];
          DateTime date;
          if (ts is Timestamp) {
            date = ts.toDate();
          } else if (ts is DateTime) {
            date = ts;
          } else if (ts is Map && ts.containsKey('seconds')) {
            // Handle Firestore timestamp from JSON
            date = DateTime.fromMillisecondsSinceEpoch(ts['seconds'] * 1000);
          } else {
            return false;
          }
          
          // Check if the order is within the selected time period
          switch (timePeriod) {
            case 'Daily':
              return date.year == now.year && date.month == now.month && date.day == now.day;
            case 'Weekly':
              final weekStart = now.subtract(Duration(days: now.weekday - 1));
              final weekEnd = weekStart.add(const Duration(days: 6));
              return date.isAfter(weekStart.subtract(const Duration(days: 1))) && 
                     date.isBefore(weekEnd.add(const Duration(days: 1)));
            case 'Monthly':
              return date.year == now.year && date.month == now.month;
            default:
              return true;
          }
        }).toList();
        
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
  
  List<Map<String, dynamic>> _getDemoSaleOrders() {
    final now = DateTime.now();
    return [
      {
        'id': 'demo-1',
        'clientId': 'client@gmail.com',
        'status': 'fulfilled',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 1))),
        'total': 145.28,
        'customerName': 'Alex Chen',
        'orderNumber': 'BENNY-2024-001',
      },
      {
        'id': 'demo-2',
        'clientId': 'client@gmail.com',
        'status': 'open',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 2))),
        'total': 89.99,
        'customerName': 'Maya Rodriguez',
        'orderNumber': 'BENNY-2024-002',
      },
      {
        'id': 'demo-3',
        'clientId': 'client@gmail.com',
        'status': 'fulfilled',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 3))),
        'total': 219.98,
        'customerName': 'Jordan Kim',
        'orderNumber': 'BENNY-2024-003',
      },
      {
        'id': 'demo-4',
        'clientId': 'client@gmail.com',
        'status': 'open',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 4))),
        'total': 79.99,
        'customerName': 'Taylor Swift',
        'orderNumber': 'BENNY-2024-004',
      },
      {
        'id': 'demo-5',
        'clientId': 'client@gmail.com',
        'status': 'fulfilled',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 5))),
        'total': 129.99,
        'customerName': 'Drake',
        'orderNumber': 'BENNY-2024-005',
      },
      {
        'id': 'demo-6',
        'clientId': 'client@gmail.com',
        'status': 'fulfilled',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 6))),
        'total': 39.99,
        'customerName': 'Olivia Green',
        'orderNumber': 'BENNY-2024-006',
      },
      {
        'id': 'demo-7',
        'clientId': 'client@gmail.com',
        'status': 'open',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 7))),
        'total': 24.99,
        'customerName': 'Noah Wilson',
        'orderNumber': 'BENNY-2024-007',
      },
      {
        'id': 'demo-8',
        'clientId': 'client@gmail.com',
        'status': 'fulfilled',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(days: 8))),
        'total': 179.97,
        'customerName': 'Emma Davis',
        'orderNumber': 'BENNY-2024-008',
      },
    ];
  }
} 