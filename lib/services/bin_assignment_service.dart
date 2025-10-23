import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BinAssignmentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Assign bin to client with product
  static Future<void> assignBinToClient({
    required String binId,
    required String clientId,
    required String productId,
    required int quantity,
    String? notes,
  }) async {
    try {
      // Update the bin with client assignment
      await _firestore.collection('locations').doc(binId).update({
        'clientId': clientId,
        'productId': productId,
        'currentStock': quantity,
        'isFilled': true,
        'assignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'notes': notes,
      });

      // Create a stock movement record
      await _firestore.collection('stockMovements').add({
        'binId': binId,
        'clientId': clientId,
        'productId': productId,
        'movementType': 'assignment',
        'quantity': quantity,
        'previousStock': 0,
        'newStock': quantity,
        'notes': 'Initial bin assignment to client',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Bin $binId assigned to client $clientId with product $productId');
    } catch (e) {
      debugPrint('Error assigning bin: $e');
      throw Exception('Failed to assign bin: $e');
    }
  }

  // Get available bins for assignment
  static Future<List<Map<String, dynamic>>> getAvailableBins() async {
    try {
      // Get all bins from the warehouse blueprint
      final snapshot = await _firestore
          .collection('locations')
          .get();
      
      // Filter for available bins (not filled and active)
      final availableBins = snapshot.docs.where((doc) {
        final data = doc.data();
        final isFilled = data['isFilled'] ?? false;
        final status = data['status'] ?? 'active';
        final clientId = data['clientId'];
        
        // Available if: not filled, active status, and no client assigned
        return !isFilled && status == 'active' && clientId == null;
      }).map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
      
      debugPrint('Found ${availableBins.length} available bins');
      return availableBins;
    } catch (e) {
      debugPrint('Error loading available bins: $e');
      return [];
    }
  }

  // Get client's assigned bins
  static Future<List<Map<String, dynamic>>> getClientBins(String clientId) async {
    try {
      final snapshot = await _firestore
          .collection('locations')
          .where('clientId', isEqualTo: clientId)
          .where('isFilled', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error loading client bins: $e');
      return [];
    }
  }

  // Update bin stock
  static Future<void> updateBinStock({
    required String binId,
    required int newQuantity,
    required String reason,
    String? notes,
  }) async {
    try {
      // Get current bin data
      final binDoc = await _firestore.collection('locations').doc(binId).get();
      if (!binDoc.exists) {
        throw Exception('Bin not found');
      }

      final binData = binDoc.data()!;
      final previousStock = binData['currentStock'] ?? 0;
      final clientId = binData['clientId'];

      // Update bin stock
      await _firestore.collection('locations').doc(binId).update({
        'currentStock': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create stock movement record
      await _firestore.collection('stockMovements').add({
        'binId': binId,
        'clientId': clientId,
        'productId': binData['productId'],
        'movementType': 'stock_update',
        'quantity': newQuantity - previousStock,
        'previousStock': previousStock,
        'newStock': newQuantity,
        'reason': reason,
        'notes': notes,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Bin $binId stock updated from $previousStock to $newQuantity');
    } catch (e) {
      debugPrint('Error updating bin stock: $e');
      throw Exception('Failed to update bin stock: $e');
    }
  }

  // Unassign bin from client
  static Future<void> unassignBin(String binId) async {
    try {
      // Get current bin data
      final binDoc = await _firestore.collection('locations').doc(binId).get();
      if (!binDoc.exists) {
        throw Exception('Bin not found');
      }

      final binData = binDoc.data()!;
      final clientId = binData['clientId'];
      final productId = binData['productId'];
      final currentStock = binData['currentStock'] ?? 0;

      // Update bin to unassigned state
      await _firestore.collection('locations').doc(binId).update({
        'clientId': null,
        'productId': null,
        'currentStock': 0,
        'isFilled': false,
        'unassignedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create stock movement record for unassignment
      await _firestore.collection('stockMovements').add({
        'binId': binId,
        'clientId': clientId,
        'productId': productId,
        'movementType': 'unassignment',
        'quantity': -currentStock,
        'previousStock': currentStock,
        'newStock': 0,
        'notes': 'Bin unassigned from client',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Bin $binId unassigned from client');
    } catch (e) {
      debugPrint('Error unassigning bin: $e');
      throw Exception('Failed to unassign bin: $e');
    }
  }

  // Get bin assignment history
  static Future<List<Map<String, dynamic>>> getBinAssignmentHistory(String binId) async {
    try {
      final snapshot = await _firestore
          .collection('stockMovements')
          .where('binId', isEqualTo: binId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('Error loading bin assignment history: $e');
      return [];
    }
  }

  // Get client's warehouse utilization
  static Future<Map<String, dynamic>> getClientWarehouseUtilization(String clientId) async {
    try {
      final bins = await getClientBins(clientId);
      
      if (bins.isEmpty) {
        return {
          'totalBins': 0,
          'totalCapacity': 0,
          'totalStock': 0,
          'utilizationRate': 0.0,
          'emptyBins': 0,
          'fullBins': 0,
        };
      }

      int totalCapacity = 0;
      int totalStock = 0;
      int emptyBins = 0;
      int fullBins = 0;

      for (final bin in bins) {
        final capacity = (bin['capacity'] ?? 0) as int;
        final stock = (bin['currentStock'] ?? 0) as int;
        
        totalCapacity += capacity;
        totalStock += stock;
        
        if (stock == 0) {
          emptyBins++;
        } else if (stock >= capacity) {
          fullBins++;
        }
      }

      final utilizationRate = totalCapacity > 0 ? (totalStock / totalCapacity) * 100 : 0.0;

      return {
        'totalBins': bins.length,
        'totalCapacity': totalCapacity,
        'totalStock': totalStock,
        'utilizationRate': utilizationRate,
        'emptyBins': emptyBins,
        'fullBins': fullBins,
      };
    } catch (e) {
      debugPrint('Error calculating warehouse utilization: $e');
      return {
        'totalBins': 0,
        'totalCapacity': 0,
        'totalStock': 0,
        'utilizationRate': 0.0,
        'emptyBins': 0,
        'fullBins': 0,
      };
    }
  }

  // Bulk assign bins to client
  static Future<void> bulkAssignBins({
    required String clientId,
    required List<Map<String, dynamic>> assignments,
  }) async {
    try {
      final batch = _firestore.batch();
      
      for (final assignment in assignments) {
        final binRef = _firestore.collection('locations').doc(assignment['binId']);
        
        batch.update(binRef, {
          'clientId': clientId,
          'productId': assignment['productId'],
          'currentStock': assignment['quantity'],
          'isFilled': true,
          'assignedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Create stock movement record
        final movementRef = _firestore.collection('stockMovements').doc();
        batch.set(movementRef, {
          'binId': assignment['binId'],
          'clientId': clientId,
          'productId': assignment['productId'],
          'movementType': 'bulk_assignment',
          'quantity': assignment['quantity'],
          'previousStock': 0,
          'newStock': assignment['quantity'],
          'notes': 'Bulk bin assignment to client',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      debugPrint('Bulk assigned ${assignments.length} bins to client $clientId');
    } catch (e) {
      debugPrint('Error bulk assigning bins: $e');
      throw Exception('Failed to bulk assign bins: $e');
    }
  }
}
