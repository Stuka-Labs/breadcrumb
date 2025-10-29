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
import '../services/material_service.dart';
import 'material_management_screen.dart';
import 'warehouse_blueprint_screen.dart';
import '../services/warehouse_service.dart';

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
  Map<String, int> dashboardStats = {};
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadClients();
    _loadDashboardStats();
    _initializeMaterials();
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

  Future<void> _loadDashboardStats() async {
    try {
      final stats = await WarehouseService.getDashboardStats();
      setState(() {
        dashboardStats = stats;
        isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard stats: $e');
      setState(() {
        isLoadingStats = false;
      });
    }
  }

  Future<void> _initializeMaterials() async {
    try {
      await MaterialService.initializeDefaultMaterials();
    } catch (e) {
      debugPrint('Error initializing materials: $e');
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
                isLoadingStats = true;
              });
              _loadDashboardStats();
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
                // Header Section - Responsive
                LayoutBuilder(
                  builder: (context, constraints) {
                    bool isMobile = constraints.maxWidth < 600;
                    
                    return Container(
                      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.dashboard,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Warehouse Dashboard',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 2,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Real-time analytics and insights',
                                            style: TextStyle(
                                              color: Colors.white.withOpacity(0.9),
                                              fontSize: 14,
                                            ),
                                            maxLines: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: DropdownButton<String>(
                                          value: selectedClient,
                                          dropdownColor: Colors.white,
                                          style: const TextStyle(color: Colors.black, fontSize: 14),
                                          items: [
                                            const DropdownMenuItem(value: 'All Clients', child: Text('All Clients')),
                                            ...clients.map((c) => DropdownMenuItem<String>(
                                              value: c['id'], 
                                              child: Text(c['name'])
                                            )).toList(),
                                          ],
                                          onChanged: isLoadingClients ? null : (v) => setState(() => selectedClient = v ?? 'All Clients'),
                                          underline: const SizedBox(),
                                          isExpanded: true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: DropdownButton<String>(
                                          value: selectedTimePeriod,
                                          dropdownColor: Colors.white,
                                          style: const TextStyle(color: Colors.black, fontSize: 14),
                                          items: const [
                                            DropdownMenuItem(value: 'Daily', child: Text('Daily')),
                                            DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                                            DropdownMenuItem(value: 'Monthly', child: Text('Monthly')),
                                          ],
                                          onChanged: (v) => setState(() => selectedTimePeriod = v ?? 'Daily'),
                                          underline: const SizedBox(),
                                          isExpanded: true,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
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
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Warehouse Operations Metrics - Responsive Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // Desktop/Tablet - horizontal row
                      return Row(
                        children: [
                          Expanded(
                            child: _buildWarehouseMetricCard(
                              'Orders Received',
                              isLoadingStats ? '...' : dashboardStats['ordersReceived']?.toString() ?? '0',
                              Icons.inbox,
                              Colors.blue,
                              'Today',
                              () => _showDetailedView('Orders Received'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildWarehouseMetricCard(
                              'Orders Placed',
                              isLoadingStats ? '...' : dashboardStats['ordersPlaced']?.toString() ?? '0',
                              Icons.shopping_cart,
                              Colors.green,
                              'Today',
                              () => _showDetailedView('Orders Placed'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildWarehouseMetricCard(
                              'Orders Shipped',
                              isLoadingStats ? '...' : dashboardStats['ordersShipped']?.toString() ?? '0',
                              Icons.local_shipping,
                              Colors.orange,
                              'Today',
                              () => _showDetailedView('Orders Shipped'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildWarehouseMetricCard(
                              'Waiting to Ship',
                              isLoadingStats ? '...' : dashboardStats['waitingToShip']?.toString() ?? '0',
                              Icons.hourglass_empty,
                              Colors.red,
                              'Pending',
                              () => _showDetailedView('Waiting to Ship'),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Mobile - 2x2 grid
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildWarehouseMetricCard(
                                  'Orders Received',
                                  isLoadingStats ? '...' : dashboardStats['ordersReceived']?.toString() ?? '0',
                                  Icons.inbox,
                                  Colors.blue,
                                  'Today',
                                  () => _showDetailedView('Orders Received'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildWarehouseMetricCard(
                                  'Orders Placed',
                                  isLoadingStats ? '...' : dashboardStats['ordersPlaced']?.toString() ?? '0',
                                  Icons.shopping_cart,
                                  Colors.green,
                                  'Today',
                                  () => _showDetailedView('Orders Placed'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildWarehouseMetricCard(
                                  'Orders Shipped',
                                  isLoadingStats ? '...' : dashboardStats['ordersShipped']?.toString() ?? '0',
                                  Icons.local_shipping,
                                  Colors.orange,
                                  'Today',
                                  () => _showDetailedView('Orders Shipped'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildWarehouseMetricCard(
                                  'Waiting to Ship',
                                  isLoadingStats ? '...' : dashboardStats['waitingToShip']?.toString() ?? '0',
                                  Icons.hourglass_empty,
                                  Colors.red,
                                  'Pending',
                                  () => _showDetailedView('Waiting to Ship'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Second Row - Inventory & Client Metrics
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // Desktop/Tablet - horizontal row
                      return Row(
                        children: [
                          Expanded(
                            child: FutureBuilder<int>(
                              future: WarehouseService.getTotalInventoryCount(),
                              builder: (context, snapshot) {
                                return _buildWarehouseMetricCard(
                                  'Current Inventory',
                                  snapshot.hasData ? snapshot.data.toString() : '...',
                                  Icons.inventory_2,
                                  Colors.purple,
                                  'Items',
                                  () => _showDetailedView('Current Inventory'),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildWarehouseMetricCard(
                              'Low Stock Alerts',
                              isLoadingStats ? '...' : dashboardStats['lowStockAlerts']?.toString() ?? '0',
                              Icons.warning,
                              Colors.amber,
                              'Alerts',
                              () => _showDetailedView('Low Stock Alerts'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildWarehouseMetricCard(
                              'Material Stock',
                              isLoadingStats ? '...' : dashboardStats['materialStockAlerts']?.toString() ?? '0',
                              Icons.storage,
                              Colors.teal,
                              'Boxes/Tape',
                              () => _showDetailedView('Material Stock'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FutureBuilder<int>(
                              future: WarehouseService.getActiveClientCount(),
                              builder: (context, snapshot) {
                                return _buildWarehouseMetricCard(
                                  'Active Clients',
                                  snapshot.hasData ? snapshot.data.toString() : '...',
                                  Icons.people,
                                  Colors.indigo,
                                  'Connected',
                                  () => _showDetailedView('Active Clients'),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Mobile - 2x2 grid
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: FutureBuilder<int>(
                                  future: WarehouseService.getTotalInventoryCount(),
                                  builder: (context, snapshot) {
                                    return _buildWarehouseMetricCard(
                                      'Current Inventory',
                                      snapshot.hasData ? snapshot.data.toString() : '...',
                                      Icons.inventory_2,
                                      Colors.purple,
                                      'Items',
                                      () => _showDetailedView('Current Inventory'),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildWarehouseMetricCard(
                                  'Low Stock Alerts',
                                  isLoadingStats ? '...' : dashboardStats['lowStockAlerts']?.toString() ?? '0',
                                  Icons.warning,
                                  Colors.amber,
                                  'Alerts',
                                  () => _showDetailedView('Low Stock Alerts'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildWarehouseMetricCard(
                                  'Material Stock',
                                  isLoadingStats ? '...' : dashboardStats['materialStockAlerts']?.toString() ?? '0',
                                  Icons.storage,
                                  Colors.teal,
                                  'Boxes/Tape',
                                  () => _showDetailedView('Material Stock'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FutureBuilder<int>(
                                  future: WarehouseService.getActiveClientCount(),
                                  builder: (context, snapshot) {
                                    return _buildWarehouseMetricCard(
                                      'Active Clients',
                                      snapshot.hasData ? snapshot.data.toString() : '...',
                                      Icons.people,
                                      Colors.indigo,
                                      'Connected',
                                      () => _showDetailedView('Active Clients'),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Charts Section - Responsive Layout
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // Desktop/Tablet - side by side
                      return Row(
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
                );
                    } else {
                      // Mobile - stacked vertically
                      return Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
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
                                    Flexible(
                                      child: Text(
                                        'Sale Orders ($selectedTimePeriod)',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  height: 200,
                                  child: _SaleOrdersLineChart(
                                    selectedClient: selectedClient, 
                                    timePeriod: selectedTimePeriod,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(20),
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
                                  height: 200,
                                  child: _SaleOrdersPieChart(
                                    selectedClient: selectedClient,
                                    timePeriod: selectedTimePeriod,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  },
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
                ElevatedButton.icon(
                  icon: const Icon(Icons.storage),
                  label: const Text('Material Management'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MaterialManagementScreen()),
                  ),
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
                      'Warehouse Blueprint',
                      'Design and configure warehouse layout',
                      Icons.location_on,
                      Colors.red,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const WarehouseBlueprintScreen()),
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

  Widget _buildWarehouseMetricCard(String title, String value, IconData icon, Color color, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                Icon(
                  Icons.arrow_forward_ios,
                  color: color.withOpacity(0.6),
                  size: 16,
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
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.7),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
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

  void _showDetailedView(String metricType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('$metricType Details'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: _buildDetailedViewContent(metricType),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailedViewContent(String metricType) {
    switch (metricType) {
      case 'Orders Received':
        return _buildOrdersReceivedView();
      case 'Orders Placed':
        return _buildOrdersPlacedView();
      case 'Orders Shipped':
        return _buildOrdersShippedView();
      case 'Waiting to Ship':
        return _buildWaitingToShipView();
      case 'Current Inventory':
        return _buildCurrentInventoryView();
      case 'Low Stock Alerts':
        return _buildLowStockAlertsView();
      case 'Material Stock':
        return _buildMaterialStockView();
      case 'Active Clients':
        return _buildActiveClientsView();
      default:
        return const Center(child: Text('No data available'));
    }
  }

  Widget _buildOrdersReceivedView() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'received')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders received today'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final order = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.inbox, color: Colors.blue),
              title: Text(order['orderNumber'] ?? 'Unknown Order'),
              subtitle: Text('Customer: ${order['customerName'] ?? 'Unknown'}'),
              trailing: Text(order['totalPrice']?.toString() ?? '0'),
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersPlacedView() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('saleOrders')
          .where('status', isEqualTo: 'open')
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders placed today'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final order = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.green),
              title: Text(order['orderNumber'] ?? 'Unknown Order'),
              subtitle: Text('Customer: ${order['customerName'] ?? 'Unknown'}'),
              trailing: Text('\$${order['total']?.toString() ?? '0'}'),
            );
          },
        );
      },
    );
  }

  Widget _buildOrdersShippedView() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'shipped')
          .orderBy('shippedAt', descending: true)
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders shipped today'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final order = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.local_shipping, color: Colors.orange),
              title: Text(order['orderNumber'] ?? 'Unknown Order'),
              subtitle: Text('Customer: ${order['customerName'] ?? 'Unknown'}'),
              trailing: Text(order['trackingNumber'] ?? 'No tracking'),
            );
          },
        );
      },
    );
  }

  Widget _buildWaitingToShipView() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'ready_to_ship')
          .orderBy('packedAt', descending: true)
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No orders waiting to ship'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final order = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.hourglass_empty, color: Colors.red),
              title: Text(order['orderNumber'] ?? 'Unknown Order'),
              subtitle: Text('Customer: ${order['customerName'] ?? 'Unknown'}'),
              trailing: Text('Ready'),
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentInventoryView() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .orderBy('name')
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No inventory items'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final product = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.inventory_2, color: Colors.purple),
              title: Text(product['name'] ?? 'Unknown Product'),
              subtitle: Text('SKU: ${product['sku'] ?? 'N/A'}'),
              trailing: Text('Qty: ${product['quantity']?.toString() ?? '0'}'),
            );
          },
        );
      },
    );
  }

  Widget _buildLowStockAlertsView() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('products')
          .where('quantity', isLessThan: 10)
          .orderBy('quantity')
          .limit(20)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No low stock alerts'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final product = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final quantity = product['quantity'] ?? 0;
            return ListTile(
              leading: Icon(
                Icons.warning,
                color: quantity < 5 ? Colors.red : Colors.amber,
              ),
              title: Text(product['name'] ?? 'Unknown Product'),
              subtitle: Text('SKU: ${product['sku'] ?? 'N/A'}'),
              trailing: Text(
                'Qty: $quantity',
                style: TextStyle(
                  color: quantity < 5 ? Colors.red : Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMaterialStockView() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('materials')
          .orderBy('name')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No material tracking set up yet'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final material = doc.data() as Map<String, dynamic>;
            final quantity = material['quantity'] ?? 0;
            final minQuantity = material['minQuantity'] ?? 10;
            final isLowStock = quantity <= minQuantity;
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isLowStock ? Colors.red.shade50 : Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.storage,
                    color: isLowStock ? Colors.red : Colors.teal,
                    size: 20,
                  ),
                ),
                title: Text(
                  material['name'] ?? 'Unknown Material',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isLowStock ? Colors.red.shade800 : Colors.black87,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type: ${material['type'] ?? 'N/A'}'),
                    if (isLowStock)
                      Text(
                        '⚠️ Low Stock Alert!',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Editable quantity field
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: TextEditingController(text: quantity.toString()),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isLowStock ? Colors.red : Colors.teal,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isLowStock ? Colors.red : Colors.teal,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isLowStock ? Colors.red : Colors.teal,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: isLowStock ? Colors.red : Colors.teal,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          isDense: true,
                        ),
                        onSubmitted: (value) async {
                          try {
                            final newQuantity = int.parse(value);
                            await MaterialService.updateMaterialQuantity(doc.id, newQuantity);
                            
                            // Show success feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${material['name']} quantity updated to $newQuantity'),
                                backgroundColor: Colors.green,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                            
                            // Refresh the view
                            setState(() {});
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error updating quantity: $e'),
                                backgroundColor: Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quick action buttons
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      onSelected: (value) async {
                        switch (value) {
                          case 'add':
                            try {
                              final newQuantity = quantity + 10;
                              await MaterialService.updateMaterialQuantity(doc.id, newQuantity);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Added 10 to ${material['name']}'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              setState(() {});
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            break;
                          case 'subtract':
                            try {
                              final newQuantity = (quantity - 10).clamp(0, double.infinity).toInt();
                              await MaterialService.updateMaterialQuantity(doc.id, newQuantity);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Subtracted 10 from ${material['name']}'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              setState(() {});
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'add',
                          child: Row(
                            children: [
                              Icon(Icons.add, color: Colors.green),
                              SizedBox(width: 8),
                              Text('Add 10'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'subtract',
                          child: Row(
                            children: [
                              Icon(Icons.remove, color: Colors.orange),
                              SizedBox(width: 8),
                              Text('Subtract 10'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActiveClientsView() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'client')
          .orderBy('name')
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No active clients'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final client = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.people, color: Colors.indigo),
              title: Text(client['name'] ?? client['email'] ?? 'Unknown Client'),
              subtitle: Text(client['email'] ?? 'No email'),
              trailing: Icon(
                Icons.circle,
                color: client['isActive'] == true ? Colors.green : Colors.grey,
                size: 12,
              ),
            );
          },
        );
      },
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