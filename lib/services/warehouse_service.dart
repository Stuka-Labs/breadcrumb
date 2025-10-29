import 'package:cloud_firestore/cloud_firestore.dart';
import 'material_service.dart';

class WarehouseService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Order Management Methods
  static Future<void> createOrder(Map<String, dynamic> orderData) async {
    await _db.collection('orders').add({
      ...orderData,
      'status': 'received',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateOrderStatus(String orderId, String status, {Map<String, dynamic>? additionalData}) async {
    final updateData = {
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    
    if (additionalData != null) {
      updateData.addAll(additionalData as Map<String, Object>);
    }
    
    // Add timestamp based on status
    switch (status) {
      case 'packed':
        updateData['packedAt'] = FieldValue.serverTimestamp();
        break;
      case 'shipped':
        updateData['shippedAt'] = FieldValue.serverTimestamp();
        break;
    }
    
    await _db.collection('orders').doc(orderId).update(updateData);
  }

  static Future<List<Map<String, dynamic>>> getOrdersByStatus(String status, {int limit = 20}) async {
    final snapshot = await _db
        .collection('orders')
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  static Future<int> getOrderCountByStatus(String status) async {
    final snapshot = await _db
        .collection('orders')
        .where('status', isEqualTo: status)
        .get();
    
    return snapshot.docs.length;
  }

  // Material Management Methods
  static Future<void> createMaterial(Map<String, dynamic> materialData) async {
    await _db.collection('materials').add({
      ...materialData,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> updateMaterialQuantity(String materialId, int quantity) async {
    await _db.collection('materials').doc(materialId).update({
      'quantity': quantity,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<Map<String, dynamic>>> getMaterials() async {
    final snapshot = await _db
        .collection('materials')
        .orderBy('name')
        .get();
    
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getLowStockMaterials({int threshold = 10}) async {
    final snapshot = await _db
        .collection('materials')
        .where('quantity', isLessThan: threshold)
        .orderBy('quantity')
        .get();
    
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  // Inventory Management Methods
  static Future<List<Map<String, dynamic>>> getLowStockProducts({int threshold = 10}) async {
    final snapshot = await _db
        .collection('products')
        .where('quantity', isLessThan: threshold)
        .orderBy('quantity')
        .get();
    
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  static Future<int> getTotalInventoryCount() async {
    final snapshot = await _db.collection('products').get();
    return snapshot.docs.length;
  }

  // Client Management Methods
  static Future<List<Map<String, dynamic>>> getActiveClients() async {
    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'client')
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    
    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  static Future<int> getActiveClientCount() async {
    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'client')
        .where('isActive', isEqualTo: true)
        .get();
    
    return snapshot.docs.length;
  }

  // Dashboard Statistics Methods
  static Future<Map<String, int>> getDashboardStats() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    // Get orders received today
    final ordersReceivedSnapshot = await _db
        .collection('orders')
        .where('status', isEqualTo: 'received')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    
    // Get orders placed today
    final ordersPlacedSnapshot = await _db
        .collection('saleOrders')
        .where('status', isEqualTo: 'open')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    
    // Get orders shipped today
    final ordersShippedSnapshot = await _db
        .collection('orders')
        .where('status', isEqualTo: 'shipped')
        .where('shippedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    
    // Get orders waiting to ship
    final waitingToShipSnapshot = await _db
        .collection('orders')
        .where('status', isEqualTo: 'ready_to_ship')
        .get();
    
    // Get low stock alerts
    final lowStockSnapshot = await _db
        .collection('products')
        .where('quantity', isLessThan: 10)
        .get();
    
    // Get material stock alerts using MaterialService
    final materialStockAlerts = await MaterialService.getLowStockAlerts();
    
    return {
      'ordersReceived': ordersReceivedSnapshot.docs.length,
      'ordersPlaced': ordersPlacedSnapshot.docs.length,
      'ordersShipped': ordersShippedSnapshot.docs.length,
      'waitingToShip': waitingToShipSnapshot.docs.length,
      'lowStockAlerts': lowStockSnapshot.docs.length,
      'materialStockAlerts': materialStockAlerts.length,
    };
  }

  // Initialize default materials
  static Future<void> initializeDefaultMaterials() async {
    final materials = [
      {
        'name': 'Small Boxes',
        'type': 'packaging',
        'quantity': 100,
        'minQuantity': 20,
        'unit': 'boxes',
        'description': 'Small shipping boxes for small items',
      },
      {
        'name': 'Medium Boxes',
        'type': 'packaging',
        'quantity': 75,
        'minQuantity': 15,
        'unit': 'boxes',
        'description': 'Medium shipping boxes for medium items',
      },
      {
        'name': 'Large Boxes',
        'type': 'packaging',
        'quantity': 50,
        'minQuantity': 10,
        'unit': 'boxes',
        'description': 'Large shipping boxes for large items',
      },
      {
        'name': 'Packing Tape',
        'type': 'packaging',
        'quantity': 200,
        'minQuantity': 50,
        'unit': 'rolls',
        'description': 'Clear packing tape for sealing boxes',
      },
      {
        'name': 'Bubble Wrap',
        'type': 'packaging',
        'quantity': 150,
        'minQuantity': 30,
        'unit': 'rolls',
        'description': 'Bubble wrap for protecting fragile items',
      },
      {
        'name': 'Shipping Labels',
        'type': 'packaging',
        'quantity': 500,
        'minQuantity': 100,
        'unit': 'labels',
        'description': 'Pre-printed shipping labels',
      },
    ];

    for (final material in materials) {
      // Check if material already exists
      final existingSnapshot = await _db
          .collection('materials')
          .where('name', isEqualTo: material['name'])
          .get();
      
      if (existingSnapshot.docs.isEmpty) {
        await createMaterial(material);
      }
    }
  }
}