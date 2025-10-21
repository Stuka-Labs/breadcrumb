import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;

class PurchaseOrderService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> fetchPurchaseOrders() async {
    try {
      final snapshot = await _firestore.collection('purchaseOrders').get();
      return snapshot.docs.map<Map<String, dynamic>>((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch purchase orders: $e');
    }
  }

  static Future<Map<String, dynamic>> createPurchaseOrder({
    required String clientId,
    required List<Map<String, dynamic>> items,
    String? notes,
    String? priority,
    DateTime? scheduledDate,
  }) async {
    try {
      // Calculate total items and value
      int totalItems = 0;
      double totalValue = 0.0;
      
      for (final item in items) {
        final quantity = item['quantity'] as int? ?? 0;
        totalItems += quantity;
        
        // Get product price if available
        if (item['productId'] != null) {
          try {
            final productDoc = await _firestore.collection('products').doc(item['productId']).get();
            if (productDoc.exists) {
              final productData = productDoc.data()!;
              final price = (productData['price'] as num?)?.toDouble() ?? 0.0;
              totalValue += price * quantity;
            }
          } catch (e) {
            // Continue without price if product not found
          }
        }
      }

      final purchaseOrderData = {
        'clientId': clientId,
        'type': 'purchase',
        'status': 'pending',
        'items': items,
        'totalItems': totalItems,
        'totalValue': totalValue,
        'notes': notes,
        'priority': priority ?? 'normal',
        'scheduledDate': scheduledDate,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('purchaseOrders').add(purchaseOrderData);
      
      // Update client stats
      await _updateClientStats(clientId, 'purchaseOrders');
      
      return {
        'id': docRef.id,
        ...purchaseOrderData,
      };
    } catch (e) {
      throw Exception('Failed to create purchase order: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchPurchaseOrderById(String id) async {
    try {
      final doc = await _firestore.collection('purchaseOrders').doc(id).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      } else {
        throw Exception('Purchase order not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch purchase order: $e');
    }
  }

  static Future<Map<String, dynamic>> updatePurchaseOrder({
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
        // Recalculate totals
        int totalItems = 0;
        double totalValue = 0.0;
        
        for (final item in items) {
          final quantity = item['quantity'] as int? ?? 0;
          totalItems += quantity;
          
          if (item['productId'] != null) {
            try {
              final productDoc = await _firestore.collection('products').doc(item['productId']).get();
              if (productDoc.exists) {
                final productData = productDoc.data()!;
                final price = (productData['price'] as num?)?.toDouble() ?? 0.0;
                totalValue += price * quantity;
              }
            } catch (e) {
              // Continue without price
            }
          }
        }
        
        updateData['totalItems'] = totalItems;
        updateData['totalValue'] = totalValue;
      }
      if (notes != null) updateData['notes'] = notes;
      if (priority != null) updateData['priority'] = priority;
      if (scheduledDate != null) updateData['scheduledDate'] = scheduledDate;

      await _firestore.collection('purchaseOrders').doc(id).update(updateData);
      
      final updatedDoc = await _firestore.collection('purchaseOrders').doc(id).get();
      return {
        'id': updatedDoc.id,
        ...updatedDoc.data()!,
      };
    } catch (e) {
      throw Exception('Failed to update purchase order: $e');
    }
  }

  static Future<void> deletePurchaseOrder(String id) async {
    try {
      await _firestore.collection('purchaseOrders').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete purchase order: $e');
    }
  }

  static Future<void> updatePurchaseOrderStatus(String id, String status) async {
    try {
      await _firestore.collection('purchaseOrders').doc(id).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update purchase order status: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPurchaseOrdersByClient(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('purchaseOrders')
          .where('clientId', isEqualTo: clientId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map<Map<String, dynamic>>((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch purchase orders by client: $e');
    }
  }

  static Future<void> _updateClientStats(String clientId, String statType) async {
    try {
      await _firestore.collection('clients').doc(clientId).update({
        'stats.$statType': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Don't throw here as it's not critical for order creation
      print('Warning: Failed to update client stats: $e');
    }
  }
} 