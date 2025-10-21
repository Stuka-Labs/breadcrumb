import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;

class ProductService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      final snapshot = await _firestore.collection('products').get();
      return snapshot.docs.map<Map<String, dynamic>>((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  static Future<Map<String, dynamic>> fetchProductById(String id) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data()!,
        };
      } else {
        throw Exception('Product not found');
      }
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required String sku,
    String? description,
    double? price,
    String? category,
    String? locationId,
    String? warehouseId,
    int? stockQuantity,
  }) async {
    try {
      final docRef = await _firestore.collection('products').add({
        'name': name,
        'sku': sku,
        'description': description,
        'price': price,
        'category': category,
        'locationId': locationId,
        'warehouseId': warehouseId,
        'stockQuantity': stockQuantity ?? 0,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      return {
        'id': docRef.id,
        'name': name,
        'sku': sku,
        'description': description,
        'price': price,
        'category': category,
        'locationId': locationId,
        'warehouseId': warehouseId,
        'stockQuantity': stockQuantity ?? 0,
        'status': 'active',
      };
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  static Future<Map<String, dynamic>> updateProduct({
    required String id,
    String? name,
    String? sku,
    String? description,
    double? price,
    String? category,
    String? locationId,
    String? warehouseId,
    int? stockQuantity,
    String? status,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (name != null) updateData['name'] = name;
      if (sku != null) updateData['sku'] = sku;
      if (description != null) updateData['description'] = description;
      if (price != null) updateData['price'] = price;
      if (category != null) updateData['category'] = category;
      if (locationId != null) updateData['locationId'] = locationId;
      if (warehouseId != null) updateData['warehouseId'] = warehouseId;
      if (stockQuantity != null) updateData['stockQuantity'] = stockQuantity;
      if (status != null) updateData['status'] = status;

      await _firestore.collection('products').doc(id).update(updateData);
      
      final updatedDoc = await _firestore.collection('products').doc(id).get();
      return {
        'id': updatedDoc.id,
        ...updatedDoc.data()!,
      };
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  static Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  static Future<void> updateStock(String productId, int quantity) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'stockQuantity': FieldValue.increment(quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchProductsByWarehouse(String warehouseId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('warehouseId', isEqualTo: warehouseId)
          .get();
      
      return snapshot.docs.map<Map<String, dynamic>>((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch products by warehouse: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchProductsByLocation(String locationId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('locationId', isEqualTo: locationId)
          .get();
      
      return snapshot.docs.map<Map<String, dynamic>>((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch products by location: $e');
    }
  }
} 