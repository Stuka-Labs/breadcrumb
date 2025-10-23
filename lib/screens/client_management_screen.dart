import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/bin_assignment_service.dart';

class ClientManagementScreen extends StatefulWidget {
  const ClientManagementScreen({super.key});

  @override
  State<ClientManagementScreen> createState() => _ClientManagementScreenState();
}

class _ClientManagementScreenState extends State<ClientManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> clients = [];
  Map<String, dynamic>? selectedClient;
  List<Map<String, dynamic>> clientOrders = [];
  List<Map<String, dynamic>> clientWarehouseItems = [];
  List<Map<String, dynamic>> availableBins = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClients();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() => isLoading = true);
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
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading clients: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectClient(Map<String, dynamic> client) async {
    setState(() {
      selectedClient = client;
      isLoading = true;
    });

    try {
      // Load client's orders
      final orders = await _loadClientOrders(client['id']);
      
      // Load client's warehouse items
      final warehouseItems = await _loadClientWarehouseItems(client['id']);
      
      // Load available bins for assignment
      final bins = await _loadAvailableBins();

      setState(() {
        clientOrders = orders;
        clientWarehouseItems = warehouseItems;
        availableBins = bins;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading client data: $e');
      setState(() => isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _loadClientOrders(String clientId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('saleOrders')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .limit(20)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error loading client orders: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadClientWarehouseItems(String clientId) async {
    try {
      return await BinAssignmentService.getClientBins(clientId);
    } catch (e) {
      debugPrint('Error loading client warehouse items: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadAvailableBins() async {
    try {
      return await BinAssignmentService.getAvailableBins();
    } catch (e) {
      debugPrint('Error loading available bins: $e');
      return [];
    }
  }

  Future<void> _assignBinToClient(String binId, String productId, int quantity) async {
    try {
      await BinAssignmentService.assignBinToClient(
        binId: binId,
        clientId: selectedClient!['id'],
        productId: productId,
        quantity: quantity,
        notes: 'Assigned via admin panel',
      );

      // Refresh data
      await _selectClient(selectedClient!);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Bin assigned successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error assigning bin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredClients {
    if (searchQuery.isEmpty) return clients;
    return clients.where((client) {
      final name = (client['name'] ?? '').toString().toLowerCase();
      final email = (client['email'] ?? '').toString().toLowerCase();
      final query = searchQuery.toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClients,
            tooltip: 'Refresh Clients',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Clients',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          
          // Client List and Details
          Expanded(
            child: Row(
              children: [
                // Client List
                Expanded(
                  flex: 2,
                  child: _buildClientList(),
                ),
                
                // Client Details
                if (selectedClient != null)
                  Expanded(
                    flex: 3,
                    child: _buildClientDetails(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Clients',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: filteredClients.isEmpty
                ? const Center(child: Text('No clients found'))
                : ListView.builder(
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      final isSelected = selectedClient?['id'] == client['id'];
                      
                      // Get display name (username or email)
                      final displayName = client['name'] ?? client['email'] ?? 'Unknown Client';
                      final email = client['email'] ?? '';
                      final avatarText = displayName[0].toUpperCase();
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
                          child: Text(
                            avatarText,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(displayName),
                        subtitle: email.isNotEmpty ? Text(email) : null,
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${client['stats']?['orders'] ?? 0} orders',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${clientWarehouseItems.length} bins',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        selected: isSelected,
                        onTap: () => _selectClient(client),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientDetails() {
    if (selectedClient == null) {
      return const Center(
        child: Text('Select a client to view details'),
      );
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Column(
        children: [
          // Client Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    (selectedClient!['name'] ?? selectedClient!['email'] ?? 'C')[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedClient!['name'] ?? selectedClient!['email'] ?? 'Unknown Client',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (selectedClient!['email'] != null && selectedClient!['email'].isNotEmpty)
                        Text(
                          selectedClient!['email'],
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _showAssignBinDialog(),
                  icon: const Icon(Icons.add_location),
                  tooltip: 'Assign Bins',
                ),
              ],
            ),
          ),
          
          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Sales History', icon: Icon(Icons.shopping_cart)),
              Tab(text: 'Warehouse', icon: Icon(Icons.warehouse)),
              Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
            ],
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSalesHistory(),
                _buildWarehouseView(),
                _buildAnalyticsView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesHistory() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clientOrders.length,
      itemBuilder: (context, index) {
        final order = clientOrders[index];
        final createdAt = order['createdAt'];
        DateTime orderDate;
        
        if (createdAt is Timestamp) {
          orderDate = createdAt.toDate();
        } else if (createdAt is DateTime) {
          orderDate = createdAt;
        } else {
          orderDate = DateTime.now();
        }

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: order['status'] == 'fulfilled' ? Colors.green : Colors.orange,
              child: Icon(
                order['status'] == 'fulfilled' ? Icons.check : Icons.pending,
                color: Colors.white,
              ),
            ),
            title: Text('Order #${order['orderNumber'] ?? order['id']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${order['customerName'] ?? 'Unknown'}'),
                Text('Date: ${orderDate.toString().split(' ')[0]}'),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '\$${order['total']?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  order['status'] ?? 'unknown',
                  style: TextStyle(
                    color: order['status'] == 'fulfilled' ? Colors.green : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWarehouseView() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Summary Cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Assigned Bins',
                  clientWarehouseItems.length.toString(),
                  Icons.inventory_2,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Total Items',
                  clientWarehouseItems.fold<int>(0, (sum, item) => sum + ((item['currentStock'] ?? 0) as int)).toString(),
                  Icons.shopping_bag,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Available Bins',
                  availableBins.length.toString(),
                  Icons.add_location,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ),
        
        // Warehouse Blueprint View
        Expanded(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Client Bins', icon: Icon(Icons.person)),
                    Tab(text: 'All Bins', icon: Icon(Icons.warehouse)),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildClientBinsView(),
                      _buildAllBinsView(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClientBinsView() {
    if (clientWarehouseItems.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No bins assigned to this client',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Use the "Assign Bins" button to assign bins to this client',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: clientWarehouseItems.length,
      itemBuilder: (context, index) {
        final item = clientWarehouseItems[index];
        final utilization = (item['capacity'] ?? 1) > 0 
            ? ((item['currentStock'] ?? 0) / (item['capacity'] ?? 1) * 100)
            : 0.0;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: utilization > 80 ? Colors.red.shade100 : 
                             utilization > 50 ? Colors.orange.shade100 : Colors.green.shade100,
              child: Text(
                'Z${item['zone']}-A${item['aisle']}-S${item['shelf']}-B${item['bin']}',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: utilization > 80 ? Colors.red.shade700 : 
                         utilization > 50 ? Colors.orange.shade700 : Colors.green.shade700,
                ),
              ),
            ),
            title: Text('Bin Z${item['zone']}-A${item['aisle']}-S${item['shelf']}-B${item['bin']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Product: ${item['productId'] ?? 'N/A'}'),
                LinearProgressIndicator(
                  value: utilization / 100,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    utilization > 80 ? Colors.red : 
                    utilization > 50 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${item['currentStock'] ?? 0}/${item['capacity'] ?? 0}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${utilization.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: utilization > 80 ? Colors.red : 
                           utilization > 50 ? Colors.orange : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllBinsView() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _loadAllBins(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warehouse, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No warehouse blueprint found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Create a warehouse blueprint first',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final allBins = snapshot.data!;
        final filledBins = allBins.where((bin) => (bin['isFilled'] ?? false)).toList();
        final availableBins = allBins.where((bin) => !(bin['isFilled'] ?? false)).toList();

        return Column(
          children: [
            // Summary
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Bins',
                      allBins.length.toString(),
                      Icons.inventory_2,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Filled Bins',
                      filledBins.length.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildSummaryCard(
                      'Available',
                      availableBins.length.toString(),
                      Icons.add_circle,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            
            // Bins List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: allBins.length,
                itemBuilder: (context, index) {
                  final bin = allBins[index];
                  final isFilled = bin['isFilled'] ?? false;
                  final clientId = bin['clientId'];
                  final currentStock = bin['currentStock'] ?? 0;
                  final capacity = bin['capacity'] ?? 0;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isFilled ? Colors.green.shade50 : Colors.grey.shade50,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isFilled ? Colors.green : Colors.grey,
                        child: Text(
                          'Z${bin['zone']}-A${bin['aisle']}-S${bin['shelf']}-B${bin['bin']}',
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      title: Text('Bin Z${bin['zone']}-A${bin['aisle']}-S${bin['shelf']}-B${bin['bin']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isFilled ? 'Assigned to: ${clientId ?? 'Unknown'}' : 'Available for assignment'),
                          if (isFilled) Text('Product: ${bin['productId'] ?? 'N/A'}'),
                          if (isFilled && capacity > 0)
                            LinearProgressIndicator(
                              value: currentStock / capacity,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                (currentStock / capacity) > 0.8 ? Colors.red : 
                                (currentStock / capacity) > 0.5 ? Colors.orange : Colors.green,
                              ),
                            ),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isFilled ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isFilled ? Colors.green : Colors.grey,
                          ),
                          if (isFilled)
                            Text(
                              '$currentStock/$capacity',
                              style: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _loadAllBins() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('locations')
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error loading all bins: $e');
      return [];
    }
  }

  Widget _buildAnalyticsView() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Calculate analytics
    final totalOrders = clientOrders.length;
    final fulfilledOrders = clientOrders.where((o) => o['status'] == 'fulfilled').length;
    final totalRevenue = clientOrders.fold<double>(0, (sum, order) => sum + (order['total'] ?? 0));
    final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Analytics Cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Orders',
                  totalOrders.toString(),
                  Icons.shopping_cart,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Fulfillment Rate',
                  '${totalOrders > 0 ? (fulfilledOrders / totalOrders * 100).toStringAsFixed(1) : 0}%',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Revenue',
                  '\$${totalRevenue.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Avg Order Value',
                  '\$${avgOrderValue.toStringAsFixed(2)}',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
          
          // Chart
          if (clientOrders.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Text(
              'Order Status Distribution',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: fulfilledOrders.toDouble(),
                      color: Colors.green,
                      title: 'Fulfilled ($fulfilledOrders)',
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    PieChartSectionData(
                      value: (totalOrders - fulfilledOrders).toDouble(),
                      color: Colors.orange,
                      title: 'Pending (${totalOrders - fulfilledOrders})',
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ],
                  sectionsSpace: 4,
                  centerSpaceRadius: 30,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignBinDialog() async {
    // Refresh available bins first
    final bins = await _loadAvailableBins();
    setState(() {
      availableBins = bins;
    });

    if (availableBins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available bins to assign. Create a warehouse blueprint first.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _AssignBinDialog(
        availableBins: availableBins,
        onAssign: _assignBinToClient,
      ),
    );
  }
}

class _AssignBinDialog extends StatefulWidget {
  final List<Map<String, dynamic>> availableBins;
  final Function(String binId, String productId, int quantity) onAssign;

  const _AssignBinDialog({
    required this.availableBins,
    required this.onAssign,
  });

  @override
  State<_AssignBinDialog> createState() => _AssignBinDialogState();
}

class _AssignBinDialogState extends State<_AssignBinDialog> {
  String? selectedBinId;
  final TextEditingController _productIdController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  @override
  void dispose() {
    _productIdController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Bin to Client'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedBinId,
              decoration: const InputDecoration(labelText: 'Select Bin'),
              items: widget.availableBins.map((bin) {
                return DropdownMenuItem<String>(
                  value: bin['id'],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Z${bin['zone']}-A${bin['aisle']}-S${bin['shelf']}-B${bin['bin']}'),
                      Text(
                        'Capacity: ${bin['capacity'] ?? 0} items',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() => selectedBinId = value),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _productIdController,
              decoration: const InputDecoration(
                labelText: 'Product ID',
                hintText: 'Enter the product identifier',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Initial Quantity',
                hintText: 'How many items to place in this bin',
              ),
              keyboardType: TextInputType.number,
            ),
            if (selectedBinId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bin Information:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('Location: Z${widget.availableBins.firstWhere((b) => b['id'] == selectedBinId)['zone']}-A${widget.availableBins.firstWhere((b) => b['id'] == selectedBinId)['aisle']}-S${widget.availableBins.firstWhere((b) => b['id'] == selectedBinId)['shelf']}-B${widget.availableBins.firstWhere((b) => b['id'] == selectedBinId)['bin']}'),
                    Text('Capacity: ${widget.availableBins.firstWhere((b) => b['id'] == selectedBinId)['capacity'] ?? 0} items'),
                    Text('Status: Available for assignment'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: selectedBinId != null && 
                    _productIdController.text.isNotEmpty && 
                    _quantityController.text.isNotEmpty
              ? () {
                  widget.onAssign(
                    selectedBinId!,
                    _productIdController.text,
                    int.tryParse(_quantityController.text) ?? 0,
                  );
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Assign Bin'),
        ),
      ],
    );
  }
}
