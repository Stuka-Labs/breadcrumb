import { json } from "@remix-run/node";
import { getFirestore } from 'firebase-admin/firestore';

export async function action({ request }) {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, { status: 405 });
  }

  try {
    const webhookData = await request.json();
    const db = getFirestore();

    console.log('App uninstalled webhook received:', {
      shop: webhookData.domain,
      shopId: webhookData.id
    });

    // Mark all shop connections as inactive
    const connectionsQuery = await db.collection('shopifyConnections')
      .where('shop', '==', webhookData.domain)
      .get();

    for (const doc of connectionsQuery.docs) {
      await doc.ref.update({
        status: 'uninstalled',
        uninstalledAt: new Date().toISOString()
      });
    }

    // Mark client as disconnected
    const clientsQuery = await db.collection('clients')
      .where('shopifyShop', '==', webhookData.domain)
      .get();

    for (const doc of clientsQuery.docs) {
      await doc.ref.update({
        shopifyConnected: false,
        shopifyShop: null,
        shopifyShopName: null,
        lastUpdated: new Date().toISOString()
      });
    }

    console.log('App uninstallation processed:', {
      connectionsUpdated: connectionsQuery.docs.length,
      clientsUpdated: clientsQuery.docs.length
    });

    return json({ success: true });
  } catch (error) {
    console.error('Error processing app uninstalled webhook:', error);
    return json({ error: 'Internal server error' }, { status: 500 });
  }
}
