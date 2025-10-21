import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/client_service.dart';

class AdminClientsScreen extends StatefulWidget {
  const AdminClientsScreen({super.key});

  @override
  State<AdminClientsScreen> createState() => _AdminClientsScreenState();
}

class _AdminClientsScreenState extends State<AdminClientsScreen> {
  List<dynamic> clients = [];
  List<dynamic> filteredClients = [];
  bool loading = false;
  String? error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchClients() async {
    setState(() => loading = true);
    try {
      final c = await ClientService.fetchClients();
      setState(() {
        clients = c;
        filteredClients = c;
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void filterClients(String query) {
    setState(() {
      filteredClients = clients.where((c) => (c['name'] ?? c['id']).toString().toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Never';
    
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is DateTime) {
        dateTime = timestamp;
      } else if (timestamp is Map && timestamp.containsKey('seconds')) {
        // Handle Firestore timestamp from JSON
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp['seconds'] * 1000);
      } else {
        return 'Invalid date';
      }
      
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  void openClientDetails(Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.business, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                client['name'] ?? client['id'],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoRow('Shop Type', client['shopType'] ?? 'N/A'),
              const SizedBox(height: 12),
              const Text(
                'Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              _buildInfoRow('Orders', '${client['stats']?['orders'] ?? 0}'),
              _buildInfoRow('Products', '${client['stats']?['products'] ?? 0}'),
              _buildInfoRow('Purchase Orders', '${client['stats']?['purchaseOrders'] ?? 0}'),
              const SizedBox(height: 12),
              _buildInfoRow('Last Activity', _formatTimestamp(client['stats']?['lastActivity'])),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showEditClientDialog(client);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit'),
          ),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showDeleteClientDialog(client);
            },
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void showCreateClientDialog() {
    final _formKey = GlobalKey<FormState>();
    String name = '', shopType = 'Shopify';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Client'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => name = v ?? '',
              ),
              DropdownButtonFormField<String>(
                value: shopType,
                items: const [
                  DropdownMenuItem(value: 'Shopify', child: Text('Shopify')),
                  DropdownMenuItem(value: 'Etsy', child: Text('Etsy')),
                  DropdownMenuItem(value: 'Amazon', child: Text('Amazon')),
                  DropdownMenuItem(value: 'WooCommerce', child: Text('WooCommerce')),
                ],
                onChanged: (v) => shopType = v ?? 'Shopify',
                decoration: const InputDecoration(labelText: 'Shop Type'),
              ),
            ],
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
                try {
                  await ClientService.createClient(name: name, shopType: shopType);
                  Navigator.pop(context);
                  fetchClients();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void showEditClientDialog(Map<String, dynamic> client) {
    final _formKey = GlobalKey<FormState>();
    String name = client['name'] ?? client['id'];
    String shopType = client['shopType'] ?? 'Shopify';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Client'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                onSaved: (v) => name = v ?? '',
              ),
              DropdownButtonFormField<String>(
                value: shopType,
                items: const [
                  DropdownMenuItem(value: 'Shopify', child: Text('Shopify')),
                  DropdownMenuItem(value: 'Etsy', child: Text('Etsy')),
                  DropdownMenuItem(value: 'Amazon', child: Text('Amazon')),
                  DropdownMenuItem(value: 'WooCommerce', child: Text('WooCommerce')),
                ],
                onChanged: (v) => shopType = v ?? 'Shopify',
                decoration: const InputDecoration(labelText: 'Shop Type'),
              ),
            ],
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
                try {
                  await ClientService.updateClient(
                    id: client['id'],
                    name: name,
                    shopType: shopType,
                  );
                  Navigator.pop(context);
                  fetchClients();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void showDeleteClientDialog(Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${client['name'] ?? client['id']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ClientService.deleteClient(client['id']);
                Navigator.pop(context);
                fetchClients();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchClients,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search Clients',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: filterClients,
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                            const SizedBox(height: 16),
                            Text('Error: $error', style: const TextStyle(fontSize: 16)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: fetchClients,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredClients.isEmpty
                        ? const Center(child: Text('No clients found.'))
                        : ListView.builder(
                            itemCount: filteredClients.length,
                            itemBuilder: (context, i) {
                              final c = filteredClients[i];
                              return ListTile(
                                title: Text(c['name'] ?? c['id']),
                                subtitle: Text('Shop: ${c['shopType'] ?? ''} | Orders: ${c['stats']?['orders'] ?? 0} | Products: ${c['stats']?['products'] ?? 0}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.info_outline),
                                  onPressed: () => openClientDetails(c),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showCreateClientDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
} 