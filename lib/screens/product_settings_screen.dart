import 'package:flutter/material.dart';

class ProductSettingsScreen extends StatelessWidget {
  const ProductSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Product Settings')),
      body: const Center(child: Text('Product Settings Page')),
    );
  }
} 