import 'package:flutter/material.dart';

class ApiClientsScreen extends StatelessWidget {
  const ApiClientsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Clients')),
      body: const Center(child: Text('API Clients Page')),
    );
  }
} 