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