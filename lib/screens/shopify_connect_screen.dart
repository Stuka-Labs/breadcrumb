import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html show window;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:firebase_auth/firebase_auth.dart';
import '../services/shopify_connection_service.dart';
import '../services/auth_service.dart';

class ShopifyConnectScreen extends StatefulWidget {
  const ShopifyConnectScreen({super.key});

  @override
  State<ShopifyConnectScreen> createState() => _ShopifyConnectScreenState();
}

class _ShopifyConnectScreenState extends State<ShopifyConnectScreen> {
  final TextEditingController _shopController = TextEditingController();
  bool loading = false;
  String? error;
  Map<String, dynamic>? currentConnection;

  @override
  void initState() {
    super.initState();
    _checkExistingConnection();
  }

  @override
  void dispose() {
    _shopController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingConnection() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get client ID from user document
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final clientId = userData['clientId'] as String?;
          
          if (clientId != null) {
            final connection = await ShopifyConnectionService.getClientShopConnection(clientId);
            if (connection != null) {
              setState(() {
                currentConnection = connection;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error checking existing connection: $e');
    }
  }

  void _connectToShopify() {
    final shop = _shopController.text.trim();
    if (shop.isEmpty) {
      setState(() => error = 'Please enter your Shopify shop domain');
      return;
    }

    // Validate shop domain
    if (!shop.endsWith('.myshopify.com')) {
      setState(() => error = 'Please enter a valid Shopify shop domain (e.g., your-shop.myshopify.com)');
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    if (kIsWeb) {
      _getClientIdAndConnect(shop);
    } else {
      setState(() {
        error = 'Shopify connection is only available on web platforms';
        loading = false;
      });
    }
  }

  Future<void> _getClientIdAndConnect(String shop) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          error = 'Please sign in to connect your shop';
          loading = false;
        });
        return;
      }

      // Get or create client ID
      String? clientId = await _getOrCreateClientId(user.uid);
      if (clientId == null) {
        setState(() {
          error = 'Failed to get client ID';
          loading = false;
        });
        return;
      }

      // Open Shopify OAuth
      final url = 'https://snap-nottingham-andrea-originally.trycloudflare.com/api/auth/shopify?shop=$shop&clientId=$clientId';
      html.window.open(url, '_blank');
      
      setState(() {
        loading = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening Shopify authorization... Please complete the process in the new tab.'),
          duration: Duration(seconds: 5),
        ),
      );

    } catch (e) {
      setState(() {
        error = 'Failed to connect: $e';
        loading = false;
      });
    }
  }

  Future<String?> _getOrCreateClientId(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final clientId = userData['clientId'] as String?;
        if (clientId != null) return clientId;
      }

      // Create client document
      final clientDoc = await FirebaseFirestore.instance.collection('clients').add({
        'name': userDoc.exists ? (userDoc.data()?['username'] ?? 'Client') : 'Client',
        'shopType': 'Shopify',
        'status': 'active',
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create or update user document with client ID
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'clientId': clientDoc.id,
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
        'username': FirebaseAuth.instance.currentUser?.displayName ?? 'Client',
        'role': 'client',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      return clientDoc.id;
    } catch (e) {
      print('Error getting/creating client ID: $e');
      return null;
    }
  }

  Future<void> _syncOrders() async {
    if (currentConnection == null) return;

    setState(() => loading = true);
    try {
      final result = await ShopifyConnectionService.syncOrdersFromShopify(currentConnection!['id']);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully synced ${result['syncedCount']} orders'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to sync orders: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _disconnectShop() async {
    if (currentConnection == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Shop'),
        content: const Text('Are you sure you want to disconnect this Shopify shop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => loading = true);
      try {
        await ShopifyConnectionService.disconnectShop(currentConnection!['id']);
        setState(() {
          currentConnection = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Shop disconnected successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to disconnect: $e')),
        );
      } finally {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Shopify'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (currentConnection != null) ...[
              // Connected state
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Connected to ${currentConnection!['shopName']}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Shop: ${currentConnection!['shop']}'),
                      Text('Connected: ${_formatDate(currentConnection!['connectedAt'])}'),
                      if (currentConnection!['lastSync'] != null)
                        Text('Last sync: ${_formatDate(currentConnection!['lastSync'])}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: loading ? null : _syncOrders,
                      icon: const Icon(Icons.sync),
                      label: const Text('Sync Orders'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: loading ? null : _disconnectShop,
                      icon: const Icon(Icons.link_off),
                      label: const Text('Disconnect'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Not connected state
              const Text(
                'Connect Your Shopify Store',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your Shopify shop domain to connect and start syncing orders.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _shopController,
                decoration: const InputDecoration(
                  labelText: 'Shop Domain',
                  hintText: 'your-shop.myshopify.com',
                  prefixIcon: Icon(Icons.store),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              if (error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(error!)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: loading ? null : _connectToShopify,
                  icon: loading ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ) : const Icon(Icons.link),
                  label: Text(loading ? 'Connecting...' : 'Connect to Shopify'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Never';
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        return 'Invalid date';
      }
      
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }
}
