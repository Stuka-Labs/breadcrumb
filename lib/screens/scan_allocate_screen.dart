import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanAllocateScreen extends StatelessWidget {
  const ScanAllocateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan Allocate')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('scanAllocates').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: \\${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No scan allocations found.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Product: \\${data['productId'] ?? ''}'),
                subtitle: Text('Allocated To: \\${data['allocatedTo'] ?? ''}'),
                trailing: Text(data['status'] ?? ''),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddScanAllocateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddScanAllocateDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String productId = '', allocatedTo = '', status = 'pending';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Scan Allocation'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Product ID'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onSaved: (v) => productId = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Allocated To (User ID)'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onSaved: (v) => allocatedTo = v ?? '',
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'allocated', child: Text('Allocated')),
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
                  await FirebaseFirestore.instance.collection('scanAllocates').add({
                    'productId': productId,
                    'allocatedTo': allocatedTo,
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