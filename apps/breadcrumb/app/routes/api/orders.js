import { authenticate } from '~/shopify.server';
import admin from 'firebase-admin';

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });
}
const db = admin.firestore();

export async function loader({ request }) {
  try {
    const { admin: shopifyAdmin } = await authenticate.admin(request);

    const response = await shopifyAdmin.graphql(`
      {
        orders(first: 20) {
          edges {
            node {
              id
              name
              createdAt
              totalPriceSet { shopMoney { amount currencyCode } }
              lineItems(first: 10) {
                edges {
                  node {
                    title
                    quantity
                  }
                }
              }
              customer {
                firstName
                lastName
                email
              }
              fulfillments {
                trackingInfo {
                  number
                  url
                }
                createdAt
                status
              }
            }
          }
        }
      }
    `);

    const data = await response.json();
    const orders = data.data.orders.edges.map(e => e.node);

    // Write each order to Firestore if not already present
    for (const order of orders) {
      const orderRef = db.collection('orders').doc(order.id);
      const doc = await orderRef.get();
      if (!doc.exists) {
        await orderRef.set({
          type: 'sale',
          status: 'pending',
          shopifyId: order.id,
          name: order.name,
          createdAt: order.createdAt,
          total: order.totalPriceSet?.shopMoney?.amount || '',
          currency: order.totalPriceSet?.shopMoney?.currencyCode || '',
          products: (order.lineItems?.edges || []).map(e => ({
            name: e.node.title,
            quantity: e.node.quantity,
            status: 'pending',
          })),
          customer: order.customer || {},
          fulfillments: order.fulfillments || [],
          updatedAt: new Date().toISOString(),
        });
      }
    }

    return new Response(JSON.stringify(data), {
      headers: { 'Content-Type': 'application/json' }
    });
  } catch (error) {
    // Log error to Firestore
    await db.collection('logs').add({
      type: 'import',
      action: 'shopify_order_import',
      error: error.message || String(error),
      timestamp: new Date().toISOString(),
    });
    return new Response(JSON.stringify({ error: error.message || String(error) }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' }
    });
  }
} 