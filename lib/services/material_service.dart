import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Material types and their properties
  static const Map<String, Map<String, dynamic>> materialTypes = {
    'small_box': {
      'name': 'Small Box',
      'dimensions': {'length': 6, 'width': 4, 'height': 3}, // inches
      'tapeLength': 24, // inches of tape needed
      'cost': 0.50,
    },
    'medium_box': {
      'name': 'Medium Box',
      'dimensions': {'length': 12, 'width': 8, 'height': 6},
      'tapeLength': 48,
      'cost': 1.00,
    },
    'large_box': {
      'name': 'Large Box',
      'dimensions': {'length': 18, 'width': 12, 'height': 9},
      'tapeLength': 72,
      'cost': 1.50,
    },
    'packing_tape': {
      'name': 'Packing Tape',
      'unit': 'feet',
      'cost': 0.05,
    },
    'bubble_wrap': {
      'name': 'Bubble Wrap',
      'unit': 'sq_ft',
      'cost': 0.10,
    },
    'shipping_labels': {
      'name': 'Shipping Labels',
      'unit': 'each',
      'cost': 0.02,
    },
  };

  // Calculate required materials based on product dimensions
  static Map<String, int> calculateMaterialsRequired({
    required double productLength,
    required double productWidth,
    required double productHeight,
    required int quantity,
  }) {
    // Add padding for packaging (2 inches on each side)
    final paddedLength = productLength + 4;
    final paddedWidth = productWidth + 4;
    final paddedHeight = productHeight + 4;

    // Determine box size needed
    String boxType;
    if (paddedLength <= 6 && paddedWidth <= 4 && paddedHeight <= 3) {
      boxType = 'small_box';
    } else if (paddedLength <= 12 && paddedWidth <= 8 && paddedHeight <= 6) {
      boxType = 'medium_box';
    } else {
      boxType = 'large_box';
    }

    // Calculate materials needed
    final boxTapeLength = materialTypes[boxType]!['tapeLength'] as int;
    final totalTapeLength = boxTapeLength * quantity;

    return {
      boxType: quantity,
      'packing_tape': totalTapeLength,
      'shipping_labels': quantity,
      'bubble_wrap': (paddedLength * paddedWidth * paddedHeight * quantity / 144).ceil(), // Convert to sq ft
    };
  }

  // Get current material stock
  static Future<List<Map<String, dynamic>>> getMaterialStock() async {
    try {
      final snapshot = await _db.collection('materials').get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    } catch (e) {
      print('Error getting material stock: $e');
      return [];
    }
  }

  // Update material quantity
  static Future<void> updateMaterialQuantity(String materialId, int newQuantity) async {
    try {
      await _db.collection('materials').doc(materialId).update({
        'quantity': newQuantity,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating material quantity: $e');
      throw Exception('Failed to update material quantity');
    }
  }

  // Add new material
  static Future<void> addMaterial({
    required String name,
    required String type,
    required int quantity,
    required int minQuantity,
    required double cost,
  }) async {
    try {
      await _db.collection('materials').add({
        'name': name,
        'type': type,
        'quantity': quantity,
        'minQuantity': minQuantity,
        'cost': cost,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding material: $e');
      throw Exception('Failed to add material');
    }
  }

  // Deduct materials when processing an order
  static Future<void> deductMaterials(Map<String, int> materialsUsed) async {
    try {
      final batch = _db.batch();
      
      for (final entry in materialsUsed.entries) {
        final materialId = entry.key;
        final quantityUsed = entry.value;
        
        // Get current quantity
        final doc = await _db.collection('materials').doc(materialId).get();
        if (doc.exists) {
          final currentQuantity = doc.data()!['quantity'] as int;
          final newQuantity = currentQuantity - quantityUsed;
          
          batch.update(_db.collection('materials').doc(materialId), {
            'quantity': newQuantity,
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
      }
      
      await batch.commit();
    } catch (e) {
      print('Error deducting materials: $e');
      throw Exception('Failed to deduct materials');
    }
  }

  // Get low stock alerts
  static Future<List<Map<String, dynamic>>> getLowStockAlerts() async {
    try {
      final snapshot = await _db.collection('materials').get();
      final alerts = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final quantity = data['quantity'] as int;
        final minQuantity = data['minQuantity'] as int;
        
        if (quantity <= minQuantity) {
          alerts.add({
            'id': doc.id,
            'name': data['name'],
            'type': data['type'],
            'quantity': quantity,
            'minQuantity': minQuantity,
            'status': quantity == 0 ? 'out_of_stock' : 'low_stock',
          });
        }
      }
      
      return alerts;
    } catch (e) {
      print('Error getting low stock alerts: $e');
      return [];
    }
  }

  // Initialize default materials if none exist
  static Future<void> initializeDefaultMaterials() async {
    try {
      final snapshot = await _db.collection('materials').get();
      
      if (snapshot.docs.isEmpty) {
        final batch = _db.batch();
        
        // Add default materials
        final defaultMaterials = [
          {
            'name': 'Small Boxes',
            'type': 'small_box',
            'quantity': 100,
            'minQuantity': 20,
            'cost': 0.50,
          },
          {
            'name': 'Medium Boxes',
            'type': 'medium_box',
            'quantity': 75,
            'minQuantity': 15,
            'cost': 1.00,
          },
          {
            'name': 'Large Boxes',
            'type': 'large_box',
            'quantity': 50,
            'minQuantity': 10,
            'cost': 1.50,
          },
          {
            'name': 'Packing Tape',
            'type': 'packing_tape',
            'quantity': 2000, // feet
            'minQuantity': 200,
            'cost': 0.05,
          },
          {
            'name': 'Bubble Wrap',
            'type': 'bubble_wrap',
            'quantity': 500, // sq ft
            'minQuantity': 50,
            'cost': 0.10,
          },
          {
            'name': 'Shipping Labels',
            'type': 'shipping_labels',
            'quantity': 1000,
            'minQuantity': 100,
            'cost': 0.02,
          },
        ];
        
        for (final material in defaultMaterials) {
          final docRef = _db.collection('materials').doc();
          batch.set(docRef, {
            ...material,
            'createdAt': FieldValue.serverTimestamp(),
            'lastUpdated': FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
      }
    } catch (e) {
      print('Error initializing default materials: $e');
      throw Exception('Failed to initialize materials');
    }
  }

  // Get material cost for an order
  static double calculateOrderMaterialCost(Map<String, int> materialsUsed) {
    double totalCost = 0.0;
    
    for (final entry in materialsUsed.entries) {
      final materialType = entry.key;
      final quantity = entry.value;
      
      if (materialTypes.containsKey(materialType)) {
        final cost = materialTypes[materialType]!['cost'] as double;
        totalCost += cost * quantity;
      }
    }
    
    return totalCost;
  }
}
