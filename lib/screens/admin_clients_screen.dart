import 'package:flutter/material.dart';
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

  void openClientDetails(Map<String, dynamic> client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(client['name'] ?? client['id']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Shop Type: ${client['shopType'] ?? ''}'),
            const SizedBox(height: 8),
            Text('Orders: ${client['stats']?['orders'] ?? 0}'),
            Text('Products: ${client['stats']?['products'] ?? 0}'),
            Text('Purchase Orders: ${client['stats']?['purchaseOrders'] ?? 0}'),
            Text('Last Activity: ${client['stats']?['lastActivity'] ?? ''}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showEditClientDialog(client);
            },
            child: const Text('Edit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              showDeleteClientDialog(client);
            },
            child: const Text('Delete'),
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
                    ? Center(child: Text('Error: $error'))
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