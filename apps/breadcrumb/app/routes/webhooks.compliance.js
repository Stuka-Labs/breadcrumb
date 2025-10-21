import { json } from "@remix-run/node";
import { getFirestore } from 'firebase-admin/firestore';
import crypto from 'crypto';

// Shopify webhook verification
function verifyWebhook(data, signature, secret) {
  const hmac = crypto.createHmac('sha256', secret);
  hmac.update(data, 'utf8');
  const hash = hmac.digest('base64');
  return hash === signature;
}

export async function action({ request }) {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, { status: 405 });
  }

  try {
    // Get the HMAC signature from headers
    const signature = request.headers.get('X-Shopify-Hmac-Sha256');
    const webhookSecret = process.env.SHOPIFY_WEBHOOK_SECRET || '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';
    
    // Get the raw body for verification
    const body = await request.text();
    
    // Verify the webhook signature (required for compliance webhooks)
    if (signature && !verifyWebhook(body, signature, webhookSecret)) {
      console.error('Invalid webhook signature for compliance webhook');
      return json({ error: 'Unauthorized' }, { status: 401 });
    }

    const webhookData = JSON.parse(body);
    const db = getFirestore();

    // Log the compliance webhook for monitoring
    console.log('Compliance webhook received:', {
      shopId: webhookData.shop_id,
      shopDomain: webhookData.shop_domain,
      webhookType: webhookData.webhook_type || 'unknown'
    });

    // Handle different compliance webhook types
    if (webhookData.customer && webhookData.orders_requested) {
      // customers/data_request webhook
      await handleDataRequest(db, webhookData);
    } else if (webhookData.customer && webhookData.orders_to_redact) {
      // customers/redact webhook
      await handleCustomerRedact(db, webhookData);
    } else if (webhookData.shop_id && webhookData.shop_domain && !webhookData.customer) {
      // shop/redact webhook
      await handleShopRedact(db, webhookData);
    } else {
      // Log unknown compliance webhook type
      console.log('Unknown compliance webhook type:', webhookData);
    }

    // Always return 200 to confirm receipt
    return json({ success: true, message: 'Compliance webhook processed' });
  } catch (error) {
    console.error('Error processing compliance webhook:', error);
    // Still return 200 to avoid webhook retries
    return json({ success: false, error: 'Internal server error' });
  }
}

async function handleDataRequest(db, webhookData) {
  try {
    const { shop_id, shop_domain, customer, orders_requested, data_request } = webhookData;
    
    // Store the data request for processing
    await db.collection('complianceRequests').add({
      type: 'data_request',
      shopId: shop_id,
      shopDomain: shop_domain,
      customerId: customer.id,
      customerEmail: customer.email,
      customerPhone: customer.phone,
      ordersRequested: orders_requested,
      dataRequestId: data_request.id,
      status: 'pending',
      createdAt: new Date().toISOString(),
      processedAt: null
    });

    console.log('Data request stored:', {
      customerId: customer.id,
      ordersRequested: orders_requested.length,
      dataRequestId: data_request.id
    });
  } catch (error) {
    console.error('Error handling data request:', error);
  }
}

async function handleCustomerRedact(db, webhookData) {
  try {
    const { shop_id, shop_domain, customer, orders_to_redact } = webhookData;
    
    // Store the redaction request
    await db.collection('complianceRequests').add({
      type: 'customer_redact',
      shopId: shop_id,
      shopDomain: shop_domain,
      customerId: customer.id,
      customerEmail: customer.email,
      customerPhone: customer.phone,
      ordersToRedact: orders_to_redact,
      status: 'pending',
      createdAt: new Date().toISOString(),
      processedAt: null
    });

    // Mark customer data for deletion (soft delete)
    const customerQuery = await db.collection('customers')
      .where('shopifyCustomerId', '==', customer.id.toString())
      .where('shopId', '==', shop_id.toString())
      .get();

    for (const doc of customerQuery.docs) {
      await doc.ref.update({
        status: 'deleted',
        deletedAt: new Date().toISOString(),
        redactionRequestId: webhookData.data_request?.id || 'manual'
      });
    }

    // Mark orders for deletion
    for (const orderId of orders_to_redact) {
      const orderQuery = await db.collection('orders')
        .where('shopifyOrderId', '==', orderId.toString())
        .where('shopId', '==', shop_id.toString())
        .get();

      for (const doc of orderQuery.docs) {
        await doc.ref.update({
          status: 'deleted',
          deletedAt: new Date().toISOString(),
          redactionRequestId: webhookData.data_request?.id || 'manual'
        });
      }
    }

    console.log('Customer redaction processed:', {
      customerId: customer.id,
      ordersRedacted: orders_to_redact.length
    });
  } catch (error) {
    console.error('Error handling customer redaction:', error);
  }
}

async function handleShopRedact(db, webhookData) {
  try {
    const { shop_id, shop_domain } = webhookData;
    
    // Store the shop redaction request
    await db.collection('complianceRequests').add({
      type: 'shop_redact',
      shopId: shop_id,
      shopDomain: shop_domain,
      status: 'pending',
      createdAt: new Date().toISOString(),
      processedAt: null
    });

    // Mark all shop data for deletion
    const collections = ['orders', 'customers', 'products', 'fulfillmentOrders', 'shopifyConnections'];
    
    for (const collectionName of collections) {
      const query = await db.collection(collectionName)
        .where('shopId', '==', shop_id.toString())
        .get();

      for (const doc of query.docs) {
        await doc.ref.update({
          status: 'deleted',
          deletedAt: new Date().toISOString(),
          redactionType: 'shop_redact'
        });
      }
    }

    console.log('Shop redaction processed:', {
      shopId: shop_id,
      shopDomain: shop_domain
    });
  } catch (error) {
    console.error('Error handling shop redaction:', error);
  }
}
