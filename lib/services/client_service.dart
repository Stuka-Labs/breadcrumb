import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;

class ClientService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> fetchClients() async {
    try {
      final snapshot = await _firestore.collection('clients').get();
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch clients: $e');
    }
  }

  static Future<Map<String, dynamic>> createClient({
    required String name,
    required String shopType,
    String? email,
    String? phone,
    String? address,
  }) async {
    try {
      final docRef = await _firestore.collection('clients').add({
        'name': name,
        'shopType': shopType,
        'email': email,
        'phone': phone,
        'address': address,
        'status': 'active',
        'stats': {
          'orders': 0,
          'products': 0,
          'purchaseOrders': 0,
          'lastActivity': FieldValue.serverTimestamp(),
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return {
        'id': docRef.id,
        'name': name,
        'shopType': shopType,
        'email': email,
        'phone': phone,
        'address': address,
        'status': 'active',
        'stats': {'orders': 0, 'products': 0, 'purchaseOrders': 0}
      };
    } catch (e) {
      throw Exception('Failed to create client: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchClientById(String id) async {
    try {
      final doc = await _firestore.collection('clients').doc(id).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      } else {
        throw Exception('Client not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch client: $e');
    }
  }

  static Future<Map<String, dynamic>> updateClient({
    required String id,
    required String name,
    required String shopType,
    String? email,
    String? phone,
    String? address,
    String? status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'name': name,
        'shopType': shopType,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (email != null) updateData['email'] = email;
      if (phone != null) updateData['phone'] = phone;
      if (address != null) updateData['address'] = address;
      if (status != null) updateData['status'] = status;

      await _firestore.collection('clients').doc(id).update(updateData);
      
      final updatedDoc = await _firestore.collection('clients').doc(id).get();
      return {
        'id': updatedDoc.id,
        ...updatedDoc.data()!,
      };
    } catch (e) {
      throw Exception('Failed to update client: $e');
    }
  }

  static Future<void> deleteClient(String id) async {
    try {
      await _firestore.collection('clients').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete client: $e');
    }
  }

  static Future<void> updateClientStats(String clientId, {
    int? orders,
    int? products,
    int? purchaseOrders,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
        'stats.lastActivity': FieldValue.serverTimestamp(),
      };
      
      if (orders != null) updateData['stats.orders'] = FieldValue.increment(orders);
      if (products != null) updateData['stats.products'] = FieldValue.increment(products);
      if (purchaseOrders != null) updateData['stats.purchaseOrders'] = FieldValue.increment(purchaseOrders);

      await _firestore.collection('clients').doc(clientId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update client stats: $e');
    }
  }
} 