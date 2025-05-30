import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'signup_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () async {
              await AuthService().signOut();
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
            // Quick Add Section
            _sectionHeader('Quick Add'),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _quickAddButton(context, 'New Sale Order', Icons.add_shopping_cart),
                _quickAddButton(context, 'New Purchase Order', Icons.add_business),
                _quickAddButton(
                  context,
                  'Create New Account',
                  Icons.person_add,
                  onPressed: () async {
                    await AuthService().signOut();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpScreen(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Warehouse Section
            _sectionHeader('Warehouse'),
            _featureGrid(context, [
              _featureTile(context, 'Products (CV)', Icons.inventory),
              _featureTile(context, 'Purchase Orders (CV)', Icons.shopping_bag),
              _featureTile(context, 'Sale Orders (CV)', Icons.sell),
              _featureTile(context, 'Stock Takes (PV)', Icons.fact_check),
              _featureTile(context, 'Wave Picks (PV)', Icons.waves),
              _featureTile(context, 'Warehouse Locations (PV)', Icons.location_on),
              _featureTile(context, 'Scan Allocate (PV)', Icons.qr_code_scanner),
              _featureTile(context, 'Scan Order (PV)', Icons.qr_code),
            ]),
            const SizedBox(height: 32),
            // Customer (Packer only)
            _sectionHeader('Customer (Packer only)'),
            _featureGrid(context, [
              _featureTile(context, 'Customer', Icons.people),
            ]),
            const SizedBox(height: 32),
            // Reports Section
            _sectionHeader('Reports'),
            _featureGrid(context, [
              _featureTile(context, 'Discrepancy Reports', Icons.report_problem),
              _featureTile(context, 'Purchase Order (CV)', Icons.assignment),
              _featureTile(context, 'Sale Order (CV)', Icons.assignment_turned_in),
              _featureTile(context, 'Stock Movement (PV) (CV)', Icons.swap_horiz),
              _featureTile(context, 'Customer Stock (PV)', Icons.storage),
              _featureTile(context, 'Bulk Export Purchase', Icons.file_upload),
              _featureTile(context, 'Warning Expiry Stock Report (CV)', Icons.warning),
              _featureTile(context, 'Bulk Export Sale', Icons.file_upload_outlined),
              _featureTile(context, 'Stats', Icons.bar_chart),
              _featureTile(context, 'Automation', Icons.settings_remote),
              _featureTile(context, 'Usda e', Icons.eco),
              _featureTile(context, 'Bulk Export', Icons.cloud_upload),
              _featureTile(context, 'API Client Usage', Icons.api),
            ]),
            const SizedBox(height: 32),
            // Parse File
            _sectionHeader('Parse File (CV)'),
            _featureGrid(context, [
              _featureTile(context, 'Parse File', Icons.insert_drive_file),
            ]),
            const SizedBox(height: 32),
            // Contacts
            _sectionHeader('Contacts'),
            _featureGrid(context, [
              _featureTile(context, 'Users', Icons.person),
              _featureTile(context, 'Customer', Icons.people_outline),
              _featureTile(context, 'Suppliers', Icons.local_shipping),
              _featureTile(context, 'Drivers', Icons.drive_eta),
              _featureTile(context, 'API Clients', Icons.api),
            ]),
            const SizedBox(height: 32),
            // More
            _sectionHeader('More'),
            _featureGrid(context, [
              _featureTile(context, 'Addresses', Icons.home),
              _featureTile(context, 'Product Settings', Icons.settings),
              _featureTile(context, 'Documents (CV)', Icons.description),
              _featureTile(context, 'Users (CV)', Icons.people),
              _featureTile(context, 'Cash on Delivery', Icons.attach_money),
              _featureTile(context, 'Invoices (CV)', Icons.receipt_long),
              _featureTile(context, 'Bills', Icons.receipt),
              _featureTile(context, 'Rate Cards', Icons.credit_card),
              _featureTile(context, 'Warehouse Settings', Icons.settings_applications),
              _featureTile(context, 'Organisation Settings', Icons.business),
              _featureTile(context, 'Parse a File', Icons.file_present),
              _featureTile(context, 'Self Managed Integration (CV)', Icons.integration_instructions),
              _featureTile(context, 'Bolt Log', Icons.bolt),
              _featureTile(context, 'Settings (CV)', Icons.settings_suggest),
              _featureTile(context, 'Import Log', Icons.import_export),
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

  Widget _quickAddButton(BuildContext context, String label, IconData icon, {VoidCallback? onPressed}) {
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
      onPressed: onPressed ?? (route != null ? () => Navigator.pushNamed(context, route!) : null),
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
      case 'Products (CV)':
        route = '/products';
        break;
      case 'Purchase Orders (CV)':
        route = '/purchase-orders';
        break;
      case 'Sale Orders (CV)':
        route = '/sale-orders';
        break;
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
      case 'Customer':
        route = '/customer';
        break;
      case 'Discrepancy Reports':
        route = '/discrepancy-reports';
        break;
      case 'Purchase Order (CV)':
        route = '/purchase-order-report';
        break;
      case 'Sale Order (CV)':
        route = '/sale-order-report';
        break;
      case 'Stock Movement (PV) (CV)':
        route = '/stock-movement-report';
        break;
      case 'Customer Stock (PV)':
        route = '/customer-stock-report';
        break;
      case 'Bulk Export Purchase':
        route = '/bulk-export-purchase';
        break;
      case 'Warning Expiry Stock Report (CV)':
        route = '/warning-expiry-stock-report';
        break;
      case 'Bulk Export Sale':
        route = '/bulk-export-sale';
        break;
      case 'Stats':
        route = '/stats';
        break;
      case 'Automation':
        route = '/automation';
        break;
      case 'Usda e':
        route = '/usda-e';
        break;
      case 'Bulk Export':
        route = '/bulk-export';
        break;
      case 'API Client Usage':
        route = '/api-client-usage';
        break;
      case 'Parse File':
        route = '/parse-file';
        break;
      case 'Users':
        route = '/users';
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
      case 'Addresses':
        route = '/addresses';
        break;
      case 'Product Settings':
        route = '/product-settings';
        break;
      case 'Documents (CV)':
        route = '/documents';
        break;
      case 'Users (CV)':
        route = '/users-cv';
        break;
      case 'Cash on Delivery':
        route = '/cash-on-delivery';
        break;
      case 'Invoices (CV)':
        route = '/invoices';
        break;
      case 'Bills':
        route = '/bills';
        break;
      case 'Rate Cards':
        route = '/rate-cards';
        break;
      case 'Warehouse Settings':
        route = '/warehouse-settings';
        break;
      case 'Organisation Settings':
        route = '/organisation-settings';
        break;
      case 'Parse a File':
        route = '/parse-a-file';
        break;
      case 'Self Managed Integration (CV)':
        route = '/self-managed-integration';
        break;
      case 'Bolt Log':
        route = '/bolt-log';
        break;
      case 'Settings (CV)':
        route = '/settings-cv';
        break;
      case 'Import Log':
        route = '/import-log';
        break;
      case 'Print Log (PV)':
        route = '/print-log';
        break;
      case 'Bulk Pallet Label Printing (PV)':
        route = '/bulk-pallet-label-printing';
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