import { json } from '@remix-run/node';
import { getFirestore, collection, getDocs, addDoc, doc, getDoc, updateDoc, deleteDoc, query, where } from 'firebase-admin/firestore';

// GET all products or by SKU
export async function loader({ request }) {
  const db = getFirestore();
  const productsRef = collection(db, 'products');
  const url = new URL(request.url);
  const sku = url.searchParams.get('sku');
  if (sku) {
    const q = query(productsRef, where('sku', '==', sku));
    const snapshot = await getDocs(q);
    if (snapshot.empty) {
      return json({ error: 'Product not found' }, { status: 404, headers: { 'Access-Control-Allow-Origin': '*' } });
    }
    const product = { id: snapshot.docs[0].id, ...snapshot.docs[0].data() };
    return json(product, { headers: { 'Access-Control-Allow-Origin': '*' } });
  }
  const snapshot = await getDocs(productsRef);
  const products = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
  return json(products, { headers: { 'Access-Control-Allow-Origin': '*' } });
}

// POST (create), PATCH (update), DELETE (remove)
export async function action({ request }) {
  const db = getFirestore();
  const productsRef = collection(db, 'products');
  if (request.method === 'POST') {
    const data = await request.json();
    if (!data.sku) {
      return json({ error: 'SKU is required' }, { status: 400, headers: { 'Access-Control-Allow-Origin': '*' } });
    }
    // Check for duplicate SKU
    const q = query(productsRef, where('sku', '==', data.sku));
    const snapshot = await getDocs(q);
    if (!snapshot.empty) {
      return json({ error: 'Product with this SKU already exists' }, { status: 409, headers: { 'Access-Control-Allow-Origin': '*' } });
    }
    const docRef = await addDoc(productsRef, data);
    return json({ id: docRef.id, ...data }, { status: 201, headers: { 'Access-Control-Allow-Origin': '*' } });
  }
  if (request.method === 'PATCH') {
    const data = await request.json();
    if (!data.id) {
      return json({ error: 'Product ID is required for update' }, { status: 400, headers: { 'Access-Control-Allow-Origin': '*' } });
    }
    const productDoc = doc(productsRef, data.id);
    await updateDoc(productDoc, data);
    const updatedDoc = await getDoc(productDoc);
    return json({ id: updatedDoc.id, ...updatedDoc.data() }, { headers: { 'Access-Control-Allow-Origin': '*' } });
  }
  if (request.method === 'DELETE') {
    const data = await request.json();
    if (!data.id) {
      return json({ error: 'Product ID is required for delete' }, { status: 400, headers: { 'Access-Control-Allow-Origin': '*' } });
    }
    await deleteDoc(doc(productsRef, data.id));
    return json({ success: true }, { headers: { 'Access-Control-Allow-Origin': '*' } });
  }
  return json({ error: 'Method not allowed' }, { status: 405, headers: { 'Access-Control-Allow-Origin': '*' } });
} 