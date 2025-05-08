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
            _featureGrid([
              _featureTile('Products (CV)', Icons.inventory),
              _featureTile('Purchase Orders (CV)', Icons.shopping_bag),
              _featureTile('Sale Orders (CV)', Icons.sell),
              _featureTile('Stock Takes (PV)', Icons.fact_check),
              _featureTile('Wave Picks (PV)', Icons.waves),
              _featureTile('Warehouse Locations (PV)', Icons.location_on),
              _featureTile('Scan Allocate (PV)', Icons.qr_code_scanner),
              _featureTile('Scan Order (PV)', Icons.qr_code),
            ]),
            const SizedBox(height: 32),
            // Customer (Packer only)
            _sectionHeader('Customer (Packer only)'),
            _featureGrid([
              _featureTile('Customer', Icons.people),
            ]),
            const SizedBox(height: 32),
            // Reports Section
            _sectionHeader('Reports'),
            _featureGrid([
              _featureTile('Discrepancy Reports', Icons.report_problem),
              _featureTile('Purchase Order (CV)', Icons.assignment),
              _featureTile('Sale Order (CV)', Icons.assignment_turned_in),
              _featureTile('Stock Movement (PV) (CV)', Icons.swap_horiz),
              _featureTile('Customer Stock (PV)', Icons.storage),
              _featureTile('Bulk Export Purchase', Icons.file_upload),
              _featureTile('Warning Expiry Stock Report (CV)', Icons.warning),
              _featureTile('Bulk Export Sale', Icons.file_upload_outlined),
              _featureTile('Stats', Icons.bar_chart),
              _featureTile('Automation', Icons.settings_remote),
              _featureTile('Usda e', Icons.eco),
              _featureTile('Bulk Export', Icons.cloud_upload),
              _featureTile('API Client Usage', Icons.api),
            ]),
            const SizedBox(height: 32),
            // Parse File
            _sectionHeader('Parse File (CV)'),
            _featureGrid([
              _featureTile('Parse File', Icons.insert_drive_file),
            ]),
            const SizedBox(height: 32),
            // Contacts
            _sectionHeader('Contacts'),
            _featureGrid([
              _featureTile('Users', Icons.person),
              _featureTile('Customer', Icons.people_outline),
              _featureTile('Suppliers', Icons.local_shipping),
              _featureTile('Drivers', Icons.drive_eta),
              _featureTile('API Clients', Icons.api),
            ]),
            const SizedBox(height: 32),
            // More
            _sectionHeader('More'),
            _featureGrid([
              _featureTile('Addresses', Icons.home),
              _featureTile('Product Settings', Icons.settings),
              _featureTile('Documents (CV)', Icons.description),
              _featureTile('Users (CV)', Icons.people),
              _featureTile('Cash on Delivery', Icons.attach_money),
              _featureTile('Invoices (CV)', Icons.receipt_long),
              _featureTile('Bills', Icons.receipt),
              _featureTile('Rate Cards', Icons.credit_card),
              _featureTile('Warehouse Settings', Icons.settings_applications),
              _featureTile('Organisation Settings', Icons.business),
              _featureTile('Parse a File', Icons.file_present),
              _featureTile('Self Managed Integration (CV)', Icons.integration_instructions),
              _featureTile('Bolt Log', Icons.bolt),
              _featureTile('Settings (CV)', Icons.settings_suggest),
              _featureTile('Import Log', Icons.import_export),
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

  Widget _quickAddButton(BuildContext context, String label, IconData icon, {VoidCallback? onPressed}) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
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