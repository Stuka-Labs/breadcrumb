import 'package:flutter/material.dart';

class NewSaleOrderScreen extends StatelessWidget {
  const NewSaleOrderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Sale Order')),
      body: const Center(child: Text('New Sale Order Page')),
    );
  }
} 