import 'package:cloud_firestore/cloud_firestore.dart';

class WarehouseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Location Management
  static Future<void> createLocation(Map<String, dynamic> locationData) async {
    await _firestore.collection('locations').add({
      ...locationData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateLocation(String locationId, Map<String, dynamic> updates) async {
    await _firestore.collection('locations').doc(locationId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> deleteLocation(String locationId) async {
    await _firestore.collection('locations').doc(locationId).delete();
  }

  static Future<List<Map<String, dynamic>>> getLocations({String? clientId}) async {
    Query query = _firestore.collection('locations');
    
    if (clientId != null) {
      query = query.where('clientId', isEqualTo: clientId);
    }
    
    final snapshot = await query.get();
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();
  }

  // Product-Location Assignment
  static Future<void> assignProductToLocation({
    required String productId,
    required String locationId,
    required int quantity,
  }) async {
    final batch = _firestore.batch();
    
    // Update location with product assignment
    final locationRef = _firestore.collection('locations').doc(locationId);
    batch.update(locationRef, {
      'productId': productId,
      'currentStock': FieldValue.increment(quantity),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Update product with location info
    final productRef = _firestore.collection('products').doc(productId);
    batch.update(productRef, {
      'locationId': locationId,
      'stock': FieldValue.increment(quantity),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }

  static Future<void> removeProductFromLocation({
    required String productId,
    required String locationId,
    required int quantity,
  }) async {
    final batch = _firestore.batch();
    
    // Update location
    final locationRef = _firestore.collection('locations').doc(locationId);
    batch.update(locationRef, {
      'currentStock': FieldValue.increment(-quantity),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Update product
    final productRef = _firestore.collection('products').doc(productId);
    batch.update(productRef, {
      'stock': FieldValue.increment(-quantity),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }

  // Picking Operations
  static Future<List<Map<String, dynamic>>> getPickingList(String orderId) async {
    // Get order details
    final orderDoc = await _firestore.collection('saleOrders').doc(orderId).get();
    if (!orderDoc.exists) return [];
    
    final orderData = orderDoc.data()!;
    final items = orderData['items'] as List<dynamic>? ?? [];
    
    List<Map<String, dynamic>> pickingItems = [];
    
    for (var item in items) {
      final productId = item['productId'];
      final quantity = item['quantity'] ?? 1;
      
      // Get product details
      final productDoc = await _firestore.collection('products').doc(productId).get();
      if (!productDoc.exists) continue;
      
      final productData = productDoc.data()!;
      
      // Get bin location
      final locationDoc = await _firestore.collection('locations')
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
    
    return pickingItems;
  }

  static Future<void> completePicking(String orderId, List<Map<String, dynamic>> pickedItems) async {
    final batch = _firestore.batch();
    
    // Update order status
    final orderRef = _firestore.collection('saleOrders').doc(orderId);
    batch.update(orderRef, {
      'status': 'fulfilled',
      'fulfilledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Update stock levels for picked items
    for (var item in pickedItems) {
      if (item['picked'] == true) {
        final productId = item['productId'];
        final quantity = item['quantity'];
        
        // Get current location
        final locationDoc = await _firestore.collection('locations')
            .where('productId', isEqualTo: productId)
            .limit(1)
            .get();
        
        if (locationDoc.docs.isNotEmpty) {
          final locationRef = locationDoc.docs.first.reference;
          batch.update(locationRef, {
            'currentStock': FieldValue.increment(-quantity),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        
        // Update product stock
        final productRef = _firestore.collection('products').doc(productId);
        batch.update(productRef, {
          'stock': FieldValue.increment(-quantity),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
    
    await batch.commit();
  }

  // Analytics
  static Future<Map<String, dynamic>> getBinAnalytics(String clientId) async {
    // Get all bins for client
    final locationsSnapshot = await _firestore.collection('locations')
        .where('clientId', isEqualTo: clientId)
        .get();
    
    // Get products for client
    final productsSnapshot = await _firestore.collection('products')
        .where('clientId', isEqualTo: clientId)
        .get();
    
    final totalBins = locationsSnapshot.docs.length;
    final activeBins = locationsSnapshot.docs
        .where((doc) => doc.data()['status'] == 'active')
        .length;
    
    final totalProducts = productsSnapshot.docs.length;
    final totalValue = productsSnapshot.docs.fold<double>(0, (sum, doc) {
      final data = doc.data();
      return sum + ((data['price'] ?? 0) * (data['stock'] ?? 0));
    });
    
    final binUtilization = totalBins > 0 ? (activeBins / totalBins) * 100 : 0.0;
    
    // Calculate cost savings
    final averageBinCost = 15.0; // Monthly cost per bin
    final monthlyBinCost = activeBins * averageBinCost;
    final potentialSavings = (totalBins - activeBins) * averageBinCost;
    
    return {
      'totalBins': totalBins,
      'activeBins': activeBins,
      'utilizationRate': binUtilization,
      'totalProducts': totalProducts,
      'totalValue': totalValue,
      'monthlyBinCost': monthlyBinCost,
      'potentialSavings': potentialSavings,
    };
  }

  static Future<List<Map<String, dynamic>>> getBinDetails(String clientId) async {
    final locationsSnapshot = await _firestore.collection('locations')
        .where('clientId', isEqualTo: clientId)
        .get();
    
    return locationsSnapshot.docs.map((doc) {
      final data = doc.data();
      return {
        'binId': doc.id,
        'location': 'Z${data['zone']}-A${data['aisle']}-S${data['shelf']}-B${data['bin']}',
        'status': data['status'],
        'capacity': data['capacity'] ?? 0,
        'currentStock': data['currentStock'] ?? 0,
        'utilization': data['capacity'] > 0 
            ? ((data['currentStock'] ?? 0) / data['capacity']) * 100 
            : 0.0,
        'lastUpdated': data['updatedAt'],
        'productId': data['productId'],
      };
    }).toList();
  }

  // Stock Movement Tracking
  static Future<void> recordStockMovement({
    required String productId,
    required String locationId,
    required int quantity,
    required String movementType, // 'in', 'out', 'transfer'
    required String reason,
    String? fromLocationId,
    String? toLocationId,
  }) async {
    await _firestore.collection('stockMovements').add({
      'productId': productId,
      'locationId': locationId,
      'quantity': quantity,
      'movementType': movementType,
      'reason': reason,
      'fromLocationId': fromLocationId,
      'toLocationId': toLocationId,
      'timestamp': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Warehouse Optimization
  static Future<List<Map<String, dynamic>>> getOptimizationSuggestions(String clientId) async {
    final binDetails = await getBinDetails(clientId);
    List<Map<String, dynamic>> suggestions = [];
    
    // Find underutilized bins
    final underutilizedBins = binDetails.where((bin) => 
        bin['utilization'] < 30 && bin['status'] == 'active').toList();
    
    if (underutilizedBins.isNotEmpty) {
      suggestions.add({
        'type': 'underutilized_bins',
        'title': 'Underutilized Bins',
        'description': '${underutilizedBins.length} bins are less than 30% utilized',
        'suggestion': 'Consider consolidating products or reducing bin count',
        'potentialSavings': underutilizedBins.length * 15.0,
        'priority': 'high',
      });
    }
    
    // Find empty bins
    final emptyBins = binDetails.where((bin) => 
        bin['currentStock'] == 0 && bin['status'] == 'active').toList();
    
    if (emptyBins.isNotEmpty) {
      suggestions.add({
        'type': 'empty_bins',
        'title': 'Empty Bins',
        'description': '${emptyBins.length} bins are completely empty',
        'suggestion': 'Deactivate empty bins to reduce costs',
        'potentialSavings': emptyBins.length * 15.0,
        'priority': 'medium',
      });
    }
    
    return suggestions;
  }
}
