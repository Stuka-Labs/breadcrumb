import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: \\${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          return Column(
            children: [
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance.collection('locations').where('isFilled', isEqualTo: false).get(),
                builder: (context, binSnapshot) {
                  if (!binSnapshot.hasData) return const SizedBox();
                  final availableBins = binSnapshot.data!.docs;
                  if (availableBins.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('No available bins. Please create bins in Warehouse Locations before adding products.', style: TextStyle(color: Colors.red)),
                    );
                  }
                  return Container();
                },
              ),
              Expanded(
                child: docs.isEmpty
                    ? const Center(child: Text('No products found.'))
                    : ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, i) {
                          final data = docs[i].data() as Map<String, dynamic>;
                          final dim = data['dimensions'] ?? {};
                          return ListTile(
                            title: Text(data['name'] ?? ''),
                            subtitle: Text('SKU: \\${data['sku'] ?? ''} | Qty: \\${data['quantity'] ?? 0} | Wt: \\${data['weight'] ?? 0}g | Dim: \\${dim['length'] ?? 0}x\\${dim['width'] ?? 0}x\\${dim['height'] ?? 0}cm | Pack: \\${data['packaging'] ?? ''} | Filler: \\${data['filler'] ?? ''} | Label: \\${data['specialLabel'] ?? ''}'),
                            trailing: Text(data['status'] ?? ''),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FutureBuilder<QuerySnapshot>(
        future: FirebaseFirestore.instance.collection('locations').where('isFilled', isEqualTo: false).get(),
        builder: (context, binSnapshot) {
          if (!binSnapshot.hasData || binSnapshot.data!.docs.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            onPressed: () => _showAddProductDialog(context),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) async {
    final _formKey = GlobalKey<FormState>();
    String name = '', sku = '', status = 'active', packaging = '', filler = '', specialLabel = '', locationId = '', productType = 'General', storageChargeMethod = 'Per Location', productGroup = '', measurementCategory = 'Count', baseMeasurement = 'Unit', stockSelectionMethod = '', stockSubSelectionMethod = 'Minimise Storage', bomFallback = 'As per customer default setting';
    int quantity = 0, weight = 0, length = 0, width = 0, height = 0, warningThreshold = 0, expiryThreshold = 0;
    bool randomWeight = false, lowStockNotification = false;
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
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text('Zone: \\${data['zone']} - Aisle: \\${data['aisle']} - Shelf: \\${data['shelf']} - Bin: \\${data['bin']}'),
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