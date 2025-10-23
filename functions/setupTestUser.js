const { onCall } = require('firebase-functions/v2/https');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

/**
 * Cloud Function to create a comprehensive test user for WMS demonstration
 * This function sets up client@gmail.com with realistic sample data
 */
exports.setupTestUser = onCall(async (request) => {
  const auth = getAuth();
  const db = getFirestore();
  
  const TEST_USER_EMAIL = 'client@gmail.com';
  const TEST_USER_PASSWORD = 'demo123456';
  const TEST_USER_UID = 'demo-client-uid-12345';
  
  try {
    // Check if user already exists
    try {
      await auth.getUser(TEST_USER_UID);
      return {
        success: false,
        message: 'Test user already exists',
        email: TEST_USER_EMAIL,
        password: TEST_USER_PASSWORD
      };
    } catch (error) {
      // User doesn't exist, continue with creation
    }
    
    // Create Firebase Auth user
    const userRecord = await auth.createUser({
      uid: TEST_USER_UID,
      email: TEST_USER_EMAIL,
      password: TEST_USER_PASSWORD,
      displayName: 'Demo Client',
      emailVerified: true
    });
    
    // Create user document in Firestore
    await db.collection('users').doc(TEST_USER_UID).set({
      email: TEST_USER_EMAIL,
      role: 'client',
      displayName: 'Demo Client',
      companyName: 'Demo E-commerce Store',
      createdAt: new Date(),
      isActive: true,
      subscription: {
        plan: 'premium',
        status: 'active',
        features: ['shopify_integration', 'analytics', 'ai_insights', 'multi_platform']
      }
    });
    
    // Create sample shop connections
    const shopConnections = [
      {
        clientId: TEST_USER_UID,
        shop: 'demo-store.myshopify.com',
        shopName: 'Demo E-commerce Store',
        shopEmail: 'demo@store.com',
        shopDomain: 'demo-store.com',
        accessToken: 'demo-access-token-123',
        scope: 'read_orders,read_products,read_customers,write_orders',
        connectedAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        status: 'active',
        lastSync: new Date(Date.now() - 2 * 60 * 60 * 1000),
        lastSyncCount: 15,
        platform: 'shopify'
      },
      {
        clientId: TEST_USER_UID,
        shop: 'demo-etsy-store.etsy.com',
        shopName: 'Demo Etsy Store',
        shopEmail: 'demo@etsy.com',
        shopDomain: 'demo-etsy-store.etsy.com',
        accessToken: 'demo-etsy-token-456',
        scope: 'read_orders,read_listings',
        connectedAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000),
        status: 'active',
        lastSync: new Date(Date.now() - 1 * 60 * 60 * 1000),
        lastSyncCount: 8,
        platform: 'etsy'
      }
    ];
    
    for (const connection of shopConnections) {
      await db.collection('shopConnections').add(connection);
    }
    
    // Create sample products
    const products = [
      {
        clientId: TEST_USER_UID,
        name: 'Premium Wireless Headphones',
        sku: 'PWH-001',
        category: 'Electronics',
        price: 199.99,
        cost: 120.00,
        weight: 0.5,
        dimensions: { length: 20, width: 15, height: 8 },
        packaging: 'Cardboard Box',
        filler: 'Bubble Wrap',
        specialLabel: 'Fragile',
        locationId: 'A-01-001',
        status: 'active',
        stockQuantity: 150,
        reorderPoint: 20,
        createdAt: new Date(Date.now() - 60 * 24 * 60 * 60 * 1000),
        updatedAt: new Date()
      },
      {
        clientId: TEST_USER_UID,
        name: 'Organic Cotton T-Shirt',
        sku: 'OCT-002',
        category: 'Clothing',
        price: 29.99,
        cost: 15.00,
        weight: 0.2,
        dimensions: { length: 30, width: 25, height: 2 },
        packaging: 'Poly Bag',
        filler: 'None',
        specialLabel: 'Eco-Friendly',
        locationId: 'B-02-001',
        status: 'active',
        stockQuantity: 300,
        reorderPoint: 50,
        createdAt: new Date(Date.now() - 45 * 24 * 60 * 60 * 1000),
        updatedAt: new Date()
      },
      {
        clientId: TEST_USER_UID,
        name: 'Stainless Steel Water Bottle',
        sku: 'SSW-003',
        category: 'Accessories',
        price: 24.99,
        cost: 12.00,
        weight: 0.3,
        dimensions: { length: 25, width: 8, height: 8 },
        packaging: 'Cardboard Box',
        filler: 'Paper',
        specialLabel: 'BPA-Free',
        locationId: 'C-03-001',
        status: 'active',
        stockQuantity: 200,
        reorderPoint: 30,
        createdAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        updatedAt: new Date()
      },
      {
        clientId: TEST_USER_UID,
        name: 'LED Desk Lamp',
        sku: 'LED-004',
        category: 'Home & Office',
        price: 89.99,
        cost: 45.00,
        weight: 1.2,
        dimensions: { length: 40, width: 15, height: 15 },
        packaging: 'Cardboard Box',
        filler: 'Styrofoam',
        specialLabel: 'Energy Star',
        locationId: 'D-04-001',
        status: 'active',
        stockQuantity: 75,
        reorderPoint: 15,
        createdAt: new Date(Date.now() - 20 * 24 * 60 * 60 * 1000),
        updatedAt: new Date()
      }
    ];
    
    for (const product of products) {
      await db.collection('products').add(product);
    }
    
    // Create sample orders
    const orders = [
      {
        clientId: TEST_USER_UID,
        orderNumber: 'SO-2024-001',
        customerName: 'John Smith',
        customerEmail: 'john.smith@email.com',
        customerPhone: '+1-555-0123',
        shippingAddress: {
          street: '123 Main St',
          city: 'New York',
          state: 'NY',
          zipCode: '10001',
          country: 'USA'
        },
        items: [
          { sku: 'PWH-001', name: 'Premium Wireless Headphones', quantity: 1, price: 199.99 },
          { sku: 'OCT-002', name: 'Organic Cotton T-Shirt', quantity: 2, price: 29.99 }
        ],
        subtotal: 259.97,
        shipping: 9.99,
        tax: 21.60,
        total: 291.56,
        status: 'pending',
        priority: 'normal',
        createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
        updatedAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000)
      },
      {
        clientId: TEST_USER_UID,
        orderNumber: 'SO-2024-002',
        customerName: 'Sarah Johnson',
        customerEmail: 'sarah.j@email.com',
        customerPhone: '+1-555-0456',
        shippingAddress: {
          street: '456 Oak Ave',
          city: 'Los Angeles',
          state: 'CA',
          zipCode: '90210',
          country: 'USA'
        },
        items: [
          { sku: 'SSW-003', name: 'Stainless Steel Water Bottle', quantity: 3, price: 24.99 },
          { sku: 'LED-004', name: 'LED Desk Lamp', quantity: 1, price: 89.99 }
        ],
        subtotal: 164.96,
        shipping: 12.99,
        tax: 13.92,
        total: 191.87,
        status: 'processing',
        priority: 'high',
        createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000),
        updatedAt: new Date()
      },
      {
        clientId: TEST_USER_UID,
        orderNumber: 'SO-2024-003',
        customerName: 'Mike Wilson',
        customerEmail: 'mike.w@email.com',
        customerPhone: '+1-555-0789',
        shippingAddress: {
          street: '789 Pine St',
          city: 'Chicago',
          state: 'IL',
          zipCode: '60601',
          country: 'USA'
        },
        items: [
          { sku: 'OCT-002', name: 'Organic Cotton T-Shirt', quantity: 5, price: 29.99 }
        ],
        subtotal: 149.95,
        shipping: 8.99,
        tax: 12.74,
        total: 171.68,
        status: 'shipped',
        priority: 'normal',
        trackingNumber: 'TRK123456789',
        shippedAt: new Date(Date.now() - 6 * 60 * 60 * 1000),
        createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000),
        updatedAt: new Date(Date.now() - 6 * 60 * 60 * 1000)
      }
    ];
    
    for (const order of orders) {
      await db.collection('orders').add(order);
    }
    
    // Create analytics data
    const analyticsData = {
      clientId: TEST_USER_UID,
      period: 'monthly',
      date: new Date(),
      metrics: {
        totalOrders: 47,
        totalRevenue: 12450.75,
        averageOrderValue: 264.91,
        totalProducts: 4,
        totalCustomers: 32,
        fulfillmentRate: 0.96,
        averageDeliveryTime: 2.3,
        returnRate: 0.03,
        customerSatisfaction: 4.7
      },
      salesByPlatform: {
        shopify: 0.65,
        etsy: 0.25,
        amazon: 0.10
      },
      topProducts: [
        { sku: 'PWH-001', name: 'Premium Wireless Headphones', sales: 15, revenue: 2999.85 },
        { sku: 'OCT-002', name: 'Organic Cotton T-Shirt', sales: 28, revenue: 839.72 },
        { sku: 'SSW-003', name: 'Stainless Steel Water Bottle', sales: 12, revenue: 299.88 },
        { sku: 'LED-004', name: 'LED Desk Lamp', sales: 8, revenue: 719.92 }
      ],
      salesTrend: [
        { date: '2024-01-01', revenue: 3200.50 },
        { date: '2024-01-02', revenue: 2850.25 },
        { date: '2024-01-03', revenue: 4100.75 },
        { date: '2024-01-04', revenue: 3650.00 },
        { date: '2024-01-05', revenue: 4200.25 }
      ],
      createdAt: new Date(),
      updatedAt: new Date()
    };
    
    await db.collection('analytics').doc(TEST_USER_UID).set(analyticsData);
    
    // Create warehouse locations
    const locations = [
      { id: 'A-01-001', zone: 'A', aisle: '01', shelf: '001', capacity: 100, currentStock: 150 },
      { id: 'B-02-001', zone: 'B', aisle: '02', shelf: '001', capacity: 200, currentStock: 300 },
      { id: 'C-03-001', zone: 'C', aisle: '03', shelf: '001', capacity: 150, currentStock: 200 },
      { id: 'D-04-001', zone: 'D', aisle: '04', shelf: '001', capacity: 100, currentStock: 75 }
    ];
    
    for (const location of locations) {
      await db.collection('warehouseLocations').add({
        clientId: TEST_USER_UID,
        ...location,
        status: 'active',
        createdAt: new Date(),
        updatedAt: new Date()
      });
    }
    
    return {
      success: true,
      message: 'Test user created successfully',
      email: TEST_USER_EMAIL,
      password: TEST_USER_PASSWORD,
      features: [
        'Shopify integration with sample orders',
        'Product management with 4 sample products',
        'Order processing and fulfillment',
        'Analytics dashboard with real metrics',
        'Warehouse management with locations',
        'Stock movement tracking',
        'Multi-platform support (Shopify + Etsy)'
      ]
    };
    
  } catch (error) {
    console.error('Error creating test user:', error);
    return {
      success: false,
      message: 'Failed to create test user',
      error: error.message
    };
  }
});
