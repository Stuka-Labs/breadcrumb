import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PackerPickingScreen extends StatefulWidget {
  const PackerPickingScreen({super.key});

  @override
  State<PackerPickingScreen> createState() => _PackerPickingScreenState();
}

class _PackerPickingScreenState extends State<PackerPickingScreen> {
  List<Map<String, dynamic>> activeOrders = [];
  List<Map<String, dynamic>> pickingList = [];
  bool isLoading = true;
  String selectedOrderId = '';

  @override
  void initState() {
    super.initState();
    _loadActiveOrders();
  }

  Future<void> _loadActiveOrders() async {
    setState(() => isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('saleOrders')
          .where('status', whereIn: ['open', 'processing'])
          .orderBy('createdAt', descending: false)
          .get();
      
      setState(() {
        activeOrders = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            ...data,
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading orders: $e')),
      );
    }
  }

  Future<void> _generatePickingList(String orderId) async {
    setState(() => isLoading = true);
    try {
      // Get order details
      final orderDoc = await FirebaseFirestore.instance
          .collection('saleOrders')
          .doc(orderId)
          .get();
      
      if (!orderDoc.exists) return;
      
      final orderData = orderDoc.data()!;
      final items = orderData['items'] as List<dynamic>? ?? [];
      
      // Generate picking list with bin locations
      final List<Map<String, dynamic>> pickingItems = [];
      
      for (var item in items) {
        final productId = item['productId'];
        final quantity = item['quantity'] ?? 1;
        
        // Get product details and bin location
        final productDoc = await FirebaseFirestore.instance
            .collection('products')
            .doc(productId)
            .get();
        
        if (productDoc.exists) {
          final productData = productDoc.data()!;
          
          // Get bin location
          final locationDoc = await FirebaseFirestore.instance
              .collection('locations')
              .where('productId', isEqualTo: productId)
              .limit(1)
              .get();
          
          String binLocation = 'Not Located';
          if (locationDoc.docs.isNotEmpty) {
            final location = locationDoc.docs.first.data();
            binLocation = 'Z${location['zone']}-A${location['aisle']}-S${location['shelf']}-B${location['bin']}';
          }
          
          pickingItems.add({
            'productId': productId,
            'productName': productData['name'] ?? 'Unknown Product',
            'sku': productData['sku'] ?? '',
            'quantity': quantity,
            'binLocation': binLocation,
            'picked': false,
            'notes': item['notes'] ?? '',
          });
        }
      }
      
      setState(() {
        pickingList = pickingItems;
        selectedOrderId = orderId;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating picking list: $e')),
      );
    }
  }

  Future<void> _markItemPicked(int index) async {
    setState(() {
      pickingList[index]['picked'] = !pickingList[index]['picked'];
    });
    
    // Check if all items are picked
    final allPicked = pickingList.every((item) => item['picked'] == true);
    if (allPicked) {
      _showOrderCompleteDialog();
    }
  }

  void _showOrderCompleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Order Complete!'),
          ],
        ),
        content: const Text('All items have been picked. Ready to pack and ship.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Picking'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeOrder();
            },
            child: const Text('Complete Order'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOrder() async {
    try {
      await FirebaseFirestore.instance
          .collection('saleOrders')
          .doc(selectedOrderId)
          .update({
        'status': 'fulfilled',
        'fulfilledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Order completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh orders
      _loadActiveOrders();
      setState(() {
        pickingList = [];
        selectedOrderId = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Packer Picking System'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadActiveOrders,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Order Selection
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Order to Pick',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      if (activeOrders.isEmpty)
                        const Text('No active orders to pick')
                      else
                        DropdownButtonFormField<String>(
                          value: selectedOrderId.isEmpty ? null : selectedOrderId,
                          decoration: const InputDecoration(
                            labelText: 'Choose Order',
                            border: OutlineInputBorder(),
                          ),
                          items: activeOrders.map((order) {
                            return DropdownMenuItem<String>(
                              value: order['id'],
                              child: Text('Order #${order['id']} - ${order['customerName'] ?? 'Unknown Customer'}'),
                            );
                          }).toList(),
                          onChanged: (orderId) {
                            if (orderId != null) {
                              _generatePickingList(orderId);
                            }
                          },
                        ),
                    ],
                  ),
                ),
                
                // Picking List
                Expanded(
                  child: pickingList.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('Select an order to start picking'),
                            ],
                          ),
                        )
                      : _buildPickingList(),
                ),
              ],
            ),
    );
  }

  Widget _buildPickingList() {
    final pickedCount = pickingList.where((item) => item['picked'] == true).length;
    final totalCount = pickingList.length;
    
    return Column(
      children: [
        // Progress Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Picking Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$pickedCount of $totalCount items picked'),
                  ],
                ),
              ),
              CircularProgressIndicator(
                value: totalCount > 0 ? pickedCount / totalCount : 0,
                backgroundColor: Colors.green.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
              ),
            ],
          ),
        ),
        
        // Picking Items
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pickingList.length,
            itemBuilder: (context, index) {
              final item = pickingList[index];
              final isPicked = item['picked'] == true;
              
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: isPicked ? 0 : 2,
                color: isPicked ? Colors.green.shade50 : Colors.white,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isPicked ? Colors.green : Colors.blue,
                    child: Icon(
                      isPicked ? Icons.check : Icons.inventory_2,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    item['productName'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: isPicked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SKU: ${item['sku']}'),
                      Text('Quantity: ${item['quantity']}'),
                      Text(
                        'Location: ${item['binLocation']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      if (item['notes'].isNotEmpty)
                        Text('Notes: ${item['notes']}'),
                    ],
                  ),
                  trailing: Checkbox(
                    value: isPicked,
                    onChanged: (_) => _markItemPicked(index),
                    activeColor: Colors.green,
                  ),
                  onTap: () => _markItemPicked(index),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
