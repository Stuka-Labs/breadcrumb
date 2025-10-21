import { json } from '@remix-run/node';
import { getFirestore } from 'firebase-admin/firestore';

export async function action({ request }) {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, { status: 405 });
  }

  try {
    const order = await request.json();
    const db = getFirestore();

    // Find the existing order in Firestore
    const ordersSnapshot = await db.collection('orders')
      .where('shopifyOrderId', '==', order.id.toString())
      .get();
    
    if (!ordersSnapshot.empty) {
      const orderDoc = ordersSnapshot.docs[0];
      const orderRef = db.collection('orders').doc(orderDoc.id);

      // Update the order with new data
      await orderRef.update({
        status: order.fulfillment_status || 'unfulfilled',
        totalPrice: parseFloat(order.total_price || 0),
        notes: order.note || '',
        tags: order.tags || '',
        shopifyData: order,
        updatedAt: new Date().toISOString(),
      });
    }

    return json({ success: true });
  } catch (error) {
    console.error('Error processing order update webhook:', error);
    return json({ error: 'Internal server error' }, { status: 500 });
  }
}
