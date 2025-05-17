import { Timestamp } from 'firebase/firestore';

// User Types
export type UserRole = 'admin' | 'client' | 'packer';
export type UserStatus = 'active' | 'inactive';

export interface User {
  email: string;
  role: UserRole;
  warehouseId: string;
  customerId: string;
  status: UserStatus;
  lastLogin: Timestamp;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Warehouse Types
export interface WarehouseSettings {
  palletLabeling: boolean;
  expiryWarnings: boolean;
  autoEmailOnDispatch: boolean;
  labeling: 'enabled' | 'disabled';
}

export interface Warehouse {
  name: string;
  addressId: string;
  settings: WarehouseSettings;
  admins: string[];
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Location Types
export type LocationStatus = 'active' | 'inactive';

export interface Location {
  warehouseId: string;
  zone: string;
  shelf: string;
  bin: string;
  capacity: number;
  currentStock: number;
  status: LocationStatus;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Product Types
export type ProductStatus = 'active' | 'damaged' | 'expired';

export interface Product {
  name: string;
  sku: string;
  quantity: number;
  warehouseId: string;
  locationId: string;
  expiryDate: Timestamp;
  status: ProductStatus;
  customerId: string;
  createdBy: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Order Types
export type OrderType = 'sale' | 'purchase' | 'return';
export type OrderStatus = 'pending' | 'picked' | 'packed' | 'fulfilled' | 'cancelled';
export type ProductOrderStatus = 'picked' | 'packed' | 'fulfilled';

export interface OrderProduct {
  productId: string;
  quantity: number;
  status: ProductOrderStatus;
}

export interface OrderTimestamps {
  created: Timestamp;
  packed: Timestamp;
  fulfilled: Timestamp;
}

export interface Order {
  type: OrderType;
  status: OrderStatus;
  customerId: string;
  warehouseId: string;
  products: OrderProduct[];
  packerId: string;
  timestamps: OrderTimestamps;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Stock Take Types
export type StockTakeStatus = 'in_progress' | 'reviewed';

export interface StockTakeItem {
  productId: string;
  actualCount: number;
  expectedCount: number;
  discrepancy: number;
}

export interface StockTake {
  warehouseId: string;
  createdBy: string;
  status: StockTakeStatus;
  items: StockTakeItem[];
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Wave Pick Types
export type WavePickStatus = 'assigned' | 'in_progress' | 'done';

export interface WavePick {
  warehouseId: string;
  orderIds: string[];
  packerId: string;
  status: WavePickStatus;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// File Types
export type FileType = 'purchase_order' | 'document' | 'invoice';
export type FileStatus = 'parsed' | 'error';

export interface File {
  fileName: string;
  fileType: FileType;
  uploadedBy: string;
  linkedTo: string;
  status: FileStatus;
  timestamp: Timestamp;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Report Types
export type ReportType = 'discrepancy' | 'stock_movement' | 'expiry_warning' | 'customer_stock' | 'stats';

export interface ReportDateRange {
  start: Timestamp;
  end: Timestamp;
}

export interface ReportFilters {
  dateRange: ReportDateRange;
  productStatus: string;
}

export interface Report {
  type: ReportType;
  warehouseId: string;
  filters: ReportFilters;
  generatedAt: Timestamp;
  generatedBy: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Contact Types
export type ContactType = 'customer' | 'supplier' | 'driver' | 'api_client';

export interface Contact {
  type: ContactType;
  name: string;
  email: string;
  phone: string;
  addressId: string;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Log Types
export type LogType = 'bolt' | 'import' | 'print';

export interface LogDetails {
  locationId: string;
  productId: string;
}

export interface Log {
  type: LogType;
  userId: string;
  action: string;
  timestamp: Timestamp;
  details: LogDetails;
  createdAt: Timestamp;
}

// Settings Types
export interface WarehouseSetting {
  labeling: 'enabled' | 'disabled';
  autoEmailOnDispatch: boolean;
}

export interface WarehouseSettingsMap {
  [warehouseId: string]: WarehouseSetting;
}

export interface GlobalSettings {
  rateCards: string[];
  cashOnDeliveryEnabled: boolean;
}

export interface Settings {
  global: GlobalSettings;
  warehouseSettings: WarehouseSettingsMap;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

// Validation Functions
export const validateUser = (user: Partial<User>): boolean => {
  if (!user.email || !user.role || !user.warehouseId) return false;
  return true;
};

export const validateProduct = (product: Partial<Product>): boolean => {
  if (!product.name || !product.sku || !product.warehouseId) return false;
  return true;
};

export const validateOrder = (order: Partial<Order>): boolean => {
  if (!order.type || !order.status || !order.warehouseId) return false;
  return true;
};

// Collection Names
export const COLLECTIONS = {
  USERS: 'users',
  WAREHOUSES: 'warehouses',
  LOCATIONS: 'locations',
  PRODUCTS: 'products',
  ORDERS: 'orders',
  STOCK_TAKES: 'stockTakes',
  WAVE_PICKS: 'wavePicks',
  FILES: 'files',
  REPORTS: 'reports',
  CONTACTS: 'contacts',
  LOGS: 'logs',
  SETTINGS: 'settings',
} as const; 