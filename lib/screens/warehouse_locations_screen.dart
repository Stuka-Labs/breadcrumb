import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WarehouseLocationsScreen extends StatelessWidget {
  const WarehouseLocationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warehouse Locations')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('locations').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: \\${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No locations found.'));
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              return ListTile(
                title: Text('Zone: \\${data['zone'] ?? ''} | Shelf: \\${data['shelf'] ?? ''}'),
                subtitle: Text('Bin: \\${data['bin'] ?? ''} | Capacity: \\${data['capacity'] ?? 0} | Stock: \\${data['currentStock'] ?? 0}'),
                trailing: Text(data['status'] ?? ''),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLocationDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLocationDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String zone = '', shelf = '', bin = '', status = 'active';
    int capacity = 0, currentStock = 0;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Location'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Zone'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onSaved: (v) => zone = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Shelf'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onSaved: (v) => shelf = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Bin'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  onSaved: (v) => bin = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Capacity'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || int.tryParse(v) == null ? 'Enter a number' : null,
                  onSaved: (v) => capacity = int.tryParse(v ?? '0') ?? 0,
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Current Stock'),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || int.tryParse(v) == null ? 'Enter a number' : null,
                  onSaved: (v) => currentStock = int.tryParse(v ?? '0') ?? 0,
                ),
                DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                  ],
                  onChanged: (v) => status = v ?? 'active',
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
                  await FirebaseFirestore.instance.collection('locations').add({
                    'zone': zone,
                    'shelf': shelf,
                    'bin': bin,
                    'capacity': capacity,
                    'currentStock': currentStock,
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