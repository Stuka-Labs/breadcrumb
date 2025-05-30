import 'package:flutter/material.dart';

class NewPurchaseOrderScreen extends StatelessWidget {
  const NewPurchaseOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Purchase Order')),
      body: const Center(child: Text('New Purchase Order Page')),
    );
  }
} 