import 'package:cloud_firestore/cloud_firestore.dart';

class WarehouseDemoSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedWarehouseDemoData() async {
    try {
      // Create sample warehouse locations
      await _createSampleLocations();
      
      // Create sample products for demo client
      await _createSampleProducts();
      
      // Create sample orders for picking
      await _createSampleOrders();
      
      print('✅ Warehouse demo data seeded successfully!');
    } catch (e) {
      print('❌ Error seeding warehouse demo data: $e');
    }
  }

  static Future<void> _createSampleLocations() async {
    final batch = _firestore.batch();
    
    // Create 2 zones, 2 aisles, 2 shelves, 2 bins each
    for (int zone = 1; zone <= 2; zone++) {
      for (int aisle = 1; aisle <= 2; aisle++) {
        for (int shelf = 1; shelf <= 2; shelf++) {
          for (int bin = 1; bin <= 2; bin++) {
            final locationRef = _firestore.collection('locations').doc();
            batch.set(locationRef, {
              'zone': zone,
              'aisle': aisle,
              'shelf': shelf,
              'bin': bin,
              'capacity': 100,
              'currentStock': 0,
              'status': 'active',
              'clientId': 'client@gmail.com',
              'productId': null,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    }
    
    await batch.commit();
  }

  static Future<void> _createSampleProducts() async {
    final batch = _firestore.batch();
    
    final products = [
      {
        'name': 'BENNY Signature Hoodie',
        'sku': 'BENNY-HOODIE-001',
        'price': 89.99,
        'stock': 45,
        'clientId': 'client@gmail.com',
        'category': 'Apparel',
        'description': 'Premium cotton hoodie with BENNY branding',
      },
      {
        'name': 'BENNY Logo Tee',
        'sku': 'BENNY-TEE-002',
        'price': 39.99,
        'stock': 78,
        'clientId': 'client@gmail.com',
        'category': 'Apparel',
        'description': 'Classic cotton t-shirt with logo print',
      },
      {
        'name': 'BENNY Dad Hat',
        'sku': 'BENNY-CAP-003',
        'price': 29.99,
        'stock': 56,
        'clientId': 'client@gmail.com',
        'category': 'Accessories',
        'description': 'Adjustable dad hat with embroidered logo',
      },
      {
        'name': 'BENNY Denim Jacket',
        'sku': 'BENNY-JACKET-004',
        'price': 129.99,
        'stock': 23,
        'clientId': 'client@gmail.com',
        'category': 'Apparel',
        'description': 'Vintage-style denim jacket with patches',
      },
    ];
    
    for (var product in products) {
      final productRef = _firestore.collection('products').doc();
      batch.set(productRef, {
        ...product,
        'productId': productRef.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    
    await batch.commit();
  }

  static Future<void> _createSampleOrders() async {
    final batch = _firestore.batch();
    
    // Get product IDs
    final productsSnapshot = await _firestore
        .collection('products')
        .where('clientId', isEqualTo: 'client@gmail.com')
        .get();
    
    if (productsSnapshot.docs.isEmpty) return;
    
    final products = productsSnapshot.docs;
    
    final orders = [
      {
        'customerName': 'Alex Chen',
        'customerEmail': 'alex@example.com',
        'status': 'open',
        'total': 145.28,
        'items': [
          {
            'productId': products[0].id,
            'productName': 'BENNY Signature Hoodie',
            'quantity': 1,
            'price': 89.99,
          },
          {
            'productId': products[1].id,
            'productName': 'BENNY Logo Tee',
            'quantity': 1,
            'price': 39.99,
          },
        ],
        'shippingAddress': {
          'street': '123 Fashion Ave',
          'city': 'New York',
          'state': 'NY',
          'zip': '10001',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'customerName': 'Maya Rodriguez',
        'customerEmail': 'maya@example.com',
        'status': 'processing',
        'total': 89.99,
        'items': [
          {
            'productId': products[0].id,
            'productName': 'BENNY Signature Hoodie',
            'quantity': 1,
            'price': 89.99,
          },
        ],
        'shippingAddress': {
          'street': '456 Streetwear Blvd',
          'city': 'Los Angeles',
          'state': 'CA',
          'zip': '90210',
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    ];
    
    for (var order in orders) {
      final orderRef = _firestore.collection('saleOrders').doc();
      batch.set(orderRef, {
        ...order,
        'orderId': orderRef.id,
        'orderNumber': 'BENNY-2024-${orderRef.id.substring(0, 6).toUpperCase()}',
      });
    }
    
    await batch.commit();
  }

  static Future<void> assignProductsToLocations() async {
    try {
      // Get products
      final productsSnapshot = await _firestore
          .collection('products')
          .where('clientId', isEqualTo: 'client@gmail.com')
          .get();
      
      // Get locations
      final locationsSnapshot = await _firestore
          .collection('locations')
          .where('clientId', isEqualTo: 'client@gmail.com')
          .get();
      
      if (productsSnapshot.docs.isEmpty || locationsSnapshot.docs.isEmpty) return;
      
      final batch = _firestore.batch();
      
      // Assign each product to a location
      for (int i = 0; i < productsSnapshot.docs.length && i < locationsSnapshot.docs.length; i++) {
        final product = productsSnapshot.docs[i];
        final location = locationsSnapshot.docs[i];
        final productData = product.data();
        final stock = productData['stock'] ?? 0;
        
        // Update location
        batch.update(location.reference, {
          'productId': product.id,
          'currentStock': stock,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        // Update product
        batch.update(product.reference, {
          'locationId': location.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      print('✅ Products assigned to locations successfully!');
    } catch (e) {
      print('❌ Error assigning products to locations: $e');
    }
  }
}
