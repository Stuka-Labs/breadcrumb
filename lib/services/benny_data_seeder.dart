import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class BennyDataSeeder {
  static final BennyDataSeeder _instance = BennyDataSeeder._internal();
  factory BennyDataSeeder() => _instance;
  BennyDataSeeder._internal();

  // Benny's company details
  static const String bennyCompanyId = 'benny_warehouse_inc';
  static const String bennyCompanyName = 'Benny\'s Warehouse Inc.';
  static const String bennyEmail = 'benny@warehouse.com';
  static const String bennyPhone = '+1-555-BENNY-01';

  // Start seeding all data
  static Future<void> seedAllData() async {
    try {
      developer.log('🚀 Starting Benny data seeding...', name: 'BennySeeder');
      
      // Seed in order of dependencies
      await _seedCompany();
      await _seedWarehouse();
      await _seedLocations();
      await _seedProducts();
      await _seedCustomers();
      await _seedSuppliers();
      await _seedUsers();
      await _seedOrders();
      await _seedStockTakes();
      await _seedReports();
      await _seedDocuments();
      
      developer.log('✅ Benny data seeding completed successfully!', name: 'BennySeeder');
    } catch (e) {
      developer.log('❌ Error seeding Benny data: $e', name: 'BennySeeder', error: e);
    }
  }

  // Seed company information
  static Future<void> _seedCompany() async {
    final companyData = {
      'id': bennyCompanyId,
      'name': bennyCompanyName,
      'email': bennyEmail,
      'phone': bennyPhone,
      'address': {
        'street': '123 Warehouse Way',
        'city': 'Bennyville',
        'state': 'CA',
        'zip': '90210',
        'country': 'USA'
      },
      'industry': 'E-commerce & Retail',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'active'
    };

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(bennyCompanyId)
        .set(companyData);
    
    developer.log('🏢 Company data seeded: $bennyCompanyName', name: 'BennySeeder');
  }

  // Seed warehouse
  static Future<void> _seedWarehouse() async {
    final warehouseData = {
      'id': 'benny_main_warehouse',
      'companyId': bennyCompanyId,
      'name': 'Benny\'s Main Distribution Center',
      'address': {
        'street': '456 Distribution Drive',
        'city': 'Bennyville',
        'state': 'CA',
        'zip': '90210',
        'country': 'USA'
      },
      'capacity': {
        'totalPallets': 10000,
        'totalSqFt': 50000,
        'temperatureControlled': true
      },
      'settings': {
        'palletLabeling': true,
        'expiryWarnings': true,
        'autoEmailOnDispatch': true,
        'labeling': 'enabled'
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'active'
    };

    await FirebaseFirestore.instance
        .collection('warehouses')
        .doc('benny_main_warehouse')
        .set(warehouseData);
    
    developer.log('🏭 Warehouse data seeded: Benny\'s Main Distribution Center', name: 'BennySeeder');
  }

  // Seed warehouse locations
  static Future<void> _seedLocations() async {
    final locations = <Map<String, dynamic>>[
      {
        'id': 'A-01-01',
        'warehouseId': 'benny_main_warehouse',
        'zone': 'A',
        'shelf': '01',
        'bin': '01',
        'capacity': 100,
        'currentStock': 75,
        'type': 'pallet',
        'status': 'active'
      },
      {
        'id': 'A-01-02',
        'warehouseId': 'benny_main_warehouse',
        'zone': 'A',
        'shelf': '01',
        'bin': '02',
        'capacity': 100,
        'currentStock': 45,
        'type': 'pallet',
        'status': 'active'
      },
      {
        'id': 'B-02-01',
        'warehouseId': 'benny_main_warehouse',
        'zone': 'B',
        'shelf': '02',
        'bin': '01',
        'capacity': 150,
        'currentStock': 120,
        'type': 'pallet',
        'status': 'active'
      },
      {
        'id': 'C-03-01',
        'warehouseId': 'benny_main_warehouse',
        'zone': 'C',
        'shelf': '03',
        'bin': '01',
        'capacity': 200,
        'currentStock': 0,
        'type': 'pallet',
        'status': 'available'
      }
    ];

    for (final location in locations) {
      location['createdAt'] = FieldValue.serverTimestamp();
      location['updatedAt'] = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance
          .collection('locations')
          .doc(location['id'] as String)
          .set(location);
    }
    
    developer.log('📍 ${locations.length} warehouse locations seeded', name: 'BennySeeder');
  }

  // Seed products
  static Future<void> _seedProducts() async {
    final products = <Map<String, dynamic>>[
      {
        'id': 'PROD-001',
        'name': 'Benny\'s Premium Coffee Beans',
        'sku': 'BENNY-COFFEE-001',
        'quantity': 500,
        'warehouseId': 'benny_main_warehouse',
        'locationId': 'A-01-01',
        'category': 'Beverages',
        'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
        'status': 'active',
        'companyId': bennyCompanyId,
        'price': 24.99,
        'weight': 2.5,
        'dimensions': {'length': 30, 'width': 20, 'height': 15}
      },
      {
        'id': 'PROD-002',
        'name': 'Benny\'s Organic Tea Collection',
        'sku': 'BENNY-TEA-002',
        'quantity': 300,
        'warehouseId': 'benny_main_warehouse',
        'locationId': 'A-01-02',
        'category': 'Beverages',
        'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 730))),
        'status': 'active',
        'companyId': bennyCompanyId,
        'price': 19.99,
        'weight': 1.8,
        'dimensions': {'length': 25, 'width': 18, 'height': 12}
      },
      {
        'id': 'PROD-003',
        'name': 'Benny\'s Artisan Chocolate Bars',
        'sku': 'BENNY-CHOC-003',
        'quantity': 800,
        'warehouseId': 'benny_main_warehouse',
        'locationId': 'B-02-01',
        'category': 'Confectionery',
        'expiryDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 180))),
        'status': 'active',
        'companyId': bennyCompanyId,
        'price': 8.99,
        'weight': 0.15,
        'dimensions': {'length': 12, 'width': 8, 'height': 2}
      }
    ];

    for (final product in products) {
      product['createdAt'] = FieldValue.serverTimestamp();
      product['updatedAt'] = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance
          .collection('products')
          .doc(product['id'] as String)
          .set(product);
    }
    
    developer.log('📦 ${products.length} products seeded', name: 'BennySeeder');
  }

  // Seed customers
  static Future<void> _seedCustomers() async {
    final customers = <Map<String, dynamic>>[
      {
        'id': 'CUST-001',
        'name': 'Coffee Corner Cafe',
        'email': 'orders@coffeecorner.com',
        'phone': '+1-555-COFFEE-1',
        'address': {
          'street': '789 Coffee Street',
          'city': 'Cafeville',
          'state': 'CA',
          'zip': '90211',
          'country': 'USA'
        },
        'companyId': bennyCompanyId,
        'creditLimit': 5000.0,
        'status': 'active'
      },
      {
        'id': 'CUST-002',
        'name': 'Tea Time Boutique',
        'email': 'purchasing@teatime.com',
        'phone': '+1-555-TEATIME-2',
        'address': {
          'street': '456 Tea Avenue',
          'city': 'Teaville',
          'state': 'CA',
          'zip': '90212',
          'country': 'USA'
        },
        'companyId': bennyCompanyId,
        'creditLimit': 3000.0,
        'status': 'active'
      },
      {
        'id': 'CUST-003',
        'name': 'Sweet Treats Market',
        'email': 'orders@sweettreats.com',
        'phone': '+1-555-SWEETS-3',
        'address': {
          'street': '321 Candy Lane',
          'city': 'Sweetville',
          'state': 'CA',
          'zip': '90213',
          'country': 'USA'
        },
        'companyId': bennyCompanyId,
        'creditLimit': 4000.0,
        'status': 'active'
      }
    ];

    for (final customer in customers) {
      customer['createdAt'] = FieldValue.serverTimestamp();
      customer['updatedAt'] = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance
          .collection('customers')
          .doc(customer['id'] as String)
          .set(customer);
    }
    
    developer.log('👥 ${customers.length} customers seeded', name: 'BennySeeder');
  }

  // Seed suppliers
  static Future<void> _seedSuppliers() async {
    final suppliers = <Map<String, dynamic>>[
      {
        'id': 'SUPP-001',
        'name': 'Global Coffee Importers',
        'email': 'orders@globalcoffee.com',
        'phone': '+1-555-GLOBAL-1',
        'address': {
          'street': '100 Import Street',
          'city': 'Importville',
          'state': 'CA',
          'zip': '90214',
          'country': 'USA'
        },
        'companyId': bennyCompanyId,
        'paymentTerms': 'Net 30',
        'status': 'active'
      },
      {
        'id': 'SUPP-002',
        'name': 'Premium Tea Distributors',
        'email': 'sales@premiumtea.com',
        'phone': '+1-555-PREMIUM-2',
        'address': {
          'street': '200 Tea Import Lane',
          'city': 'Teaimport',
          'state': 'CA',
          'zip': '90215',
          'country': 'USA'
        },
        'companyId': bennyCompanyId,
        'paymentTerms': 'Net 45',
        'status': 'active'
      }
    ];

    for (final supplier in suppliers) {
      supplier['createdAt'] = FieldValue.serverTimestamp();
      supplier['updatedAt'] = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance
          .collection('suppliers')
          .doc(supplier['id'] as String)
          .set(supplier);
    }
    
    developer.log('🏭 ${suppliers.length} suppliers seeded', name: 'BennySeeder');
  }

  // Seed users
  static Future<void> _seedUsers() async {
    final users = <Map<String, dynamic>>[
      {
        'id': 'USER-001',
        'email': 'benny@warehouse.com',
        'name': 'Benny Manager',
        'role': 'admin',
        'companyId': bennyCompanyId,
        'warehouseId': 'benny_main_warehouse',
        'status': 'active'
      },
      {
        'id': 'USER-002',
        'email': 'packer@warehouse.com',
        'name': 'Benny Packer',
        'role': 'packer',
        'companyId': bennyCompanyId,
        'warehouseId': 'benny_main_warehouse',
        'status': 'active'
      },
      {
        'id': 'USER-003',
        'email': 'driver@warehouse.com',
        'name': 'Benny Driver',
        'role': 'driver',
        'companyId': bennyCompanyId,
        'warehouseId': 'benny_main_warehouse',
        'status': 'active'
      }
    ];

    for (final user in users) {
      user['createdAt'] = FieldValue.serverTimestamp();
      user['updatedAt'] = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user['id'] as String)
          .set(user);
    }
    
    developer.log('👤 ${users.length} users seeded', name: 'BennySeeder');
  }

  // Seed orders
  static Future<void> _seedOrders() async {
    final orders = <Map<String, dynamic>>[
      {
        'id': 'SO-001',
        'type': 'sale',
        'status': 'pending',
        'customerId': 'CUST-001',
        'warehouseId': 'benny_main_warehouse',
        'companyId': bennyCompanyId,
        'orderDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 2))),
        'expectedDelivery': Timestamp.fromDate(DateTime.now().add(const Duration(days: 3))),
        'totalAmount': 124.95,
        'products': [
          {
            'productId': 'PROD-001',
            'quantity': 5,
            'unitPrice': 24.99,
            'status': 'pending'
          }
        ],
        'shippingAddress': {
          'street': '789 Coffee Street',
          'city': 'Cafeville',
          'state': 'CA',
          'zip': '90211',
          'country': 'USA'
        }
      },
      {
        'id': 'SO-002',
        'type': 'sale',
        'status': 'fulfilled',
        'customerId': 'CUST-002',
        'warehouseId': 'benny_main_warehouse',
        'companyId': bennyCompanyId,
        'orderDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 5))),
        'fulfilledDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'totalAmount': 59.97,
        'products': [
          {
            'productId': 'PROD-002',
            'quantity': 3,
            'unitPrice': 19.99,
            'status': 'fulfilled'
          }
        ],
        'shippingAddress': {
          'street': '456 Tea Avenue',
          'city': 'Teaville',
          'state': 'CA',
          'zip': '90212',
          'country': 'USA'
        }
      },
      {
        'id': 'PO-001',
        'type': 'purchase',
        'status': 'pending',
        'supplierId': 'SUPP-001',
        'warehouseId': 'benny_main_warehouse',
        'companyId': bennyCompanyId,
        'orderDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'expectedDelivery': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
        'totalAmount': 249.90,
        'products': [
          {
            'productId': 'PROD-001',
            'quantity': 10,
            'unitPrice': 24.99,
            'status': 'ordered'
          }
        ]
      }
    ];

    for (final order in orders) {
      order['createdAt'] = FieldValue.serverTimestamp();
      order['updatedAt'] = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(order['id'] as String)
          .set(order);
    }
    
    developer.log('📋 ${orders.length} orders seeded', name: 'BennySeeder');
  }

  // Seed stock takes
  static Future<void> _seedStockTakes() async {
    final stockTakes = <Map<String, dynamic>>[
      {
        'id': 'ST-001',
        'warehouseId': 'benny_main_warehouse',
        'companyId': bennyCompanyId,
        'createdBy': 'USER-001',
        'status': 'completed',
        'startDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7))),
        'completedDate': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 6))),
        'items': [
          {
            'productId': 'PROD-001',
            'expectedQuantity': 500,
            'actualQuantity': 498,
            'variance': -2,
            'locationId': 'A-01-01'
          },
          {
            'productId': 'PROD-002',
            'expectedQuantity': 300,
            'actualQuantity': 300,
            'variance': 0,
            'locationId': 'A-01-02'
          }
        ]
      }
    ];

    for (final stockTake in stockTakes) {
      stockTake['createdAt'] = FieldValue.serverTimestamp();
      stockTake['updatedAt'] = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance
          .collection('stockTakes')
          .doc(stockTake['id'] as String)
          .set(stockTake);
    }
    
    developer.log('📊 ${stockTakes.length} stock takes seeded', name: 'BennySeeder');
  }

  // Seed reports
  static Future<void> _seedReports() async {
    final reports = <Map<String, dynamic>>[
      {
        'id': 'REP-001',
        'type': 'sales_summary',
        'title': 'Weekly Sales Report',
        'warehouseId': 'benny_main_warehouse',
        'companyId': bennyCompanyId,
        'generatedBy': 'USER-001',
        'generatedAt': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1))),
        'data': {
          'totalSales': 184.92,
          'ordersProcessed': 2,
          'topProduct': 'PROD-001',
          'topCustomer': 'CUST-001'
        },
        'status': 'completed'
      },
      {
        'id': 'REP-002',
        'type': 'inventory_status',
        'title': 'Current Inventory Report',
        'warehouseId': 'benny_main_warehouse',
        'companyId': bennyCompanyId,
        'generatedBy': 'USER-001',
        'generatedAt': Timestamp.fromDate(DateTime.now()),
        'data': {
          'totalProducts': 3,
          'totalQuantity': 1600,
          'lowStockItems': ['PROD-002'],
          'outOfStockItems': ['PROD-003']
        },
        'status': 'completed'
      }
    ];

    for (final report in reports) {
      report['createdAt'] = FieldValue.serverTimestamp();
      report['updatedAt'] = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(report['id'] as String)
          .set(report);
    }
    
    developer.log('📈 ${reports.length} reports seeded', name: 'BennySeeder');
  }

  // Seed documents
  static Future<void> _seedDocuments() async {
    final documents = <Map<String, dynamic>>[
      {
        'id': 'DOC-001',
        'type': 'invoice',
        'title': 'Invoice SO-002',
        'reference': 'SO-002',
        'warehouseId': 'benny_main_warehouse',
        'companyId': bennyCompanyId,
        'uploadedBy': 'USER-001',
        'fileSize': 245760,
        'fileType': 'pdf',
        'status': 'active'
      },
      {
        'id': 'DOC-002',
        'type': 'purchase_order',
        'title': 'Purchase Order PO-001',
        'reference': 'PO-001',
        'warehouseId': 'benny_main_warehouse',
        'companyId': bennyCompanyId,
        'uploadedBy': 'USER-001',
        'fileSize': 189440,
        'fileType': 'pdf',
        'status': 'active'
      }
    ];

    for (final document in documents) {
      document['createdAt'] = FieldValue.serverTimestamp();
      document['updatedAt'] = FieldValue.serverTimestamp();
      
      await FirebaseFirestore.instance
          .collection('documents')
          .doc(document['id'] as String)
          .set(document);
    }
    
    developer.log('📄 ${documents.length} documents seeded', name: 'BennySeeder');
  }

  // Clear all Benny data (for testing)
  static Future<void> clearAllBennyData() async {
    try {
      final collections = [
        'companies', 'warehouses', 'locations', 'products', 
        'customers', 'suppliers', 'users', 'orders', 
        'stockTakes', 'reports', 'documents'
      ];

      for (final collection in collections) {
        final query = await FirebaseFirestore.instance
            .collection(collection)
            .where('companyId', isEqualTo: bennyCompanyId)
            .get();
        
        for (final doc in query.docs) {
          await doc.reference.delete();
        }
      }
      
      developer.log('🗑️ All Benny data cleared', name: 'BennySeeder');
    } catch (e) {
      developer.log('❌ Error clearing Benny data: $e', name: 'BennySeeder', error: e);
    }
  }
}
