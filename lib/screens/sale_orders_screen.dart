import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SaleOrdersScreen extends StatelessWidget {
  const SaleOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sale Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('orders').where('type', isEqualTo: 'sale').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: \\${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No sale orders found.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Order #\\${docs[i].id}'),
                subtitle: Text('Status: \\${data['status'] ?? ''} | Customer: \\${data['customerId'] ?? ''}'),
                trailing: Text(data['type'] ?? ''),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSaleOrderDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddSaleOrderDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String customerId = '', status = 'pending';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Sale Order'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Customer ID'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onSaved: (v) => customerId = v ?? '',
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'picked', child: Text('Picked')),
                    DropdownMenuItem(value: 'packed', child: Text('Packed')),
                    DropdownMenuItem(value: 'fulfilled', child: Text('Fulfilled')),
                    DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
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
                  await FirebaseFirestore.instance.collection('orders').add({
                    'type': 'sale',
                    'status': status,
                    'customerId': customerId,
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