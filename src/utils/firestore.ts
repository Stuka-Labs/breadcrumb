import {
  collection,
  doc,
  setDoc,
  getDoc,
  getDocs,
  updateDoc,
  deleteDoc,
  query,
  where,
  Timestamp,
  DocumentData,
  QueryConstraint,
} from 'firebase/firestore';
import { db } from '../config/firebase';
import { COLLECTIONS } from '../types/firestore';

// Generic function to add a document with type checking
export async function addDocument<T extends DocumentData>(
  collectionName: string,
  data: T,
  id?: string
): Promise<string> {
  const docRef = id ? doc(db, collectionName, id) : doc(collection(db, collectionName));
  await setDoc(docRef, {
    ...data,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });
  return docRef.id;
}

// Generic function to get a document by ID
export async function getDocument<T>(
  collectionName: string,
  id: string
): Promise<T | null> {
  const docRef = doc(db, collectionName, id);
  const docSnap = await getDoc(docRef);
  return docSnap.exists() ? (docSnap.data() as T) : null;
}

// Generic function to update a document
export async function updateDocument<T extends DocumentData>(
  collectionName: string,
  id: string,
  data: Partial<T>
): Promise<void> {
  const docRef = doc(db, collectionName, id);
  await updateDoc(docRef, {
    ...data,
    updatedAt: Timestamp.now(),
  });
}

// Generic function to delete a document
export async function deleteDocument(
  collectionName: string,
  id: string
): Promise<void> {
  const docRef = doc(db, collectionName, id);
  await deleteDoc(docRef);
}

// Generic function to query documents
export async function queryDocuments<T>(
  collectionName: string,
  constraints: QueryConstraint[]
): Promise<T[]> {
  const q = query(collection(db, collectionName), ...constraints);
  const querySnapshot = await getDocs(q);
  return querySnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() } as T));
}

// Example usage with type safety:
/*
import { User, Product, Order } from '../types/firestore';

// Add a user
const newUser: User = {
  email: 'user@example.com',
  role: 'client',
  warehouseId: 'warehouse1',
  customerId: 'customer1',
  status: 'active',
  lastLogin: Timestamp.now(),
  createdAt: Timestamp.now(),
  updatedAt: Timestamp.now(),
};
await addDocument(COLLECTIONS.USERS, newUser);

// Get a product
const product = await getDocument<Product>(COLLECTIONS.PRODUCTS, 'product1');

// Update an order
await updateDocument(COLLECTIONS.ORDERS, 'order1', { status: 'fulfilled' });

// Query products
const products = await queryDocuments<Product>(COLLECTIONS.PRODUCTS, [
  where('warehouseId', '==', 'warehouse1'),
  where('status', '==', 'active'),
]);
*/ 