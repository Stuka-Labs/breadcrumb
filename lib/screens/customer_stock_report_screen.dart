import 'package:flutter/material.dart';

class CustomerStockReportScreen extends StatelessWidget {
  const CustomerStockReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Stock (PV) Report')),
      body: const Center(child: Text('Customer Stock (PV) Report Page')),
    );
  }
} 