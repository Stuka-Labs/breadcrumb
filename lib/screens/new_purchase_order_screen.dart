import 'package:flutter/material.dart';
import '../services/purchase_order_service.dart';
import '../services/client_service.dart';
import '../services/product_service.dart';

class NewPurchaseOrderScreen extends StatefulWidget {
  const NewPurchaseOrderScreen({super.key});

  @override
  State<NewPurchaseOrderScreen> createState() => _NewPurchaseOrderScreenState();
}

class _NewPurchaseOrderScreenState extends State<NewPurchaseOrderScreen> {
  String? selectedClientId;
  List<dynamic> clients = [];
  List<dynamic> products = [];
  List<dynamic> filteredProducts = [];
  Map<String, int> selectedProducts = {};
  bool loading = false;
  String? error;
  final TextEditingController _searchController = TextEditingController();
  // Advanced fields
  DateTime? arrivalDate;
  String customerReference = '';
  String specialInstruction = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchData() async {
    setState(() => loading = true);
    try {
      final c = await ClientService.fetchClients();
      final p = await ProductService.fetchProducts();
      // Only products with a bin assigned
      final filtered = p.where((prod) => prod['locationId'] != null && prod['locationId'].toString().isNotEmpty).toList();
      setState(() {
        clients = c;
        products = filtered;
        filteredProducts = filtered;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  void filterProducts(String query) {
    setState(() {
      filteredProducts = products.where((p) => (p['name'] ?? p['id']).toString().toLowerCase().contains(query.toLowerCase())).toList();
    });
  }

  void submit() async {
    if (selectedClientId == null || selectedProducts.isEmpty) return;
    setState(() => loading = true);
    try {
      final items = selectedProducts.entries
          .map((e) => {'productId': e.key, 'quantity': e.value})
          .toList();
      await PurchaseOrderService.createPurchaseOrder(
        clientId: selectedClientId!,
        items: items,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Purchase Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchData,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text('Error: $error'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedClientId,
                            items: clients
                                .map<DropdownMenuItem<String>>((c) => DropdownMenuItem(
                                      value: c['id'],
                                      child: Text(c['name'] ?? c['id']),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => selectedClientId = v),
                            decoration: const InputDecoration(labelText: 'Select Client'),
                          ),
                          const SizedBox(height: 16),
                          // Arrival Date
                          Row(
                            children: [
                              const Text('Arrival Date: '),
                              Text(arrivalDate == null ? 'Not set' : arrivalDate!.toLocal().toString().split(' ')[0]),
                              IconButton(
                                icon: const Icon(Icons.calendar_today),
                                onPressed: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: arrivalDate ?? DateTime.now(),
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) setState(() => arrivalDate = picked);
                                },
                              ),
                            ],
                          ),
                          TextField(
                            decoration: const InputDecoration(labelText: 'Customer reference'),
                            onChanged: (v) => customerReference = v,
                          ),
                          TextField(
                            decoration: const InputDecoration(labelText: 'Special Instruction'),
                            onChanged: (v) => specialInstruction = v,
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              labelText: 'Search Products',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                            ),
                            onChanged: filterProducts,
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('Select Products and Quantities:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, i) {
                          final p = filteredProducts[i];
                          return ListTile(
                            title: Text(p['name'] ?? p['id']),
                            subtitle: Text('SKU: ${p['sku'] ?? ''}'),
                            trailing: SizedBox(
                              width: 100,
                              child: TextFormField(
                                initialValue: selectedProducts[p['id']]?.toString() ?? '',
                                decoration: const InputDecoration(labelText: 'Qty'),
                                keyboardType: TextInputType.number,
                                onChanged: (v) {
                                  final qty = int.tryParse(v) ?? 0;
                                  setState(() {
                                    if (qty > 0) {
                                      selectedProducts[p['id']] = qty;
                                    } else {
                                      selectedProducts.remove(p['id']);
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (selectedProducts.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16.0),
                        color: Colors.grey[200],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selected Products:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ...selectedProducts.entries.map((e) {
                              final p = products.firstWhere((p) => p['id'] == e.key, orElse: () => {'name': e.key});
                              return Text('${p['name'] ?? p['id']}: ${e.value}');
                            }),
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: selectedClientId != null && selectedProducts.isNotEmpty && !loading ? submit : null,
                            child: const Text('Create Purchase Order'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
} 