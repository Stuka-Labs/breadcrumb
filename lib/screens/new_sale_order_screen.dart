import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class NewSaleOrderScreen extends StatefulWidget {
  const NewSaleOrderScreen({super.key});

  @override
  State<NewSaleOrderScreen> createState() => _NewSaleOrderScreenState();
}

class _NewSaleOrderScreenState extends State<NewSaleOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  String reference = '';
  String? selectedAddress;
  bool pickupFromWarehouse = false;
  List<Map<String, dynamic>> addresses = [];
  String newCompany = '', newCustomer = '', newStreet = '', newUnit = '', newSuburb = '', newCity = '', newPostcode = '', newState = '';
  File? invoiceFile;
  String? invoiceFileName;
  String? invoiceUrl;
  bool showAdvanced = false;
  // Advanced fields
  String specialInstructions = '';
  String deliveryDate = '';
  String deliveryContact = '';
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    fetchAddresses();
  }

  Future<void> fetchAddresses() async {
    // TODO: Replace with Firestore query to get addresses for the current client/shopify order
    // For now, just use a placeholder
    final snapshot = await FirebaseFirestore.instance.collection('addresses').get();
    setState(() {
      addresses = snapshot.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    });
  }

  Future<void> _pickInvoice() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);
    if (result != null && result.files.single.path != null) {
      setState(() {
        invoiceFile = File(result.files.single.path!);
        invoiceFileName = result.files.single.name;
      });
    }
  }

  Future<String?> _uploadInvoice() async {
    if (invoiceFile == null) return null;
    final ref = FirebaseStorage.instance.ref().child('invoices/${DateTime.now().millisecondsSinceEpoch}_$invoiceFileName');
    final uploadTask = ref.putFile(invoiceFile!);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  void _addNewAddress() async {
    if (newCompany.isNotEmpty && newCustomer.isNotEmpty && newStreet.isNotEmpty && newCity.isNotEmpty && newPostcode.isNotEmpty && newState.isNotEmpty) {
      final newAddr = {
        'company': newCompany,
        'customer': newCustomer,
        'street': newStreet,
        'unit': newUnit,
        'suburb': newSuburb,
        'city': newCity,
        'postcode': newPostcode,
        'state': newState,
      };
      final doc = await FirebaseFirestore.instance.collection('addresses').add(newAddr);
      setState(() {
        addresses.add(newAddr);
        selectedAddress = doc.id;
        newCompany = newCustomer = newStreet = newUnit = newSuburb = newCity = newPostcode = newState = '';
      });
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => submitting = true);
    _formKey.currentState!.save();
    String? uploadedInvoiceUrl;
    if (invoiceFile != null) {
      uploadedInvoiceUrl = await _uploadInvoice();
    }
    await FirebaseFirestore.instance.collection('saleOrders').add({
      'reference': reference,
      'deliveryAddress': pickupFromWarehouse ? 'PICKUP' : selectedAddress,
      'pickupFromWarehouse': pickupFromWarehouse,
      'specialInstructions': specialInstructions,
      'deliveryDate': deliveryDate,
      'deliveryContact': deliveryContact,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'open',
      'invoiceUrl': uploadedInvoiceUrl,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Sale Order')),
      body: submitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Reference', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextFormField(
                      decoration: const InputDecoration(hintText: 'Enter reference or Invoice Number'),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      onSaved: (v) => reference = v ?? '',
                    ),
                    const SizedBox(height: 24),
                    const Text('Delivery Address:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<String>(
                      value: pickupFromWarehouse ? null : (selectedAddress ?? (addresses.isNotEmpty ? (addresses.first['id'] ?? '') : '')),
                      items: addresses.map((a) => DropdownMenuItem<String>(
                        value: (a['id'] ?? '').toString(),
                        child: Text('${a['company'] ?? ''}, ${a['street'] ?? ''}, ${a['city'] ?? ''}'),
                      )).toList(),
                      onChanged: pickupFromWarehouse ? null : (v) => setState(() => selectedAddress = v),
                      decoration: const InputDecoration(hintText: 'Search for an address'),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: pickupFromWarehouse,
                          onChanged: (v) => setState(() {
                            pickupFromWarehouse = v ?? false;
                            if (pickupFromWarehouse) selectedAddress = null;
                          }),
                        ),
                        const Text('Order will be picked up from Warehouse'),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Address Not Listed?'),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Add New Delivery Address'),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Add Address'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextFormField(
                                        decoration: const InputDecoration(labelText: 'Company name'),
                                        onChanged: (v) => newCompany = v,
                                      ),
                                      TextFormField(
                                        decoration: const InputDecoration(labelText: 'Customer name'),
                                        onChanged: (v) => newCustomer = v,
                                      ),
                                      TextFormField(
                                        decoration: const InputDecoration(labelText: 'Street address'),
                                        onChanged: (v) => newStreet = v,
                                      ),
                                      TextFormField(
                                        decoration: const InputDecoration(labelText: 'Unit, Apartment, Suite (optional)'),
                                        onChanged: (v) => newUnit = v,
                                      ),
                                      TextFormField(
                                        decoration: const InputDecoration(labelText: 'Suburb'),
                                        onChanged: (v) => newSuburb = v,
                                      ),
                                      TextFormField(
                                        decoration: const InputDecoration(labelText: 'City'),
                                        onChanged: (v) => newCity = v,
                                      ),
                                      TextFormField(
                                        decoration: const InputDecoration(labelText: 'Postcode'),
                                        onChanged: (v) => newPostcode = v,
                                      ),
                                      TextFormField(
                                        decoration: const InputDecoration(labelText: 'State'),
                                        onChanged: (v) => newState = v,
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                                  ElevatedButton(onPressed: _addNewAddress, child: const Text('Add')),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _pickInvoice,
                      child: Text(invoiceFile == null ? 'Attach Invoice' : 'Invoice Attached'),
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: const Text('Advanced Options'),
                      initiallyExpanded: showAdvanced,
                      onExpansionChanged: (v) => setState(() => showAdvanced = v),
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Special Instructions'),
                          onSaved: (v) => specialInstructions = v ?? '',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Delivery Date (optional)'),
                          onSaved: (v) => deliveryDate = v ?? '',
                        ),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Delivery Contact (optional)'),
                          onSaved: (v) => deliveryContact = v ?? '',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('Add Sale Order'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 