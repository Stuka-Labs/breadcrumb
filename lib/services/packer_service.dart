import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'package:firebase_auth/firebase_auth.dart';
import 'material_service.dart';

class PackerService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current packer ID
  static String? getCurrentPackerId() {
    return _auth.currentUser?.uid;
  }

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

  // Fetch orders ready for packing
  static Stream<QuerySnapshot> getOrdersReadyForPacking() {
    return _firestore
        .collection('orders')
        .where('status', whereIn: ['received', 'ready_to_ship'])
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Get order details with product information
  static Future<Map<String, dynamic>?> getOrderDetails(String orderId) async {
    try {
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) return null;
      
      final orderData = orderDoc.data()!;
      final items = orderData['items'] as List<dynamic>? ?? [];
      
      // Enrich items with product and bin location data
      final enrichedItems = <Map<String, dynamic>>[];
      
      for (var item in items) {
        final productId = item['productId'];
        final productDoc = await _firestore.collection('products').doc(productId).get();
        
        String binLocation = 'Not Located';
        String binId = '';
        
        // Find bin location from locations collection
        final locationQuery = await _firestore
            .collection('locations')
            .where('productId', isEqualTo: productId)
            .where('isFilled', isEqualTo: true)
            .limit(1)
            .get();
        
        if (locationQuery.docs.isNotEmpty) {
          final locationData = locationQuery.docs.first.data();
          binId = locationQuery.docs.first.id;
          binLocation = locationData['binName'] ?? 
                       '${locationData['row'] ?? ''}-${locationData['level'] ?? ''}-${locationData['bay'] ?? ''}-${locationData['bin'] ?? ''}';
          if (binLocation.isEmpty || binLocation == '---') binLocation = 'Not Located';
        }
        
        final productData = productDoc.exists ? productDoc.data() : {};
        
        enrichedItems.add({
          ...item,
          'productName': productData?['name'] ?? 'Unknown Product',
          'sku': productData?['sku'] ?? '',
          'binLocation': binLocation,
          'binId': binId,
          'currentStock': locationQuery.docs.isNotEmpty 
              ? (locationQuery.docs.first.data()['currentStock'] ?? 0)
              : (productData?['quantity'] ?? 0),
        });
      }
      
      return {
        'id': orderDoc.id,
        ...orderData,
        'items': enrichedItems,
      };
    } catch (e) {
      throw Exception('Failed to get order details: $e');
    }
  }

  // Validate bin scan and return bin info
  static Future<Map<String, dynamic>?> validateBinScan(String scannedBin) async {
    try {
      // Search for bin in locations collection by binName
      final locationQuery = await _firestore
          .collection('locations')
          .where('binName', isEqualTo: scannedBin)
          .limit(1)
          .get();
      
      if (locationQuery.docs.isEmpty) {
        // Try searching in warehouse_blueprint collection
        final blueprintSnapshot = await _firestore
            .collection('warehouse_blueprint')
            .get();
        
        for (final rowDoc in blueprintSnapshot.docs) {
          final rowData = rowDoc.data();
          final levels = rowData['levels'] as List<dynamic>? ?? [];
          
          for (final level in levels) {
            final bays = level['bays'] as List<dynamic>? ?? [];
            for (final bay in bays) {
              final bins = bay['bins'] as List<dynamic>? ?? [];
              for (final bin in bins) {
                final binName = bin['binName'] ?? bin['id'].toString();
                if (binName == scannedBin || bin['id'].toString().contains(scannedBin)) {
                  return {
                    'binName': binName,
                    'binId': bin['id'],
                    'productId': bin['productId'],
                    'productName': bin['productName'],
                  };
                }
              }
            }
          }
        }
        
        return null;
      }
      
      final locationData = locationQuery.docs.first.data();
      final productId = locationData['productId'];
      
      // Get product info
      Map<String, dynamic>? productData;
      if (productId != null) {
        final productDoc = await _firestore.collection('products').doc(productId).get();
        productData = productDoc.exists ? productDoc.data() : null;
      }
      
      return {
        'binName': locationData['binName'] ?? scannedBin,
        'binId': locationQuery.docs.first.id,
        'productId': productId,
        'productName': productData?['name'] ?? 'No Product Assigned',
        'sku': productData?['sku'] ?? '',
        'currentStock': locationData['currentStock'] ?? 0,
      };
    } catch (e) {
      throw Exception('Failed to validate bin scan: $e');
    }
  }

  // Validate product SKU scan
  static Future<Map<String, dynamic>?> validateProductScan(String scannedSku) async {
    try {
      final productQuery = await _firestore
          .collection('products')
          .where('sku', isEqualTo: scannedSku)
          .limit(1)
          .get();
      
      if (productQuery.docs.isEmpty) return null;
      
      final productData = productQuery.docs.first.data();
      final productId = productQuery.docs.first.id;
      
      // Find bin location
      final locationQuery = await _firestore
          .collection('locations')
          .where('productId', isEqualTo: productId)
          .where('isFilled', isEqualTo: true)
          .limit(1)
          .get();
      
      String binLocation = 'Not Located';
      String binId = '';
      if (locationQuery.docs.isNotEmpty) {
        final locationData = locationQuery.docs.first.data();
        binId = locationQuery.docs.first.id;
        binLocation = locationData['binName'] ?? 'Not Located';
      }
      
      return {
        'productId': productId,
        'productName': productData['name'] ?? 'Unknown Product',
        'sku': scannedSku,
        'binLocation': binLocation,
        'binId': binId,
        'quantity': productData['quantity'] ?? 0,
        'dimensions': {
          'length': productData['length']?.toDouble() ?? 6.0,
          'width': productData['width']?.toDouble() ?? 4.0,
          'height': productData['height']?.toDouble() ?? 3.0,
        },
      };
    } catch (e) {
      throw Exception('Failed to validate product scan: $e');
    }
  }

  // Pack an item: deduct inventory, deduct materials, update order
  static Future<void> packItem({
    required String orderId,
    required String productId,
    required String itemId,
    required String binId,
    required int quantityPacked,
    required String packerId,
  }) async {
    try {
      final batch = _firestore.batch();
      
      // 1. Get order to update item status
      final orderRef = _firestore.collection('orders').doc(orderId);
      final orderDoc = await orderRef.get();
      if (!orderDoc.exists) throw Exception('Order not found');
      
      final orderData = orderDoc.data()!;
      final items = List<Map<String, dynamic>>.from(orderData['items'] as List? ?? []);
      
      // Update item status to packed
      bool allItemsPacked = true;
      bool itemMatched = false;
      for (var item in items) {
        // Match by productId and itemId (if present), or just productId if itemId matches productId
        final matchesId = itemId.isEmpty || item['id'] == itemId || itemId == productId;
        if (item['productId'] == productId && matchesId && 
            (item['status'] != 'packed' && item['status'] != 'fulfilled')) {
          item['status'] = 'packed';
          item['packedQuantity'] = quantityPacked;
          item['packedAt'] = FieldValue.serverTimestamp();
          item['packerId'] = packerId;
          itemMatched = true;
          break; // Only pack one item at a time
        }
        if (item['status'] != 'packed' && item['status'] != 'fulfilled') {
          allItemsPacked = false;
        }
      }
      
      if (!itemMatched) {
        throw Exception('Item not found or already packed');
      }
      
      // Update order items
      batch.update(orderRef, {
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // If all items packed, update order status
      if (allItemsPacked) {
        batch.update(orderRef, {
          'status': 'ready_to_ship',
          'packedAt': FieldValue.serverTimestamp(),
        });
      }
      
      // 2. Deduct inventory from bin
      if (binId.isNotEmpty) {
        final binRef = _firestore.collection('locations').doc(binId);
        final binDoc = await binRef.get();
        
        if (binDoc.exists) {
          final currentStock = binDoc.data()!['currentStock'] as int? ?? 0;
          final newStock = (currentStock - quantityPacked).clamp(0, double.infinity).toInt();
          
          batch.update(binRef, {
            'currentStock': newStock,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          // If bin is empty, mark as not filled
          if (newStock == 0) {
            batch.update(binRef, {
              'isFilled': false,
              'productId': FieldValue.delete(),
            });
          }
        }
      }
      
      // Also deduct from product quantity
      final productRef = _firestore.collection('products').doc(productId);
      final productDoc = await productRef.get();
      
      if (productDoc.exists) {
        final currentQuantity = productDoc.data()!['quantity'] as int? ?? 0;
        final newQuantity = (currentQuantity - quantityPacked).clamp(0, double.infinity).toInt();
        
        batch.update(productRef, {
          'quantity': newQuantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // 3. Deduct packaging materials
        final productData = productDoc.data()!;
        final dimensions = {
          'length': productData['length']?.toDouble() ?? 6.0,
          'width': productData['width']?.toDouble() ?? 4.0,
          'height': productData['height']?.toDouble() ?? 3.0,
        };
        
        final materialsUsed = MaterialService.calculateMaterialsRequired(
          productLength: dimensions['length']!,
          productWidth: dimensions['width']!,
          productHeight: dimensions['height']!,
          quantity: quantityPacked,
        );
        
        // Get material IDs and deduct
        final materialsSnapshot = await _firestore.collection('materials').get();
        for (final materialDoc in materialsSnapshot.docs) {
          final materialData = materialDoc.data();
          final materialType = materialData['type'] as String? ?? '';
          final materialName = materialData['name'] as String? ?? '';
          
          int? quantityToDeduct;
          
          // Match material type or name
          if (materialsUsed.containsKey(materialType)) {
            quantityToDeduct = materialsUsed[materialType];
          } else if (materialsUsed.containsKey(materialName.toLowerCase().replaceAll(' ', '_'))) {
            final key = materialName.toLowerCase().replaceAll(' ', '_');
            quantityToDeduct = materialsUsed[key];
          } else if (materialName.toLowerCase().contains('box') && materialsUsed.containsKey('small_box')) {
            quantityToDeduct = materialsUsed['small_box'];
          } else if (materialName.toLowerCase().contains('tape') && materialsUsed.containsKey('packing_tape')) {
            quantityToDeduct = materialsUsed['packing_tape'];
          } else if (materialName.toLowerCase().contains('label') && materialsUsed.containsKey('shipping_labels')) {
            quantityToDeduct = materialsUsed['shipping_labels'];
          }
          
          if (quantityToDeduct != null && quantityToDeduct > 0) {
            final currentMaterialQty = materialData['quantity'] as int? ?? 0;
            final newMaterialQty = (currentMaterialQty - quantityToDeduct).clamp(0, double.infinity).toInt();
            
            batch.update(materialDoc.reference, {
              'quantity': newMaterialQty,
              'lastUpdated': FieldValue.serverTimestamp(),
            });
          }
        }
      }
      
      // 4. Create stock movement record
      await _firestore.collection('stockMovements').add({
        'orderId': orderId,
        'productId': productId,
        'binId': binId,
        'movementType': 'packed',
        'quantity': -quantityPacked,
        'packerId': packerId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // 5. Update packer stats
      await updatePackerStats(packerId, itemsPacked: quantityPacked);
      
      // Commit all updates
      await batch.commit();
      
    } catch (e) {
      throw Exception('Failed to pack item: $e');
    }
  }
}
