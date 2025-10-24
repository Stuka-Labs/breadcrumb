import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Stats Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
                const SizedBox(height: 16),
                // Stats Cards
                _buildStatsCards(),
              ],
            ),
          ),
          // Products List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final docs = snapshot.data!.docs;
                final filteredDocs = _filterProducts(docs);
                
                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty ? 'No products found matching "$_searchQuery"' : 'No products found',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => _showAddProductDialog(context),
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Group products by client
                final groupedProducts = _groupProductsByClient(filteredDocs);
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: groupedProducts.length,
                  itemBuilder: (context, index) {
                    final clientGroup = groupedProducts[index];
                    return _buildClientProductGroup(clientGroup);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('locations').where('isFilled', isEqualTo: false).get(),
        builder: (context, binSnapshot) {
          if (!binSnapshot.hasData || binSnapshot.data!.docs.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () => _showAddProductDialog(context),
            backgroundColor: Colors.blue.shade600,
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }

  List<QueryDocumentSnapshot> _filterProducts(List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final name = (data['name'] ?? '').toString().toLowerCase();
      final sku = (data['sku'] ?? '').toString().toLowerCase();
      final status = (data['status'] ?? '').toString();
      final category = (data['productGroup'] ?? '').toString();
      
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!name.contains(query) && !sku.contains(query)) {
          return false;
        }
      }
      
      // Status filter
      if (_selectedStatus != 'All' && status != _selectedStatus.toLowerCase()) {
        return false;
      }
      
      // Category filter
      if (_selectedCategory != 'All' && category != _selectedCategory) {
        return false;
      }
      
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _groupProductsByClient(List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};
    
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final clientId = data['clientId'] ?? 'Unknown Client';
      final clientName = _getClientName(clientId);
      
      if (!grouped.containsKey(clientName)) {
        grouped[clientName] = [];
      }
      grouped[clientName]!.add(doc);
    }
    
    // Convert to list of maps for easier handling
    return grouped.entries.map((entry) => {
      'clientName': entry.key,
      'clientId': (entry.value.first.data() as Map<String, dynamic>)['clientId'] ?? 'Unknown Client',
      'products': entry.value,
      'productCount': entry.value.length,
    }).toList();
  }

  String _getClientName(String clientId) {
    // For demo purposes, map known client IDs to names
    switch (clientId) {
      case 'client@gmail.com':
        return 'BENNY';
      case 'Unknown Client':
        return 'Unassigned';
      default:
        return clientId; // Use the clientId as name if no mapping found
    }
  }

  Widget _buildClientProductGroup(Map<String, dynamic> clientGroup) {
    final clientName = clientGroup['clientName'] as String;
    final products = clientGroup['products'] as List<QueryDocumentSnapshot>;
    final productCount = clientGroup['productCount'] as int;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Client Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade600, Colors.blue.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        clientName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$productCount product${productCount == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${products.where((doc) => (doc.data() as Map<String, dynamic>)['status'] == 'active').length} Active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Products List
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: products.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildProductCard(data, doc.id),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        
        final docs = snapshot.data!.docs;
        final totalProducts = docs.length;
        final activeProducts = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['status'] ?? '').toString() == 'active';
        }).length;
        final lowStockProducts = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final quantity = (data['quantity'] ?? 0) as int;
          return quantity < 10; // Low stock threshold
        }).length;
        
        return Row(
          children: [
            Expanded(
              child: _buildStatCard('Total Products', totalProducts.toString(), Icons.inventory_2, Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Active', activeProducts.toString(), Icons.check_circle, Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Low Stock', lowStockProducts.toString(), Icons.warning, Colors.orange),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
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
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> data, String productId) {
    final dim = data['dimensions'] ?? {};
    final quantity = data['quantity'] ?? 0;
    final status = data['status'] ?? 'active';
    final isLowStock = quantity < 10;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showProductDetails(data, productId),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Product Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getProductIcon(data['productGroup'] ?? ''),
                      color: _getStatusColor(status),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Unnamed Product',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'SKU: ${data['sku'] ?? 'N/A'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _getStatusColor(status).withOpacity(0.3)),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(status),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Product Details Grid
              Row(
                children: [
                  Expanded(
                    child: _buildDetailItem('Quantity', quantity.toString(), Icons.inventory),
                  ),
                  Expanded(
                    child: _buildDetailItem('Weight', '${data['weight'] ?? 0}g', Icons.scale),
                  ),
                  Expanded(
                    child: _buildDetailItem('Dimensions', '${dim['length'] ?? 0}×${dim['width'] ?? 0}×${dim['height'] ?? 0}cm', Icons.straighten),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Additional Info
              if (data['packaging'] != null && data['packaging'].toString().isNotEmpty)
                _buildInfoRow('Packaging', data['packaging'].toString()),
              if (data['filler'] != null && data['filler'].toString().isNotEmpty)
                _buildInfoRow('Filler', data['filler'].toString()),
              if (data['specialLabel'] != null && data['specialLabel'].toString().isNotEmpty)
                _buildInfoRow('Special Label', data['specialLabel'].toString()),
              // Low Stock Warning
              if (isLowStock)
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Low Stock Alert',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'damaged':
        return Colors.red;
      case 'expired':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getProductIcon(String category) {
    switch (category.toLowerCase()) {
      case 'apparel':
      case 'clothing':
        return Icons.checkroom;
      case 'food':
      case 'beverage':
        return Icons.restaurant;
      case 'electronics':
        return Icons.devices;
      case 'books':
        return Icons.menu_book;
      default:
        return Icons.inventory_2;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Products'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Status')),
                DropdownMenuItem(value: 'active', child: Text('Active')),
                DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                DropdownMenuItem(value: 'expired', child: Text('Expired')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value ?? 'All');
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'All', child: Text('All Categories')),
                DropdownMenuItem(value: 'Apparel', child: Text('Apparel')),
                DropdownMenuItem(value: 'Food', child: Text('Food')),
                DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
              ],
              onChanged: (value) {
                setState(() => _selectedCategory = value ?? 'All');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(Map<String, dynamic> data, String productId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data['name'] ?? 'Product Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('SKU', data['sku'] ?? 'N/A'),
              _buildDetailRow('Status', data['status'] ?? 'N/A'),
              _buildDetailRow('Quantity', (data['quantity'] ?? 0).toString()),
              _buildDetailRow('Weight', '${data['weight'] ?? 0}g'),
              if (data['dimensions'] != null) ...[
                _buildDetailRow('Length', '${data['dimensions']['length'] ?? 0}cm'),
                _buildDetailRow('Width', '${data['dimensions']['width'] ?? 0}cm'),
                _buildDetailRow('Height', '${data['dimensions']['height'] ?? 0}cm'),
              ],
              if (data['packaging'] != null && data['packaging'].toString().isNotEmpty)
                _buildDetailRow('Packaging', data['packaging'].toString()),
              if (data['filler'] != null && data['filler'].toString().isNotEmpty)
                _buildDetailRow('Filler', data['filler'].toString()),
              if (data['specialLabel'] != null && data['specialLabel'].toString().isNotEmpty)
                _buildDetailRow('Special Label', data['specialLabel'].toString()),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    String name = '', sku = '', status = 'active', packaging = '', filler = '', specialLabel = '', locationId = '', productType = 'General', storageChargeMethod = 'Per Location', productGroup = '', measurementCategory = 'Count', baseMeasurement = 'Unit', stockSelectionMethod = '', stockSubSelectionMethod = 'Minimise Storage', bomFallback = 'As per customer default setting';
    int quantity = 0, weight = 0, length = 0, width = 0, height = 0, warningThreshold = 0, expiryThreshold = 0;
    bool lowStockNotification = false;
    List<String> tags = [];
    // Fetch available bins
    final binSnapshot = await FirebaseFirestore.instance.collection('locations').where('isFilled', isEqualTo: false).get();
    final availableBins = binSnapshot.docs;
    if (availableBins.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No available bins. Please create bins first.')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Product'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => name = v ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'SKU'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => sku = v ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Tags (comma separated)'),
                    onSaved: (v) => tags = (v ?? '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || int.tryParse(v) == null ? 'Enter a number' : null,
                    onSaved: (v) => quantity = int.tryParse(v ?? '0') ?? 0,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Weight (g)'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => weight = int.tryParse(v ?? '0') ?? 0,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Length (cm)'),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => length = int.tryParse(v ?? '0') ?? 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Width (cm)'),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => width = int.tryParse(v ?? '0') ?? 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Height (cm)'),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => height = int.tryParse(v ?? '0') ?? 0,
                        ),
                      ),
                    ],
                  ),
                  DropdownButtonFormField<String>(
                    value: productType,
                    items: const [
                      DropdownMenuItem(value: 'General', child: Text('General')),
                      DropdownMenuItem(value: 'Random Weight', child: Text('Random Weight')),
                    ],
                    onChanged: (v) => productType = v ?? 'General',
                    decoration: const InputDecoration(labelText: 'Product Type*'),
                  ),
                  DropdownButtonFormField<String>(
                    value: storageChargeMethod,
                    items: const [
                      DropdownMenuItem(value: 'Per Location', child: Text('Per Location')),
                      DropdownMenuItem(value: 'Per Unit', child: Text('Per Unit')),
                    ],
                    onChanged: (v) => storageChargeMethod = v ?? 'Per Location',
                    decoration: const InputDecoration(labelText: 'Storage Charge Method'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Packaging Type'),
                    onSaved: (v) => packaging = v ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Filler Type'),
                    onSaved: (v) => filler = v ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Special Label'),
                    onSaved: (v) => specialLabel = v ?? '',
                  ),
                  DropdownButtonFormField<String>(
                    value: locationId.isNotEmpty ? locationId : null,
                    items: availableBins.map((doc) {
                      final data = doc.data();
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text('Zone: ${data['zone']} - Aisle: ${data['aisle']} - Shelf: ${data['shelf']} - Bin: ${data['bin']}'),
                      );
                    }).toList(),
                    onChanged: (v) => locationId = v ?? '',
                    validator: (v) => v == null || v.isEmpty ? 'Select a bin' : null,
                    decoration: const InputDecoration(labelText: 'Assign to Bin*'),
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Product Group'),
                    onSaved: (v) => productGroup = v ?? '',
                  ),
                  DropdownButtonFormField<String>(
                    value: measurementCategory,
                    items: const [
                      DropdownMenuItem(value: 'Count', child: Text('Count')),
                      DropdownMenuItem(value: 'Weight', child: Text('Weight')),
                      DropdownMenuItem(value: 'Volume', child: Text('Volume')),
                    ],
                    onChanged: (v) => measurementCategory = v ?? 'Count',
                    decoration: const InputDecoration(labelText: 'Measurement Category*'),
                  ),
                  DropdownButtonFormField<String>(
                    value: baseMeasurement,
                    items: const [
                      DropdownMenuItem(value: 'Unit', child: Text('Unit')),
                      DropdownMenuItem(value: 'Carton', child: Text('Carton')),
                      DropdownMenuItem(value: 'Inner', child: Text('Inner')),
                    ],
                    onChanged: (v) => baseMeasurement = v ?? 'Unit',
                    decoration: const InputDecoration(labelText: 'Base Measurement*'),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Warning Threshold Days*'),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => warningThreshold = int.tryParse(v ?? '0') ?? 0,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Expiry Threshold Days*'),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => expiryThreshold = int.tryParse(v ?? '0') ?? 0,
                        ),
                      ),
                    ],
                  ),
                  CheckboxListTile(
                    value: lowStockNotification,
                    onChanged: (v) => lowStockNotification = v ?? false,
                    title: const Text('Enable Low Stock Notification'),
                  ),
                  DropdownButtonFormField<String>(
                    value: status,
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'damaged', child: Text('Damaged')),
                      DropdownMenuItem(value: 'expired', child: Text('Expired')),
                    ],
                    onChanged: (v) => status = v ?? 'active',
                    decoration: const InputDecoration(labelText: 'Status'),
                  ),
                  DropdownButtonFormField<String>(
                    value: stockSelectionMethod,
                    items: const [
                      DropdownMenuItem(value: '', child: Text('Select')),
                      DropdownMenuItem(value: 'FIFO', child: Text('FIFO')),
                      DropdownMenuItem(value: 'LIFO', child: Text('LIFO')),
                      DropdownMenuItem(value: 'FEFO', child: Text('FEFO')),
                    ],
                    onChanged: (v) => stockSelectionMethod = v ?? '',
                    decoration: const InputDecoration(labelText: 'Stock Selection Method'),
                  ),
                  DropdownButtonFormField<String>(
                    value: stockSubSelectionMethod,
                    items: const [
                      DropdownMenuItem(value: 'Minimise Storage', child: Text('Minimise Storage')),
                      DropdownMenuItem(value: 'Maximise Storage', child: Text('Maximise Storage')),
                    ],
                    onChanged: (v) => stockSubSelectionMethod = v ?? 'Minimise Storage',
                    decoration: const InputDecoration(labelText: 'Stock Sub-Selection Method'),
                  ),
                  DropdownButtonFormField<String>(
                    value: bomFallback,
                    items: const [
                      DropdownMenuItem(value: 'As per customer default setting', child: Text('As per customer default setting')),
                      DropdownMenuItem(value: 'Take from components', child: Text('Take from components')),
                    ],
                    onChanged: (v) => bomFallback = v ?? 'As per customer default setting',
                    decoration: const InputDecoration(labelText: 'BOM Fallback'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  final productRef = await FirebaseFirestore.instance.collection('products').add({
                    'name': name,
                    'sku': sku,
                    'tags': tags,
                    'quantity': quantity,
                    'weight': weight,
                    'dimensions': {'length': length, 'width': width, 'height': height},
                    'packaging': packaging,
                    'filler': filler,
                    'specialLabel': specialLabel,
                    'locationId': locationId,
                    'status': status,
                    'productType': productType,
                    'storageChargeMethod': storageChargeMethod,
                    'productGroup': productGroup,
                    'measurementCategory': measurementCategory,
                    'baseMeasurement': baseMeasurement,
                    'warningThreshold': warningThreshold,
                    'expiryThreshold': expiryThreshold,
                    'lowStockNotification': lowStockNotification,
                    'stockSelectionMethod': stockSelectionMethod,
                    'stockSubSelectionMethod': stockSubSelectionMethod,
                    'bomFallback': bomFallback,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  // Mark bin as filled and assign productId
                  await FirebaseFirestore.instance.collection('locations').doc(locationId).update({
                    'isFilled': true,
                    'productId': productRef.id,
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
} 