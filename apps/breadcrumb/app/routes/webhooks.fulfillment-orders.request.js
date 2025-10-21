import { json } from "@remix-run/node";
import { getFirestore } from 'firebase-admin/firestore';

export async function action({ request }) {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, { status: 405 });
  }

  try {
    const fulfillmentOrder = await request.json();
    const db = getFirestore();

    // Store fulfillment order request
    const fulfillmentData = {
      shopifyFulfillmentOrderId: fulfillmentOrder.id,
      status: fulfillmentOrder.status,
      requestStatus: fulfillmentOrder.request_status,
      assignedLocationId: fulfillmentOrder.assigned_location?.id,
      assignedLocationName: fulfillmentOrder.assigned_location?.name,
      destination: fulfillmentOrder.destination,
      lineItems: fulfillmentOrder.line_items?.map(item => ({
        id: item.id,
        sku: item.sku,
        title: item.title,
        quantity: item.quantity,
        remainingQuantity: item.remaining_quantity,
        variantId: item.variant?.id,
        variantTitle: item.variant?.title,
        imageUrl: item.variant?.image?.url
      })) || [],
      shopifyData: fulfillmentOrder,
      createdAt: new Date().toISOString(),
      updatedAt: new Date().toISOString(),
    };

    // Store in Firestore
    await db.collection('fulfillmentOrders').add(fulfillmentData);

    // Log the fulfillment request for monitoring
    console.log('Fulfillment order request received:', {
      id: fulfillmentOrder.id,
      status: fulfillmentOrder.status,
      requestStatus: fulfillmentOrder.request_status,
      lineItemsCount: fulfillmentOrder.line_items?.length || 0
    });

    return json({ success: true });
  } catch (error) {
    console.error('Error processing fulfillment order webhook:', error);
    return json({ error: 'Internal server error' }, { status: 500 });
  }
}
