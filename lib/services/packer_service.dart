import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;

class PackerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> fetchPackers() async {
    try {
      final snapshot = await _firestore.collection('users')
          .where('role', isEqualTo: 'packer')
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch packers: $e');
    }
  }

  static Future<Map<String, dynamic>> createPacker({
    required String email,
    required String username,
    String? warehouseId,
    String? phone,
    String? address,
  }) async {
    try {
      final docRef = await _firestore.collection('users').add({
        'email': email,
        'username': username,
        'role': 'packer',
        'warehouseId': warehouseId,
        'phone': phone,
        'address': address,
        'status': 'active',
        'stats': {
          'ordersPacked': 0,
          'itemsPacked': 0,
          'lastActivity': FieldValue.serverTimestamp(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return {
        'id': docRef.id,
        'email': email,
        'username': username,
        'role': 'packer',
        'warehouseId': warehouseId,
        'phone': phone,
        'address': address,
        'status': 'active',
        'stats': {'ordersPacked': 0, 'itemsPacked': 0}
      };
    } catch (e) {
      throw Exception('Failed to create packer: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchPackerById(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        final data = doc.data()!;
        if (data['role'] == 'packer') {
          return {
            'id': doc.id,
            ...data,
          };
        } else {
          throw Exception('User is not a packer');
        }
      } else {
        throw Exception('Packer not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch packer: $e');
    }
  }

  static Future<Map<String, dynamic>> updatePacker({
    required String id,
    String? username,
    String? warehouseId,
    String? phone,
    String? address,
    String? status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (username != null) updateData['username'] = username;
      if (warehouseId != null) updateData['warehouseId'] = warehouseId;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (status != null) updateData['status'] = status;

      await _firestore.collection('users').doc(id).update(updateData);
      
      final updatedDoc = await _firestore.collection('users').doc(id).get();
      return {
        'id': updatedDoc.id,
        ...updatedDoc.data()!,
      };
    } catch (e) {
      throw Exception('Failed to update packer: $e');
    }
  }

  static Future<void> deletePacker(String id) async {
    try {
      await _firestore.collection('users').doc(id).update({
        'status': 'inactive',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to delete packer: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPackerOrders(String packerId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('packerId', isEqualTo: packerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch packer orders: $e');
    }
  }

  static Future<void> assignOrderToPacker(String orderId, String packerId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'packerId': packerId,
        'status': 'processing',
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to assign order to packer: $e');
    }
  }

  static Future<void> updatePackerStats(String packerId, {
    int? ordersPacked,
    int? itemsPacked,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'stats.lastActivity': FieldValue.serverTimestamp(),
      };
      
      if (ordersPacked != null) {
        updateData['stats.ordersPacked'] = FieldValue.increment(ordersPacked);
      }
      if (itemsPacked != null) {
        updateData['stats.itemsPacked'] = FieldValue.increment(itemsPacked);
      }

      await _firestore.collection('users').doc(packerId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update packer stats: $e');
    }
  }

  static Future<Map<String, int>> getPackerStats(String packerId) async {
    try {
      final doc = await _firestore.collection('users').doc(packerId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final stats = data['stats'] as Map<String, dynamic>? ?? {};
        return {
          'ordersPacked': stats['ordersPacked'] as int? ?? 0,
          'itemsPacked': stats['itemsPacked'] as int? ?? 0,
        };
      } else {
        throw Exception('Packer not found');
      }
    } catch (e) {
      throw Exception('Failed to get packer stats: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAvailablePackers() async {
    try {
      final snapshot = await _firestore.collection('users')
          .where('role', isEqualTo: 'packer')
          .where('status', isEqualTo: 'active')
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch available packers: $e');
    }
  }
}
