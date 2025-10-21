import { json } from '@remix-run/node';
import { getFirestore } from 'firebase-admin/firestore';

export async function action({ request }) {
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, { status: 405 });
  }

  try {
    const product = await request.json();
    const db = getFirestore();

    // Find the existing product in Firestore
    const productsSnapshot = await db.collection('products')
      .where('shopifyProductId', '==', product.id.toString())
      .get();
    
    if (!productsSnapshot.empty) {
      const productDoc = productsSnapshot.docs[0];
      const productRef = db.collection('products').doc(productDoc.id);

      // Update the product with new data
      await productRef.update({
        title: product.title,
        handle: product.handle,
        vendor: product.vendor,
        productType: product.product_type,
        tags: product.tags,
        status: product.status,
        variants: product.variants?.map(variant => ({
          id: variant.id,
          title: variant.title,
          sku: variant.sku,
          price: parseFloat(variant.price || 0),
          compareAtPrice: parseFloat(variant.compare_at_price || 0),
          inventoryQuantity: variant.inventory_quantity || 0,
          weight: variant.weight || 0,
          weightUnit: variant.weight_unit,
          requiresShipping: variant.requires_shipping,
          taxable: variant.taxable,
          barcode: variant.barcode,
          imageId: variant.image_id,
          position: variant.position,
          option1: variant.option1,
          option2: variant.option2,
          option3: variant.option3,
        })) || [],
        images: product.images?.map(image => ({
          id: image.id,
          src: image.src,
          alt: image.alt,
          position: image.position,
          width: image.width,
          height: image.height,
        })) || [],
        options: product.options?.map(option => ({
          id: option.id,
          name: option.name,
          position: option.position,
          values: option.values,
        })) || [],
        shopifyData: product,
        updatedAt: new Date().toISOString(),
      });

      console.log('Product updated:', {
        productId: product.id,
        title: product.title,
        handle: product.handle
      });
    }

    return json({ success: true });
  } catch (error) {
    console.error('Error processing product update webhook:', error);
    return json({ error: 'Internal server error' }, { status: 500 });
  }
}
