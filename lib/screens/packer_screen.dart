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
            _featureGrid(context, [
              _featureTile(context, 'Stock Takes (PV)', Icons.fact_check),
              _featureTile(context, 'Wave Picks (PV)', Icons.waves),
              _featureTile(context, 'Warehouse Locations (PV)', Icons.location_on),
              _featureTile(context, 'Scan Allocate (PV)', Icons.qr_code_scanner),
              _featureTile(context, 'Scan Order (PV)', Icons.qr_code),
            ]),
            const SizedBox(height: 32),
            _sectionHeader('Customer (Packer only)'),
            _featureGrid(context, [
              _featureTile(context, 'Customer', Icons.people),
            ]),
            const SizedBox(height: 32),
            _sectionHeader('Reports'),
            _featureGrid(context, [
              _featureTile(context, 'Stock Movement (PV) (CV)', Icons.swap_horiz),
              _featureTile(context, 'Customer Stock (PV)', Icons.storage),
              _featureTile(context, 'Print Log (PV)', Icons.print),
              _featureTile(context, 'Bulk Pallet Label Printing (PV)', Icons.label),
            ]),
            const SizedBox(height: 32),
            _sectionHeader('Contacts'),
            _featureGrid(context, [
              _featureTile(context, 'Users', Icons.person),
              _featureTile(context, 'Customer', Icons.people_outline),
              _featureTile(context, 'Suppliers', Icons.local_shipping),
              _featureTile(context, 'Drivers', Icons.drive_eta),
              _featureTile(context, 'API Clients', Icons.api),
            ]),
            const SizedBox(height: 32),
            _sectionHeader('More'),
            _featureGrid(context, [
              _featureTile(context, 'Print Log (PV)', Icons.print),
              _featureTile(context, 'Bulk Pallet Label Printing (PV)', Icons.label),
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
    String? route;
    switch (label) {
      case 'New Sale Order':
        route = '/new-sale-order';
        break;
      case 'New Purchase Order':
        route = '/new-purchase-order';
        break;
      default:
        route = null;
    }
    return ElevatedButton.icon(
      onPressed: route != null ? () => Navigator.pushNamed(context, route!) : null,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _featureGrid(BuildContext context, List<Widget> tiles) {
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

  Widget _featureTile(BuildContext context, String label, IconData icon) {
    String? route;
    switch (label) {
      case 'Stock Takes (PV)':
        route = '/stock-takes';
        break;
      case 'Wave Picks (PV)':
        route = '/wave-picks';
        break;
      case 'Warehouse Locations (PV)':
        route = '/warehouse-locations';
        break;
      case 'Scan Allocate (PV)':
        route = '/scan-allocate';
        break;
      case 'Scan Order (PV)':
        route = '/scan-order';
        break;
      case 'Stock Movement (PV) (CV)':
        route = '/stock-movement-report';
        break;
      case 'Customer Stock (PV)':
        route = '/customer-stock-report';
        break;
      case 'Print Log (PV)':
        route = '/print-log';
        break;
      case 'Bulk Pallet Label Printing (PV)':
        route = '/bulk-pallet-label-printing';
        break;
      case 'Users':
        route = '/users';
        break;
      case 'Customer':
        route = '/customer';
        break;
      case 'Suppliers':
        route = '/suppliers';
        break;
      case 'Drivers':
        route = '/drivers';
        break;
      case 'API Clients':
        route = '/api-clients';
        break;
      default:
        route = null;
    }
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: route != null ? () => Navigator.pushNamed(context, route!) : null,
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