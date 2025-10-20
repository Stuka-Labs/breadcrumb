import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  String clientName = '', clientEmail = '', defaultPackaging = '', defaultFiller = '', defaultLabel = '';
  List<Map<String, dynamic>> products = [];

  // Product fields
  String prodName = '', prodSku = '', prodPackaging = '', prodFiller = '', prodLabel = '', prodLocationId = '';
  int prodWeight = 0, prodLength = 0, prodWidth = 0, prodHeight = 0, prodQty = 0;

  void _addProduct() {
    setState(() {
      products.add({
        'name': prodName,
        'sku': prodSku,
        'quantity': prodQty,
        'weight': prodWeight,
        'dimensions': {'length': prodLength, 'width': prodWidth, 'height': prodHeight},
        'packaging': prodPackaging.isNotEmpty ? prodPackaging : defaultPackaging,
        'filler': prodFiller.isNotEmpty ? prodFiller : defaultFiller,
        'specialLabel': prodLabel.isNotEmpty ? prodLabel : defaultLabel,
        'locationId': prodLocationId,
        'status': 'active',
      });
      prodName = prodSku = prodPackaging = prodFiller = prodLabel = prodLocationId = '';
      prodWeight = prodLength = prodWidth = prodHeight = prodQty = 0;
    });
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && products.isNotEmpty) {
      _formKey.currentState!.save();
      final clientRef = await FirebaseFirestore.instance.collection('clients').add({
        'name': clientName,
        'email': clientEmail,
        'defaultPackaging': defaultPackaging,
        'defaultFiller': defaultFiller,
        'defaultLabel': defaultLabel,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      for (final prod in products) {
        await FirebaseFirestore.instance.collection('products').add({
          ...prod,
          'clientId': clientRef.id,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboard New Client')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Client Info', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Client Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => clientName = v ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Client Email'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => clientEmail = v ?? '',
                  ),
                  const SizedBox(height: 12),
                  const Text('Default Product Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Default Packaging'),
                    onSaved: (v) => defaultPackaging = v ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Default Filler'),
                    onSaved: (v) => defaultFiller = v ?? '',
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Default Special Label'),
                    onSaved: (v) => defaultLabel = v ?? '',
                  ),
                  const SizedBox(height: 18),
                  ExpansionTile(
                    title: const Text('Add Products', style: TextStyle(fontWeight: FontWeight.bold)),
                    children: [
                      _productInputFields(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add Product'),
                          onPressed: _addProduct,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (products.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Products to Onboard:', style: TextStyle(fontWeight: FontWeight.bold)),
                        ...products.map((p) => ListTile(
                          title: Text(p['name'] ?? ''),
                          subtitle: Text('SKU: ${p['sku']}, Qty: ${p['quantity']}, Wt: ${p['weight']}g, Dim: ${p['dimensions']['length']}x${p['dimensions']['width']}x${p['dimensions']['height']}cm'),
                        )),
                      ],
                    ),
                  const SizedBox(height: 18),
                  Center(
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Submit Onboarding'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _productInputFields() {
    return Column(
      children: [
        TextFormField(
          decoration: const InputDecoration(labelText: 'Product Name'),
          onChanged: (v) => prodName = v,
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'SKU'),
          onChanged: (v) => prodSku = v,
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Quantity'),
          keyboardType: TextInputType.number,
          onChanged: (v) => prodQty = int.tryParse(v) ?? 0,
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Weight (g)'),
          keyboardType: TextInputType.number,
          onChanged: (v) => prodWeight = int.tryParse(v) ?? 0,
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Length (cm)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => prodLength = int.tryParse(v) ?? 0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Width (cm)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => prodWidth = int.tryParse(v) ?? 0,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => prodHeight = int.tryParse(v) ?? 0,
              ),
            ),
          ],
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Packaging Type'),
          onChanged: (v) => prodPackaging = v,
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Filler Type'),
          onChanged: (v) => prodFiller = v,
        ),
        TextFormField(
          decoration: const InputDecoration(labelText: 'Special Label'),
          onChanged: (v) => prodLabel = v,
        ),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('locations').get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final locations = snapshot.data!.docs;
            return DropdownButtonFormField<String>(
              value: prodLocationId.isNotEmpty ? prodLocationId : null,
              items: locations.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text('${data['zone'] ?? ''}-${data['shelf'] ?? ''}-${data['bin'] ?? ''}'),
                );
              }).toList(),
              onChanged: (v) => prodLocationId = v ?? '',
              decoration: const InputDecoration(labelText: 'Default Location'),
            );
          },
        ),
      ],
    );
  }
} 