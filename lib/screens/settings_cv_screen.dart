import 'package:flutter/material.dart';

class SettingsCVScreen extends StatelessWidget {
  const SettingsCVScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings (CV)')),
      body: const Center(child: Text('Settings (CV) Page')),
    );
  }
} 