import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DemoDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Automatically populates demo data for client@gmail.com
  static Future<void> populateDemoData(String userId) async {
    try {
      debugPrint('Populating demo data for user: $userId');
      
      // Create shop connections
      await _createShopConnections(userId);
      
      // Create sample products
      await _createSampleProducts(userId);
      
      // Create sample orders
      await _createSampleOrders(userId);
      
      // Create analytics data
      await _createAnalyticsData(userId);
      
      // Create warehouse locations
      await _createWarehouseLocations(userId);
      
      // Create stock movements
      await _createStockMovements(userId);
      
      debugPrint('Demo data populated successfully for user: $userId');
    } catch (e) {
      debugPrint('Error populating demo data: $e');
      rethrow;
    }
  }

  static Future<void> _createShopConnections(String userId) async {
    final shopConnections = [
      {
        'clientId': userId,
        'shop': 'demo-store.myshopify.com',
        'shopName': 'Demo E-commerce Store',
        'shopEmail': 'demo@store.com',
        'shopDomain': 'demo-store.com',
        'accessToken': 'demo-access-token-123',
        'scope': 'read_orders,read_products,read_customers,write_orders',
        'connectedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
        'status': 'active',
        'lastSync': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 2))),
        'lastSyncCount': 15,
        'platform': 'shopify'
      },
      {
        'clientId': userId,
        'shop': 'demo-etsy-store.etsy.com',
        'shopName': 'Demo Etsy Store',
        'shopEmail': 'demo@etsy.com',
        'shopDomain': 'demo-etsy-store.etsy.com',
        'accessToken': 'demo-etsy-token-456',
        'scope': 'read_orders,read_listings',
        'connectedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 15))),
        'status': 'active',
        'lastSync': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 1))),
        'lastSyncCount': 8,
        'platform': 'etsy'
      }
    ];
    
    for (final connection in shopConnections) {
      await _firestore.collection('shopConnections').add(connection);
    }
  }

  static Future<void> _createSampleProducts(String userId) async {
    final products = [
      {
        'clientId': userId,
        'name': 'Premium Wireless Headphones',
        'sku': 'PWH-001',
        'category': 'Electronics',
        'price': 199.99,
        'cost': 120.00,
        'weight': 0.5,
        'dimensions': {'length': 20, 'width': 15, 'height': 8},
        'packaging': 'Cardboard Box',
        'filler': 'Bubble Wrap',
        'specialLabel': 'Fragile',
        'locationId': 'A-01-001',
        'status': 'active',
        'stockQuantity': 150,
        'reorderPoint': 20,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 60))),
        'updatedAt': Timestamp.now()
      },
      {
        'clientId': userId,
        'name': 'Organic Cotton T-Shirt',
        'sku': 'OCT-002',
        'category': 'Clothing',
        'price': 29.99,
        'cost': 15.00,
        'weight': 0.2,
        'dimensions': {'length': 30, 'width': 25, 'height': 2},
        'packaging': 'Poly Bag',
        'filler': 'None',
        'specialLabel': 'Eco-Friendly',
        'locationId': 'B-02-001',
        'status': 'active',
        'stockQuantity': 300,
        'reorderPoint': 50,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 45))),
        'updatedAt': Timestamp.now()
      },
      {
        'clientId': userId,
        'name': 'Stainless Steel Water Bottle',
        'sku': 'SSW-003',
        'category': 'Accessories',
        'price': 24.99,
        'cost': 12.00,
        'weight': 0.3,
        'dimensions': {'length': 25, 'width': 8, 'height': 8},
        'packaging': 'Cardboard Box',
        'filler': 'Paper',
        'specialLabel': 'BPA-Free',
        'locationId': 'C-03-001',
        'status': 'active',
        'stockQuantity': 200,
        'reorderPoint': 30,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
        'updatedAt': Timestamp.now()
      },
      {
        'clientId': userId,
        'name': 'LED Desk Lamp',
        'sku': 'LED-004',
        'category': 'Home & Office',
        'price': 89.99,
        'cost': 45.00,
        'weight': 1.2,
        'dimensions': {'length': 40, 'width': 15, 'height': 15},
        'packaging': 'Cardboard Box',
        'filler': 'Styrofoam',
        'specialLabel': 'Energy Star',
        'locationId': 'D-04-001',
        'status': 'active',
        'stockQuantity': 75,
        'reorderPoint': 15,
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 20))),
        'updatedAt': Timestamp.now()
      }
    ];
    
    for (final product in products) {
      await _firestore.collection('products').add(product);
    }
  }

  static Future<void> _createSampleOrders(String userId) async {
    final orders = [
      {
        'clientId': userId,
        'orderNumber': 'SO-2024-001',
        'customerName': 'John Smith',
        'customerEmail': 'john.smith@email.com',
        'customerPhone': '+1-555-0123',
        'shippingAddress': {
          'street': '123 Main St',
          'city': 'New York',
          'state': 'NY',
          'zipCode': '10001',
          'country': 'USA'
        },
        'items': [
          {'sku': 'PWH-001', 'name': 'Premium Wireless Headphones', 'quantity': 1, 'price': 199.99},
          {'sku': 'OCT-002', 'name': 'Organic Cotton T-Shirt', 'quantity': 2, 'price': 29.99}
        ],
        'subtotal': 259.97,
        'shipping': 9.99,
        'tax': 21.60,
        'total': 291.56,
        'status': 'pending',
        'priority': 'normal',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)))
      },
      {
        'clientId': userId,
        'orderNumber': 'SO-2024-002',
        'customerName': 'Sarah Johnson',
        'customerEmail': 'sarah.j@email.com',
        'customerPhone': '+1-555-0456',
        'shippingAddress': {
          'street': '456 Oak Ave',
          'city': 'Los Angeles',
          'state': 'CA',
          'zipCode': '90210',
          'country': 'USA'
        },
        'items': [
          {'sku': 'SSW-003', 'name': 'Stainless Steel Water Bottle', 'quantity': 3, 'price': 24.99},
          {'sku': 'LED-004', 'name': 'LED Desk Lamp', 'quantity': 1, 'price': 89.99}
        ],
        'subtotal': 164.96,
        'shipping': 12.99,
        'tax': 13.92,
        'total': 191.87,
        'status': 'processing',
        'priority': 'high',
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'updatedAt': Timestamp.now()
      },
      {
        'clientId': userId,
        'orderNumber': 'SO-2024-003',
        'customerName': 'Mike Wilson',
        'customerEmail': 'mike.w@email.com',
        'customerPhone': '+1-555-0789',
        'shippingAddress': {
          'street': '789 Pine St',
          'city': 'Chicago',
          'state': 'IL',
          'zipCode': '60601',
          'country': 'USA'
        },
        'items': [
          {'sku': 'OCT-002', 'name': 'Organic Cotton T-Shirt', 'quantity': 5, 'price': 29.99}
        ],
        'subtotal': 149.95,
        'shipping': 8.99,
        'tax': 12.74,
        'total': 171.68,
        'status': 'shipped',
        'priority': 'normal',
        'trackingNumber': 'TRK123456789',
        'shippedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 6))),
        'createdAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 3))),
        'updatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(hours: 6)))
      }
    ];
    
    for (final order in orders) {
      await _firestore.collection('orders').add(order);
    }
  }

  static Future<void> _createAnalyticsData(String userId) async {
    final analyticsData = {
      'clientId': userId,
      'period': 'monthly',
      'date': Timestamp.now(),
      'metrics': {
        'totalOrders': 47,
        'totalRevenue': 12450.75,
        'averageOrderValue': 264.91,
        'totalProducts': 4,
        'totalCustomers': 32,
        'fulfillmentRate': 0.96,
        'averageDeliveryTime': 2.3,
        'returnRate': 0.03,
        'customerSatisfaction': 4.7
      },
      'salesByPlatform': {
        'shopify': 0.65,
        'etsy': 0.25,
        'amazon': 0.10
      },
      'topProducts': [
        {'sku': 'PWH-001', 'name': 'Premium Wireless Headphones', 'sales': 15, 'revenue': 2999.85},
        {'sku': 'OCT-002', 'name': 'Organic Cotton T-Shirt', 'sales': 28, 'revenue': 839.72},
        {'sku': 'SSW-003', 'name': 'Stainless Steel Water Bottle', 'sales': 12, 'revenue': 299.88},
        {'sku': 'LED-004', 'name': 'LED Desk Lamp', 'sales': 8, 'revenue': 719.92}
      ],
      'salesTrend': [
        {'date': '2024-01-01', 'revenue': 3200.50},
        {'date': '2024-01-02', 'revenue': 2850.25},
        {'date': '2024-01-03', 'revenue': 4100.75},
        {'date': '2024-01-04', 'revenue': 3650.00},
        {'date': '2024-01-05', 'revenue': 4200.25}
      ],
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now()
    };
    
    await _firestore.collection('analytics').doc(userId).set(analyticsData);
  }

  static Future<void> _createWarehouseLocations(String userId) async {
    final locations = [
      {'id': 'A-01-001', 'zone': 'A', 'aisle': '01', 'shelf': '001', 'capacity': 100, 'currentStock': 150},
      {'id': 'B-02-001', 'zone': 'B', 'aisle': '02', 'shelf': '001', 'capacity': 200, 'currentStock': 300},
      {'id': 'C-03-001', 'zone': 'C', 'aisle': '03', 'shelf': '001', 'capacity': 150, 'currentStock': 200},
      {'id': 'D-04-001', 'zone': 'D', 'aisle': '04', 'shelf': '001', 'capacity': 100, 'currentStock': 75}
    ];
    
    for (final location in locations) {
      await _firestore.collection('warehouseLocations').add({
        'clientId': userId,
        ...location,
        'status': 'active',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now()
      });
    }
  }

  static Future<void> _createStockMovements(String userId) async {
    final stockMovements = [
      {
        'clientId': userId,
        'productSku': 'PWH-001',
        'movementType': 'inbound',
        'quantity': 200,
        'reason': 'purchase_order',
        'reference': 'PO-2024-001',
        'locationId': 'A-01-001',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)))
      },
      {
        'clientId': userId,
        'productSku': 'PWH-001',
        'movementType': 'outbound',
        'quantity': 50,
        'reason': 'order_fulfillment',
        'reference': 'SO-2024-001',
        'locationId': 'A-01-001',
        'timestamp': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2)))
      }
    ];
    
    for (final movement in stockMovements) {
      await _firestore.collection('stockMovements').add(movement);
    }
  }
}
