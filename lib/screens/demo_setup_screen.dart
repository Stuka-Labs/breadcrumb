import 'package:flutter/material.dart';
import '../services/test_user_service.dart';
import '../services/auth_service.dart';
import '../constants/theme.dart';

class DemoSetupScreen extends StatefulWidget {
  const DemoSetupScreen({super.key});

  @override
  State<DemoSetupScreen> createState() => _DemoSetupScreenState();
}

class _DemoSetupScreenState extends State<DemoSetupScreen> {
  bool _isLoading = false;
  bool _testUserExists = false;
  Map<String, dynamic>? _testUserInfo;

  @override
  void initState() {
    super.initState();
    _loadTestUserInfo();
  }

  Future<void> _loadTestUserInfo() async {
    setState(() => _isLoading = true);
    
    try {
      final info = await TestUserService.getTestUserInfo();
      final exists = await TestUserService.testUserExists();
      
      setState(() {
        _testUserInfo = info;
        _testUserExists = exists;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading test user info: $e')),
        );
      }
    }
  }

  Future<void> _createTestUser() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await TestUserService.createTestUser();
      
      if (result['success'] == true) {
        setState(() => _testUserExists = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Test user created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create test user: ${result['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating test user: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInAsTestUser() async {
    if (_testUserInfo == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      final authService = AuthService();
      await authService.signInWithEmailAndPassword(
        _testUserInfo!['email'],
        _testUserInfo!['password'],
      );
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/client');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WMS Demo Setup'),
        backgroundColor: kBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildTestUserCard(),
                  const SizedBox(height: 24),
                  _buildFeaturesSection(),
                  const SizedBox(height: 24),
                  _buildSampleDataSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: kPastelOrange, size: 32),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'WMS Demonstration Setup',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'This demo showcases the complete Breadcrumb WMS functionality with realistic sample data. '
              'The test user includes shop integrations, products, orders, analytics, and warehouse management features.',
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestUserCard() {
    if (_testUserInfo == null) return const SizedBox.shrink();
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _testUserExists ? Icons.check_circle : Icons.person_add,
                  color: _testUserExists ? Colors.green : kPastelOrange,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _testUserExists ? 'Test User Ready' : 'Demo Test User',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _testUserInfo!['email'],
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kPastelOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kPastelOrange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Demo Credentials:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Email: ${_testUserInfo!['email']}'),
                  Text('Password: ${_testUserInfo!['password']}'),
                  Text('Role: ${_testUserInfo!['role']}'),
                  Text('Company: ${_testUserInfo!['company']}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection() {
    if (_testUserInfo == null) return const SizedBox.shrink();
    
    final features = _testUserInfo!['features'] as List<dynamic>? ?? [];
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: kPastelOrange, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Demo Features',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature.toString())),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildSampleDataSection() {
    if (_testUserInfo == null) return const SizedBox.shrink();
    
    final sampleData = _testUserInfo!['sampleData'] as Map<String, dynamic>? ?? {};
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.data_object, color: kPastelOrange, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Sample Data',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildDataCard('Products', sampleData['products']?.toString() ?? '0', Icons.inventory),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDataCard('Orders', sampleData['orders']?.toString() ?? '0', Icons.shopping_cart),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildDataCard('Shop Connections', sampleData['shopConnections']?.toString() ?? '0', Icons.link),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDataCard('Warehouse Locations', sampleData['warehouseLocations']?.toString() ?? '0', Icons.warehouse),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kPastelOrange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kPastelOrange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: kPastelOrange, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        if (!_testUserExists) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Create Test User'),
              onPressed: _isLoading ? null : _createTestUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPastelOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_testUserExists) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.login),
              label: const Text('Sign In as Demo User'),
              onPressed: _isLoading ? null : _signInAsTestUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Status'),
            onPressed: _isLoading ? null : _loadTestUserInfo,
            style: OutlinedButton.styleFrom(
              foregroundColor: kPastelOrange,
              side: BorderSide(color: kPastelOrange),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
