import 'package:flutter/material.dart';

class OrganisationSettingsScreen extends StatelessWidget {
  const OrganisationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Organisation Settings')),
      body: const Center(child: Text('Organisation Settings Page')),
    );
  }
} 