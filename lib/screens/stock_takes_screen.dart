import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StockTakesScreen extends StatelessWidget {
  const StockTakesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Takes')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('stockTakes').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: \\${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No stock takes found.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Stock Take #\\${docs[i].id}'),
                subtitle: Text('Status: \\${data['status'] ?? ''} | Created By: \\${data['createdBy'] ?? ''}'),
                trailing: Text(data['status'] ?? ''),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStockTakeDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddStockTakeDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String createdBy = '', status = 'in_progress';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Stock Take'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Created By (User ID)'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onSaved: (v) => createdBy = v ?? '',
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                    DropdownMenuItem(value: 'reviewed', child: Text('Reviewed')),
                  ],
                  onChanged: (v) => status = v ?? 'in_progress',
                  decoration: const InputDecoration(labelText: 'Status'),
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
                  await FirebaseFirestore.instance.collection('stockTakes').add({
                    'createdBy': createdBy,
                    'status': status,
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
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

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  String searchText = '';
  String measure = 'All';
  String type = 'All';
  bool showOutOfStock = false;
  List<Map<String, dynamic>> products = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    setState(() => loading = true);
    final snapshot = await FirebaseFirestore.instance.collection('products').get();
    products = snapshot.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    setState(() => loading = false);
  }

  List<Map<String, dynamic>> get filteredProducts {
    var filtered = products.where((p) {
      final matchesText = searchText.isEmpty || (p['name'] ?? '').toString().toLowerCase().contains(searchText.toLowerCase()) || (p['sku'] ?? '').toString().toLowerCase().contains(searchText.toLowerCase());
      final matchesMeasure = measure == 'All' || (p['baseMeasurement'] ?? '') == measure;
      final matchesType = type == 'All' || (p['productType'] ?? '') == type;
      final matchesStock = !showOutOfStock || (p['quantity'] ?? 0) == 0;
      return matchesText && matchesMeasure && matchesType && matchesStock;
    }).toList();
    return filtered;
  }

  void exportCSV() {
    // TODO: Implement CSV export logic
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exported CSV (not implemented)')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stock Report'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: fetchProducts),
        IconButton(icon: const Icon(Icons.download), onPressed: exportCSV),
      ]),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Search Text'),
                          onChanged: (v) => setState(() => searchText = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: measure,
                        items: ['All', 'Unit', 'Carton', 'Inner'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (v) => setState(() => measure = v ?? 'All'),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: type,
                        items: ['All', 'General', 'Random Weight'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (v) => setState(() => type = v ?? 'All'),
                      ),
                      const SizedBox(width: 8),
                      Checkbox(
                        value: showOutOfStock,
                        onChanged: (v) => setState(() => showOutOfStock = v ?? false),
                      ),
                      const Text('Show Out of Stock'),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Code')),
                        DataColumn(label: Text('Product Name')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('UOM')),
                        DataColumn(label: Text('In Warehouse')),
                        DataColumn(label: Text('Free')),
                        DataColumn(label: Text('Incoming')),
                      ],
                      rows: filteredProducts.map((p) => DataRow(cells: [
                        DataCell(Text(p['sku'] ?? '')),
                        DataCell(Text(p['name'] ?? '')),
                        DataCell(Text(p['status'] ?? '')),
                        DataCell(Text(p['baseMeasurement'] ?? '')),
                        DataCell(Text('${p['quantity'] ?? 0}')),
                        DataCell(Text('${p['free'] ?? 0}')),
                        DataCell(Text('${p['incoming'] ?? 0}')),
                      ])).toList(),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
} 