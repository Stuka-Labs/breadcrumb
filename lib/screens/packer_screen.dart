import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PackerScreen extends StatelessWidget {
  const PackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Packer Portal'),
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
              _featureTile('Stock Takes (PV)', Icons.fact_check),
              _featureTile('Wave Picks (PV)', Icons.waves),
              _featureTile('Warehouse Locations (PV)', Icons.location_on),
              _featureTile('Scan Allocate (PV)', Icons.qr_code_scanner),
              _featureTile('Scan Order (PV)', Icons.qr_code),
            ]),
            const SizedBox(height: 32),
            _sectionHeader('Customer (Packer only)'),
            _featureGrid([
              _featureTile('Customer', Icons.people),
            ]),
            const SizedBox(height: 32),
            _sectionHeader('Reports'),
            _featureGrid([
              _featureTile('Stock Movement (PV)', Icons.swap_horiz),
              _featureTile('Customer Stock (PV)', Icons.storage),
              _featureTile('Print Log (PV)', Icons.print),
              _featureTile('Bulk Pallet Label Printing (PV)', Icons.label),
            ]),
            const SizedBox(height: 32),
            _sectionHeader('Contacts'),
            _featureGrid([
              _featureTile('Users', Icons.person),
              _featureTile('Customer', Icons.people_outline),
              _featureTile('Suppliers', Icons.local_shipping),
              _featureTile('Drivers', Icons.drive_eta),
              _featureTile('API Clients', Icons.api),
            ]),
            const SizedBox(height: 32),
            _sectionHeader('More'),
            _featureGrid([
              _featureTile('Print Log (PV)', Icons.print),
              _featureTile('Bulk Pallet Label Printing (PV)', Icons.label),
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