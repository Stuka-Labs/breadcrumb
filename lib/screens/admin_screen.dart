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
                // Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.dashboard,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Warehouse Dashboard',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Real-time analytics and insights',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Filter Controls
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            DropdownButton<String>(
                              value: selectedClient,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Colors.black),
                              items: [
                                const DropdownMenuItem(value: 'All Clients', child: Text('All Clients')),
                                ...clients.map((c) => DropdownMenuItem<String>(
                                  value: c['id'], 
                                  child: Text(c['name'])
                                )).toList(),
                              ],
                              onChanged: isLoadingClients ? null : (v) => setState(() => selectedClient = v ?? 'All Clients'),
                            ),
                            const SizedBox(height: 8),
                            DropdownButton<String>(
                              value: selectedTimePeriod,
                              dropdownColor: Colors.white,
                              style: const TextStyle(color: Colors.black),
                              items: const [
                                DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                                DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                                DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                              ],
                              onChanged: (v) => setState(() => selectedTimePeriod = v ?? 'Daily'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Key Metrics Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Total Orders',
                        '24',
                        Icons.shopping_cart,
                        Colors.blue,
                        '+12%',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Revenue',
                        '\$12,450',
                        Icons.attach_money,
                        Colors.green,
                        '+8%',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Fulfillment Rate',
                        '94%',
                        Icons.check_circle,
                        Colors.orange,
                        '+3%',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMetricCard(
                        'Active Clients',
                        '8',
                        Icons.people,
                        Colors.purple,
                        '+2',
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Charts Section
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.trending_up,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Sale Orders ($selectedTimePeriod)',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 250,
                              child: _SaleOrdersLineChart(
                                selectedClient: selectedClient, 
                                timePeriod: selectedTimePeriod,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.shade200,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.pie_chart,
                                    color: Colors.green.shade600,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Order Status',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 250,
                              child: _SaleOrdersPieChart(
                                selectedClient: selectedClient,
                                timePeriod: selectedTimePeriod,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Recent Activity Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.history,
                              color: Colors.orange.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Recent Activity',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildRecentActivityList(),
                    ],
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
                // Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade200,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.warehouse,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Warehouse Operations',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Manage inventory, orders, and warehouse operations',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Operations Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _buildWarehouseCard(
                      'Products',
                      'Manage inventory and product catalog',
                      Icons.inventory_2,
                      Colors.blue,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProductsScreen()),
                      ),
                    ),
                    _buildWarehouseCard(
                      'Purchase Orders',
                      'Track incoming inventory orders',
                      Icons.shopping_bag,
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PurchaseOrdersScreen()),
                      ),
                    ),
                    _buildWarehouseCard(
                      'Sale Orders',
                      'Manage outgoing customer orders',
                      Icons.sell,
                      Colors.orange,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SaleOrdersScreen()),
                      ),
                    ),
                    _buildWarehouseCard(
                      'Stock Takes',
                      'Perform inventory audits and counts',
                      Icons.fact_check,
                      Colors.purple,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StockTakesScreen()),
                      ),
                    ),
                    _buildWarehouseCard(
                      'Wave Picks',
                      'Organize picking operations',
                      Icons.waves,
                      Colors.teal,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WavePicksScreen()),
                      ),
                    ),
                    _buildWarehouseCard(
                      'Warehouse Layout',
                      'Configure warehouse zones and bins',
                      Icons.location_on,
                      Colors.red,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WarehouseLocationsScreen()),
                      ),
                    ),
                    _buildWarehouseCard(
                      'Scan Allocate',
                      'Allocate products to orders',
                      Icons.qr_code_scanner,
                      Colors.indigo,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScanAllocateScreen()),
                      ),
                    ),
                    _buildWarehouseCard(
                      'Scan Orders',
                      'Process orders with barcode scanning',
                      Icons.qr_code,
                      Colors.brown,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ScanOrderScreen()),
                      ),
                    ),
                    _buildWarehouseCard(
                      '3D Warehouse',
                      'Visualize warehouse in 3D',
                      Icons.view_in_ar,
                      Colors.pink,
                      () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const Warehouse3DScreen()),
                      ),
                    ),
                  ],
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
                // Header Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.purple.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.shade200,
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reports & Administration',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Access reports, settings, and administrative tools',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Operations Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                  children: [
                    _buildReportsCard(
                      'Invoices',
                      'Generate and manage invoices',
                      Icons.receipt_long,
                      Colors.blue,
                      () {},
                    ),
                    _buildReportsCard(
                      'Stock Report',
                      'View inventory reports and analytics',
                      Icons.bar_chart,
                      Colors.green,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const StockReportScreen()),
                      ),
                    ),
                    _buildReportsCard(
                      'Bills',
                      'Manage vendor bills and payments',
                      Icons.receipt,
                      Colors.orange,
                      () {},
                    ),
                    _buildReportsCard(
                      'Rate Cards',
                      'Configure pricing and rate structures',
                      Icons.credit_card,
                      Colors.purple,
                      () {},
                    ),
                    _buildReportsCard(
                      'Warehouse Settings',
                      'Configure warehouse parameters',
                      Icons.settings_applications,
                      Colors.teal,
                      () {},
                    ),
                    _buildReportsCard(
                      'Organization Settings',
                      'Manage organization preferences',
                      Icons.business,
                      Colors.indigo,
                      () {},
                    ),
                    _buildReportsCard(
                      'Clients Overview',
                      'View and manage client accounts',
                      Icons.people,
                      Colors.pink,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AdminClientsScreen()),
                      ),
                    ),
                    _buildReportsCard(
                      'Addresses',
                      'Manage shipping and billing addresses',
                      Icons.home,
                      Colors.brown,
                      () {},
                    ),
                    _buildReportsCard(
                      'Product Settings',
                      'Configure product parameters',
                      Icons.settings,
                      Colors.cyan,
                      () {},
                    ),
                    _buildReportsCard(
                      'Documents',
                      'Access and manage documents',
                      Icons.description,
                      Colors.grey,
                      () {},
                    ),
                    _buildReportsCard(
                      'Cash on Delivery',
                      'Manage COD payment settings',
                      Icons.attach_money,
                      Colors.amber,
                      () {},
                    ),
                    _buildReportsCard(
                      'Import Log',
                      'View data import history',
                      Icons.import_export,
                      Colors.deepOrange,
                      () {},
                    ),
                    _buildReportsCard(
                      'Print Log',
                      'View printing history and logs',
                      Icons.print,
                      Colors.lightBlue,
                      () {},
                    ),
                    _buildReportsCard(
                      'Bulk Label Printing',
                      'Print labels in bulk quantities',
                      Icons.label,
                      Colors.lightGreen,
                      () {},
                    ),
                  ],
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

  Widget _buildReportsCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: color.withOpacity(0.6),
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWarehouseCard(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: color.withOpacity(0.6),
                      size: 14,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String change) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
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
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList() {
    final activities = [
      {
        'icon': Icons.shopping_cart,
        'title': 'New order received',
        'subtitle': 'Order #BENNY-2024-001 from Alex Chen',
        'time': '2 minutes ago',
        'color': Colors.blue,
      },
      {
        'icon': Icons.check_circle,
        'title': 'Order fulfilled',
        'subtitle': 'Order #BENNY-2024-002 completed',
        'time': '15 minutes ago',
        'color': Colors.green,
      },
      {
        'icon': Icons.warehouse,
        'title': 'Inventory updated',
        'subtitle': 'BENNY Hoodie stock replenished',
        'time': '1 hour ago',
        'color': Colors.orange,
      },
      {
        'icon': Icons.person_add,
        'title': 'New client onboarded',
        'subtitle': 'Supreme brand connected',
        'time': '2 hours ago',
        'color': Colors.purple,
      },
    ];

    return Column(
      children: activities.map((activity) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (activity['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  activity['icon'] as IconData,
                  color: activity['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity['title'] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activity['subtitle'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                activity['time'] as String,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              horizontalInterval: 1,
              verticalInterval: 1,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                );
              },
              getDrawingVerticalLine: (value) {
                return FlLine(
                  color: Colors.grey.shade200,
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= sortedKeys.length) return const SizedBox();
                    final label = _formatTimeLabel(sortedKeys[idx], timePeriod);
                    return Text(
                      label,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blue.shade600,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.blue.shade600,
                      strokeWidth: 2,
                      strokeColor: Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.blue.shade50,
                ),
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
                color: Colors.green.shade600,
                title: 'Fulfilled\n($fulfilled)',
                radius: 80,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                titlePositionPercentageOffset: 0.6,
              ),
              PieChartSectionData(
                value: open.toDouble(),
                color: Colors.orange.shade600,
                title: 'Open\n($open)',
                radius: 80,
                titleStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                titlePositionPercentageOffset: 0.6,
              ),
            ],
            sectionsSpace: 2,
            centerSpaceRadius: 50,
            centerSpaceColor: Colors.white,
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                // Handle touch events if needed
              },
            ),
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