#!/usr/bin/env node

/**
 * Test User Setup Script for Breadcrumb WMS
 * Creates client@gmail.com as a demo user with comprehensive sample data
 * to showcase all WMS functionality
 */

const admin = require('firebase-admin');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin
if (!admin.apps.length) {
  // Try to use default credentials or environment variables
  try {
    initializeApp({
      databaseURL: "https://breadcrumb-wms-default-rtdb.firebaseio.com"
    });
  } catch (error) {
    console.log('Note: This script requires Firebase Admin SDK setup.');
    console.log('Please use the Flutter app demo setup screen instead.');
    console.log('Or set up Firebase Admin credentials in your environment.');
    process.exit(1);
  }
}

const auth = getAuth();
const db = getFirestore();

const TEST_USER_EMAIL = 'client@gmail.com';
const TEST_USER_PASSWORD = 'demo123456';
const TEST_USER_UID = 'demo-client-uid-12345';

async function createTestUser() {
  console.log('🚀 Setting up test user: client@gmail.com');
  
  try {
    // Create Firebase Auth user
    const userRecord = await auth.createUser({
      uid: TEST_USER_UID,
      email: TEST_USER_EMAIL,
      password: TEST_USER_PASSWORD,
      displayName: 'Demo Client',
      emailVerified: true
    });
    
    console.log('✅ Firebase Auth user created:', userRecord.uid);
    
    // Create user document in Firestore
    await db.collection('users').doc(TEST_USER_UID).set({
      email: TEST_USER_EMAIL,
      role: 'client',
      displayName: 'Demo Client',
      companyName: 'Demo E-commerce Store',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isActive: true,
      subscription: {
        plan: 'premium',
        status: 'active',
        features: ['shopify_integration', 'analytics', 'ai_insights', 'multi_platform']
      }
    });
    
    console.log('✅ User document created in Firestore');
    
    // Create sample shop connections
    await createSampleShopConnections();
    
    // Create sample products
    await createSampleProducts();
    
    // Create sample orders
    await createSampleOrders();
    
    // Create sample analytics data
    await createSampleAnalytics();
    
    // Create sample warehouse data
    await createSampleWarehouseData();
    
    console.log('🎉 Test user setup complete!');
    console.log('📧 Email: client@gmail.com');
    console.log('🔑 Password: demo123456');
    console.log('👤 Role: client');
    console.log('🏢 Company: Demo E-commerce Store');
    
  } catch (error) {
    console.error('❌ Error creating test user:', error);
    throw error;
  }
}

async function createSampleShopConnections() {
  console.log('📱 Creating sample shop connections...');
  
  const shopConnections = [
    {
      clientId: TEST_USER_UID,
      shop: 'demo-store.myshopify.com',
      shopName: 'Demo E-commerce Store',
      shopEmail: 'demo@store.com',
      shopDomain: 'demo-store.com',
      accessToken: 'demo-access-token-123',
      scope: 'read_orders,read_products,read_customers,write_orders',
      connectedAt: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // 30 days ago
      status: 'active',
      lastSync: new Date(Date.now() - 2 * 60 * 60 * 1000), // 2 hours ago
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
      connectedAt: new Date(Date.now() - 15 * 24 * 60 * 60 * 1000), // 15 days ago
      status: 'active',
      lastSync: new Date(Date.now() - 1 * 60 * 60 * 1000), // 1 hour ago
      lastSyncCount: 8,
      platform: 'etsy'
    }
  ];
  
  for (const connection of shopConnections) {
    await db.collection('shopConnections').add(connection);
  }
  
  console.log('✅ Sample shop connections created');
}

async function createSampleProducts() {
  console.log('📦 Creating sample products...');
  
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
  
  console.log('✅ Sample products created');
}

async function createSampleOrders() {
  console.log('📋 Creating sample orders...');
  
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
      createdAt: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000), // 2 days ago
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
      createdAt: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000), // 1 day ago
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
      shippedAt: new Date(Date.now() - 6 * 60 * 60 * 1000), // 6 hours ago
      createdAt: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000), // 3 days ago
      updatedAt: new Date(Date.now() - 6 * 60 * 60 * 1000)
    }
  ];
  
  for (const order of orders) {
    await db.collection('orders').add(order);
  }
  
  console.log('✅ Sample orders created');
}

async function createSampleAnalytics() {
  console.log('📊 Creating sample analytics data...');
  
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
  
  console.log('✅ Sample analytics data created');
}

async function createSampleWarehouseData() {
  console.log('🏭 Creating sample warehouse data...');
  
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
  
  // Create stock movements
  const stockMovements = [
    {
      clientId: TEST_USER_UID,
      productSku: 'PWH-001',
      movementType: 'inbound',
      quantity: 200,
      reason: 'purchase_order',
      reference: 'PO-2024-001',
      locationId: 'A-01-001',
      timestamp: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) // 7 days ago
    },
    {
      clientId: TEST_USER_UID,
      productSku: 'PWH-001',
      movementType: 'outbound',
      quantity: 50,
      reason: 'order_fulfillment',
      reference: 'SO-2024-001',
      locationId: 'A-01-001',
      timestamp: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000) // 2 days ago
    }
  ];
  
  for (const movement of stockMovements) {
    await db.collection('stockMovements').add(movement);
  }
  
  console.log('✅ Sample warehouse data created');
}

// Run the setup
if (require.main === module) {
  createTestUser()
    .then(() => {
      console.log('\n🎉 Test user setup completed successfully!');
      console.log('\n📋 Demo User Credentials:');
      console.log('   Email: client@gmail.com');
      console.log('   Password: demo123456');
      console.log('\n🚀 Features to showcase:');
      console.log('   • Shopify integration with sample orders');
      console.log('   • Product management with 4 sample products');
      console.log('   • Order processing and fulfillment');
      console.log('   • Analytics dashboard with real metrics');
      console.log('   • Warehouse management with locations');
      console.log('   • Stock movement tracking');
      console.log('   • Multi-platform support (Shopify + Etsy)');
      process.exit(0);
    })
    .catch((error) => {
      console.error('❌ Setup failed:', error);
      process.exit(1);
    });
}

module.exports = { createTestUser };
