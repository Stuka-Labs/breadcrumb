const { onRequest } = require("firebase-functions/v2/https");
const { setGlobalOptions } = require("firebase-functions/v2");
const admin = require("firebase-admin");

// Initialize Firebase Admin
admin.initializeApp();

// Set global options
setGlobalOptions({
  maxInstances: 10,
  memory: "1GiB",
  timeoutSeconds: 60,
});

// Shopify OAuth handler
exports.shopifyAuth = onRequest({
  region: "us-central1",
  cors: true,
}, async (req, res) => {
  try {
    const { shop, clientId } = req.query;
    
    if (!shop) {
      return res.status(400).send("Missing shop parameter");
    }

    // Validate shop domain
    if (!shop.endsWith('.myshopify.com')) {
      return res.status(400).send("Invalid shop domain");
    }

    // Shopify app credentials
    const SHOPIFY_API_KEY = process.env.SHOPIFY_API_KEY || "a4242369a1e8b5d7e512d82356262da9";
    const SHOPIFY_REDIRECT_URI = "https://breadcrumb-shopify.web.app/api/auth/shopify/callback";
    const SHOPIFY_SCOPES = "read_orders,read_products,read_customers,write_orders,read_inventory";

    // Generate state parameter with client info
    const state = JSON.stringify({
      shop: shop,
      clientId: clientId,
      timestamp: Date.now()
    });

    // Build Shopify OAuth URL
    const shopifyAuthUrl = `https://${shop}/admin/oauth/authorize?client_id=${SHOPIFY_API_KEY}&scope=${SHOPIFY_SCOPES}&redirect_uri=${encodeURIComponent(SHOPIFY_REDIRECT_URI)}&state=${encodeURIComponent(state)}&grant_options[]=`;

    res.redirect(shopifyAuthUrl);
  } catch (error) {
    console.error('Shopify auth error:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Shopify OAuth callback handler
exports.shopifyCallback = onRequest({
  region: "us-central1",
  cors: true,
}, async (req, res) => {
  try {
    const { code, state, shop } = req.query;
    
    if (!code || !state || !shop) {
      return res.status(400).send("Missing required parameters");
    }

    // Parse state to get client info
    const stateData = JSON.parse(state);
    const clientId = stateData.clientId;
    
    // Exchange code for access token
    const tokenResponse = await fetch(`https://${shop}/admin/oauth/access_token`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        client_id: process.env.SHOPIFY_API_KEY || "a4242369a1e8b5d7e512d82356262da9",
        client_secret: process.env.SHOPIFY_API_SECRET,
        code: code,
      }),
    });

    if (!tokenResponse.ok) {
      throw new Error('Failed to get access token');
    }

    const tokenData = await tokenResponse.json();
    const accessToken = tokenData.access_token;

    // Get shop information
    const shopResponse = await fetch(`https://${shop}/admin/api/2025-01/shop.json`, {
      headers: {
        'X-Shopify-Access-Token': accessToken,
      },
    });

    if (!shopResponse.ok) {
      throw new Error('Failed to get shop information');
    }

    const shopData = await shopResponse.json();
    const shopInfo = shopData.shop;

    // Store connection in Firestore
    const db = admin.firestore();
    
    // Create shop connection document
    const connectionData = {
      clientId: clientId,
      shop: shop,
      shopName: shopInfo.name,
      shopEmail: shopInfo.email,
      shopDomain: shopInfo.domain,
      accessToken: accessToken,
      scope: tokenData.scope,
      connectedAt: new Date().toISOString(),
      status: 'active',
      lastSync: null,
    };

    // Store in shopConnections collection
    await db.collection('shopConnections').add(connectionData);

    // Update client with shop connection
    if (clientId) {
      await db.collection('clients').doc(clientId).set({
        shopifyConnected: true,
        shopifyShop: shop,
        shopifyShopName: shopInfo.name,
        lastUpdated: new Date().toISOString(),
      }, { merge: true });
    }

    // Redirect back to Shopify app with success
    const redirectUrl = `https://breadcrumb-shopify.web.app/?connected=success&shop=${encodeURIComponent(shop)}&shopName=${encodeURIComponent(shopInfo.name)}`;
    res.redirect(redirectUrl);

  } catch (error) {
    console.error('Shopify OAuth error:', error);
    const redirectUrl = `https://breadcrumb-shopify.web.app/?connected=error&error=${encodeURIComponent(error.message)}`;
    res.redirect(redirectUrl);
  }
});

// Webhook handler for order creation
exports.webhookOrdersCreate = onRequest({
  region: "us-central1",
  cors: true,
}, async (req, res) => {
  try {
    if (req.method !== 'POST') {
      return res.status(405).send('Method not allowed');
    }

    const order = req.body;
    const db = admin.firestore();

    // Process the new order
    const orderData = {
      shopifyOrderId: order.id.toString(),
      shopifyOrderNumber: order.order_number.toString(),
      shop: order.shop_domain,
      customerName: order.customer?.first_name + ' ' + order.customer?.last_name || 'Guest',
      customerEmail: order.customer?.email || '',
      totalPrice: parseFloat(order.total_price || 0),
      currency: order.currency || 'USD',
      status: order.fulfillment_status || 'unfulfilled',
      items: order.line_items?.map(item => ({
        productId: item.product_id?.toString(),
        variantId: item.variant_id?.toString(),
        sku: item.sku || '',
        name: item.name || '',
        quantity: item.quantity || 0,
        price: parseFloat(item.price || 0),
        totalPrice: parseFloat(item.price || 0) * (item.quantity || 0),
      })) || [],
      shippingAddress: order.shipping_address ? {
        firstName: order.shipping_address.first_name || '',
        lastName: order.shipping_address.last_name || '',
        company: order.shipping_address.company || '',
        address1: order.shipping_address.address1 || '',
        address2: order.shipping_address.address2 || '',
        city: order.shipping_address.city || '',
        province: order.shipping_address.province || '',
        country: order.shipping_address.country || '',
        zip: order.shipping_address.zip || '',
        phone: order.shipping_address.phone || '',
      } : null,
      billingAddress: order.billing_address ? {
        firstName: order.billing_address.first_name || '',
        lastName: order.billing_address.last_name || '',
        company: order.billing_address.company || '',
        address1: order.billing_address.address1 || '',
        address2: order.billing_address.address2 || '',
        city: order.billing_address.city || '',
        province: order.billing_address.province || '',
        country: order.billing_address.country || '',
        zip: order.billing_address.zip || '',
        phone: order.billing_address.phone || '',
      } : null,
      notes: order.note || '',
      tags: order.tags || '',
      shopifyData: order,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    // Store the order in Firestore
    await db.collection('orders').add(orderData);

    // Update client stats if we can identify the client
    const shopConnections = await db.collection('shopConnections')
      .where('shop', '==', order.shop_domain)
      .where('status', '==', 'active')
      .get();

    if (!shopConnections.empty) {
      const connection = shopConnections.docs[0].data();
      const clientId = connection.clientId;

      if (clientId) {
        // Update client stats
        await db.collection('clients').doc(clientId).update({
          'stats.orders': admin.firestore.FieldValue.increment(1),
          'stats.lastActivity': new Date(),
          'updatedAt': new Date(),
        });
      }
    }

    res.status(200).send('OK');
  } catch (error) {
    console.error('Error processing order webhook:', error);
    res.status(500).send('Internal Server Error');
  }
});

// Create request handler for Remix app
const requestHandler = async (req, res) => {
  try {
    // Set CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    // Handle preflight requests
    if (req.method === 'OPTIONS') {
      res.status(200).end();
      return;
    }

    // Import the Remix serverless function dynamically
    const { createRequestHandler } = require("@remix-run/express");
    const { installGlobals } = require("@remix-run/node");
    
    // Install globals
    installGlobals();
    
    // Import the server build
    const serverBuild = require("../breadcrumb/build/server/index.js");
    
    // Create the request handler
    const handler = createRequestHandler(serverBuild, "production");
    
    // Handle the request
    await handler(req, res);
    
  } catch (error) {
    console.error('Function error:', error);
    res.status(500).send('Internal Server Error');
  }
};

// Export the Firebase function
exports.remixApp = onRequest({
  region: "us-central1",
  cors: true,
}, requestHandler);