import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PackerOrdersScreen extends StatefulWidget {
  const PackerOrdersScreen({super.key});

  @override
  State<PackerOrdersScreen> createState() => _PackerOrdersScreenState();
}

class _PackerOrdersScreenState extends State<PackerOrdersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Fulfill Sale Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('type', isEqualTo: 'sale')
            .where('status', isNotEqualTo: 'fulfilled')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: \\${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No sale orders to fulfill.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final order = docs[i].data() as Map<String, dynamic>;
              final orderId = docs[i].id;
              final products = order['products'] as List<dynamic>? ?? [];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ExpansionTile(
                  title: Text('Order #$orderId'),
                  subtitle: Text('Status: ${order['status']}'),
                  children: products.map((prod) => _productTile(prod, orderId)).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _productTile(Map<String, dynamic> prod, String orderId) {
    final prodName = prod['name'] ?? '';
    final prodSku = prod['sku'] ?? '';
    final prodLabel = prod['specialLabel'] ?? '';
    final prodPackaging = prod['packaging'] ?? '';
    final prodFiller = prod['filler'] ?? '';
    final prodLocation = prod['locationId'] ?? '';
    final prodStatus = prod['status'] ?? '';
    final barcode = prod['sku'] ?? '';
    TextEditingController barcodeController = TextEditingController();
    return ListTile(
      title: Text(prodName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SKU: $prodSku'),
          Text('Location: $prodLocation'),
          Text('Packaging: $prodPackaging | Filler: $prodFiller'),
          if (prodLabel.isNotEmpty) Text('Special Label: $prodLabel'),
          Text('Status: $prodStatus'),
        ],
      ),
      trailing: prodStatus == 'fulfilled'
          ? const Icon(Icons.check_circle, color: Colors.green)
          : IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              tooltip: 'Scan/Enter Barcode',
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Scan or Enter Barcode'),
                    content: TextField(
                      controller: barcodeController,
                      autofocus: true,
                      decoration: const InputDecoration(hintText: 'Enter or scan barcode'),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          if (barcodeController.text.trim() == barcode) {
                            // Mark product as fulfilled in order
                            await _fulfillProduct(orderId, prodSku);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Product $prodName fulfilled!')),
                            );
                            setState(() {});
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Barcode does not match!')),
                            );
                          }
                        },
                        child: const Text('Confirm'),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Future<void> _fulfillProduct(String orderId, String prodSku) async {
    final orderRef = FirebaseFirestore.instance.collection('orders').doc(orderId);
    final orderSnap = await orderRef.get();
    final order = orderSnap.data() as Map<String, dynamic>?;
    if (order == null) return;
    final products = (order['products'] as List<dynamic>).map((e) => Map<String, dynamic>.from(e)).toList();
    for (var prod in products) {
      if (prod['sku'] == prodSku) {
        prod['status'] = 'fulfilled';
      }
    }
    // If all products fulfilled, mark order as fulfilled
    final allFulfilled = products.every((p) => p['status'] == 'fulfilled');
    await orderRef.update({
      'products': products,
      if (allFulfilled) 'status': 'fulfilled',
    });
  }
} 