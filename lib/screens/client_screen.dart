import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ClientScreen extends StatelessWidget {
  const ClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Quick Add'),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _quickAddButton(context, 'New Sale Order', Icons.add_shopping_cart),
                _quickAddButton(context, 'New Purchase Order', Icons.add_business),
              ],
            ),
            const SizedBox(height: 32),
            _sectionHeader('Warehouse'),
            _featureGrid([
              _featureTile('Products', Icons.inventory),
              _featureTile('Purchase Orders', Icons.shopping_bag),
              _featureTile('Sale Orders', Icons.sell),
            ]),
            const SizedBox(height: 32),
            _sectionHeader('Reports'),
            _featureGrid([
              _featureTile('Purchase Order Report', Icons.assignment),
              _featureTile('Sale Order Report', Icons.assignment_turned_in),
              _featureTile('Stock Movement', Icons.swap_horiz),
              _featureTile('Warning Expiry Stock', Icons.warning),
              _featureTile('Documents', Icons.description),
              _featureTile('Users', Icons.people),
              _featureTile('Settings', Icons.settings_suggest),
            ]),
            const SizedBox(height: 32),
            _sectionHeader('Parse File'),
            _featureGrid([
              _featureTile('Parse File', Icons.insert_drive_file),
            ]),
            const SizedBox(height: 32),
            _sectionHeader('Contacts'),
            _featureGrid([
              _featureTile('Users', Icons.person),
              _featureTile('Customers', Icons.people_outline),
              _featureTile('Suppliers', Icons.local_shipping),
              _featureTile('Drivers', Icons.drive_eta),
              _featureTile('API Clients', Icons.api),
            ]),
            const SizedBox(height: 32),
            _sectionHeader('More'),
            _featureGrid([
              _featureTile('Documents', Icons.description),
              _featureTile('Users', Icons.people),
              _featureTile('Invoices', Icons.receipt_long),
              _featureTile('Self Managed Integration', Icons.integration_instructions),
              _featureTile('Settings', Icons.settings_suggest),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _quickAddButton(BuildContext context, String label, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _featureGrid(List<Widget> tiles) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: tiles,
    );
  }

  Widget _featureTile(String label, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.deepPurple),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 