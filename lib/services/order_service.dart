import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;

class OrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> fetchOrders({
    String? clientId,
    String? status,
    String? type,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection('orders');
      
      if (clientId != null) {
        query = query.where('clientId', isEqualTo: clientId);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }
      if (type != null) {
        query = query.where('type', isEqualTo: type);
      }
      
      query = query.orderBy('createdAt', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map<Map<String, dynamic>>((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  static Future<Map<String, dynamic>> createOrder({
    required String clientId,
    required String type, // 'sale' or 'purchase'
    required String status,
    required List<Map<String, dynamic>> items,
    String? notes,
    String? priority,
    DateTime? scheduledDate,
  }) async {
    try {
      final orderData = {
        'clientId': clientId,
        'type': type,
        'status': status,
        'items': items,
        'notes': notes,
        'priority': priority ?? 'normal',
        'scheduledDate': scheduledDate,
        'totalItems': items.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 0)),
        'totalValue': items.fold(0.0, (sum, item) => sum + ((item['price'] as num? ?? 0) * (item['quantity'] as int? ?? 0))),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('orders').add(orderData);
      
      // Update client stats
      await _updateClientOrderStats(clientId, type);
      
      return {
        'id': docRef.id,
        ...orderData,
      };
    } catch (e) {
      throw Exception('Failed to create order: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchOrderById(String id) async {
    try {
      final doc = await _firestore.collection('orders').doc(id).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      } else {
        throw Exception('Order not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  static Future<Map<String, dynamic>> updateOrder({
    required String id,
    String? status,
    List<Map<String, dynamic>>? items,
    String? notes,
    String? priority,
    DateTime? scheduledDate,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (status != null) updateData['status'] = status;
      if (items != null) {
        updateData['items'] = items;
        updateData['totalItems'] = items.fold(0, (sum, item) => sum + (item['quantity'] as int? ?? 0));
        updateData['totalValue'] = items.fold(0.0, (sum, item) => sum + ((item['price'] as num? ?? 0) * (item['quantity'] as int? ?? 0)));
      }
      if (notes != null) updateData['notes'] = notes;
      if (priority != null) updateData['priority'] = priority;
      if (scheduledDate != null) updateData['scheduledDate'] = scheduledDate;

      await _firestore.collection('orders').doc(id).update(updateData);
      
      final updatedDoc = await _firestore.collection('orders').doc(id).get();
      return {
        'id': updatedDoc.id,
        ...updatedDoc.data()!,
      };
    } catch (e) {
      throw Exception('Failed to update order: $e');
    }
  }

  static Future<void> deleteOrder(String id) async {
    try {
      await _firestore.collection('orders').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete order: $e');
    }
  }

  static Future<void> updateOrderStatus(String id, String status) async {
    try {
      await _firestore.collection('orders').doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchOrdersByStatus(String status) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map<Map<String, dynamic>>((doc) => {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by status: $e');
    }
  }

  static Future<Map<String, int>> getOrderStats({String? clientId}) async {
    try {
      Query query = _firestore.collection('orders');
      if (clientId != null) {
        query = query.where('clientId', isEqualTo: clientId);
      }
      
      final snapshot = await query.get();
      final orders = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      final stats = <String, int>{
        'total': orders.length,
        'pending': 0,
        'processing': 0,
        'shipped': 0,
        'delivered': 0,
        'cancelled': 0,
      };
      
      for (final order in orders) {
        final status = order['status'] as String? ?? 'pending';
        if (stats.containsKey(status)) {
          stats[status] = stats[status]! + 1;
        }
      }
      
      return stats;
    } catch (e) {
      throw Exception('Failed to get order stats: $e');
    }
  }

  static Future<void> _updateClientOrderStats(String clientId, String orderType) async {
    try {
      await _firestore.collection('clients').doc(clientId).update({
        'stats.orders': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw here as it's not critical for order creation
      print('Warning: Failed to update client stats: $e');
    }
  }
}
