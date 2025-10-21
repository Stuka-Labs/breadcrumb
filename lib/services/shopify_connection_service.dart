import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'dart:convert';
import 'package:http/http.dart' as http;

class ShopifyConnectionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> getClientShopConnection(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('shopConnections')
          .where('clientId', isEqualTo: clientId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return {
          'id': snapshot.docs.first.id,
          ...snapshot.docs.first.data(),
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get shop connection: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getClientConnections(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('shopConnections')
          .where('clientId', isEqualTo: clientId)
          .orderBy('connectedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to get client connections: $e');
    }
  }

  static Future<void> disconnectShop(String connectionId) async {
    try {
      await _firestore.collection('shopConnections').doc(connectionId).update({
        'status': 'disconnected',
        'disconnectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to disconnect shop: $e');
    }
  }

  static Future<Map<String, dynamic>> syncOrdersFromShopify(String connectionId) async {
    try {
      // Get connection details
      final connectionDoc = await _firestore.collection('shopConnections').doc(connectionId).get();
      if (!connectionDoc.exists) {
        throw Exception('Connection not found');
      }

      final connection = connectionDoc.data()!;
      final shop = connection['shop'] as String;
      final accessToken = connection['accessToken'] as String;

      // Fetch orders from Shopify
      final ordersResponse = await http.get(
        Uri.parse('https://$shop/admin/api/2025-01/orders.json?status=any&limit=50'),
        headers: {
          'X-Shopify-Access-Token': accessToken,
          'Content-Type': 'application/json',
        },
      );

      if (ordersResponse.statusCode != 200) {
        throw Exception('Failed to fetch orders from Shopify');
      }

      final ordersData = json.decode(ordersResponse.body);
      final orders = ordersData['orders'] as List<dynamic>;

      // Process and store orders
      int syncedCount = 0;
      for (final order in orders) {
        try {
          await _processAndStoreOrder(order, connection);
          syncedCount++;
        } catch (e) {
          print('Error processing order ${order['id']}: $e');
        }
      }

      // Update last sync time
      await _firestore.collection('shopConnections').doc(connectionId).update({
        'lastSync': FieldValue.serverTimestamp(),
        'lastSyncCount': syncedCount,
      });

      return {
        'success': true,
        'syncedCount': syncedCount,
        'totalOrders': orders.length,
      };
    } catch (e) {
      throw Exception('Failed to sync orders: $e');
    }
  }

  static Future<void> _processAndStoreOrder(Map<String, dynamic> shopifyOrder, Map<String, dynamic> connection) async {
    try {
      // Check if order already exists
      final existingOrder = await _firestore
          .collection('orders')
          .where('shopifyOrderId', isEqualTo: shopifyOrder['id'].toString())
          .limit(1)
          .get();

      if (existingOrder.docs.isNotEmpty) {
        // Update existing order
        await _firestore.collection('orders').doc(existingOrder.docs.first.id).update({
          'status': _mapShopifyStatus(shopifyOrder['fulfillment_status']),
          'updatedAt': FieldValue.serverTimestamp(),
          'shopifyData': shopifyOrder,
        });
        return;
      }

      // Create new order
      final orderData = {
        'clientId': connection['clientId'],
        'shopifyOrderId': shopifyOrder['id'].toString(),
        'shopifyOrderNumber': shopifyOrder['order_number'].toString(),
        'type': 'sale',
        'status': _mapShopifyStatus(shopifyOrder['fulfillment_status']),
        'customerName': shopifyOrder['customer']?['first_name'] ?? 'Guest',
        'customerEmail': shopifyOrder['customer']?['email'] ?? '',
        'totalPrice': (shopifyOrder['total_price'] as num?)?.toDouble() ?? 0.0,
        'currency': shopifyOrder['currency'] ?? 'USD',
        'items': _processOrderItems(shopifyOrder['line_items']),
        'shippingAddress': _processShippingAddress(shopifyOrder['shipping_address']),
        'billingAddress': _processBillingAddress(shopifyOrder['billing_address']),
        'notes': shopifyOrder['note'] ?? '',
        'tags': shopifyOrder['tags'] ?? '',
        'shopifyData': shopifyOrder,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('orders').add(orderData);

      // Update client stats
      await _firestore.collection('clients').doc(connection['clientId']).update({
        'stats.orders': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

    } catch (e) {
      print('Error processing order: $e');
      rethrow;
    }
  }

  static String _mapShopifyStatus(String? shopifyStatus) {
    switch (shopifyStatus) {
      case 'fulfilled':
        return 'shipped';
      case 'partial':
        return 'processing';
      case 'unfulfilled':
        return 'pending';
      default:
        return 'pending';
    }
  }

  static List<Map<String, dynamic>> _processOrderItems(List<dynamic>? lineItems) {
    if (lineItems == null) return [];
    
    return lineItems.map((item) => {
      'productId': item['product_id']?.toString(),
      'variantId': item['variant_id']?.toString(),
      'sku': item['sku'] ?? '',
      'name': item['name'] ?? '',
      'quantity': item['quantity'] ?? 0,
      'price': (item['price'] as num?)?.toDouble() ?? 0.0,
      'totalPrice': ((item['price'] as num?)?.toDouble() ?? 0.0) * (item['quantity'] as int? ?? 0),
    }).toList();
  }

  static Map<String, dynamic>? _processShippingAddress(Map<String, dynamic>? address) {
    if (address == null) return null;
    
    return {
      'firstName': address['first_name'] ?? '',
      'lastName': address['last_name'] ?? '',
      'company': address['company'] ?? '',
      'address1': address['address1'] ?? '',
      'address2': address['address2'] ?? '',
      'city': address['city'] ?? '',
      'province': address['province'] ?? '',
      'country': address['country'] ?? '',
      'zip': address['zip'] ?? '',
      'phone': address['phone'] ?? '',
    };
  }

  static Map<String, dynamic>? _processBillingAddress(Map<String, dynamic>? address) {
    if (address == null) return null;
    
    return {
      'firstName': address['first_name'] ?? '',
      'lastName': address['last_name'] ?? '',
      'company': address['company'] ?? '',
      'address1': address['address1'] ?? '',
      'address2': address['address2'] ?? '',
      'city': address['city'] ?? '',
      'province': address['province'] ?? '',
      'country': address['country'] ?? '',
      'zip': address['zip'] ?? '',
      'phone': address['phone'] ?? '',
    };
  }

  static Future<List<Map<String, dynamic>>> getClientOrders(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to get client orders: $e');
    }
  }

  static Future<Map<String, dynamic>> getConnectionStats(String connectionId) async {
    try {
      final connection = await _firestore.collection('shopConnections').doc(connectionId).get();
      if (!connection.exists) {
        throw Exception('Connection not found');
      }

      final connectionData = connection.data()!;
      final clientId = connectionData['clientId'] as String;

      // Get order count
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('clientId', isEqualTo: clientId)
          .get();

      return {
        'connectionId': connectionId,
        'shop': connectionData['shop'],
        'shopName': connectionData['shopName'],
        'connectedAt': connectionData['connectedAt'],
        'lastSync': connectionData['lastSync'],
        'totalOrders': ordersSnapshot.docs.length,
        'status': connectionData['status'],
      };
    } catch (e) {
      throw Exception('Failed to get connection stats: $e');
    }
  }
}
