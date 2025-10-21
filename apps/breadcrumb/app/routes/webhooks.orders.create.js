import { json } from '@remix-run/node';
import { getFirestore } from 'firebase-admin/firestore';

export async function action({ request }) {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, { status: 405 });
  }

  try {
    const order = await request.json();
    const db = getFirestore();

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
          'stats.orders': db.FieldValue.increment(1),
          'stats.lastActivity': new Date(),
          'updatedAt': new Date(),
        });
      }
    }

    return json({ success: true });
  } catch (error) {
    console.error('Error processing order webhook:', error);
    return json({ error: 'Internal server error' }, { status: 500 });
  }
}
