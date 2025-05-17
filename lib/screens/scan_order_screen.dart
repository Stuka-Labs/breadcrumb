import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanOrderScreen extends StatelessWidget {
  const ScanOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Order')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('scanOrders').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: \\${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No scan orders found.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Order: \\${data['orderId'] ?? ''}'),
                subtitle: Text('Scanned By: \\${data['scannedBy'] ?? ''}'),
                trailing: Text(data['status'] ?? ''),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddScanOrderDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddScanOrderDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String orderId = '', scannedBy = '', status = 'pending';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Scan Order'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Order ID'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onSaved: (v) => orderId = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Scanned By (User ID)'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onSaved: (v) => scannedBy = v ?? '',
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'scanned', child: Text('Scanned')),
                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  ],
                  onChanged: (v) => status = v ?? 'pending',
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
                  await FirebaseFirestore.instance.collection('scanOrders').add({
                    'orderId': orderId,
                    'scannedBy': scannedBy,
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