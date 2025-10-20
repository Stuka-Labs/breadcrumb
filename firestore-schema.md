# BreadCrumb WMS Firestore Database Schema

## Collections Overview

### 1. users/{userId}
```json
{
  "email": "string",
  "role": "admin" | "client" | "packer",
  "warehouseId": "string",
  "customerId": "string",
  "status": "active" | "inactive",
  "lastLogin": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 2. warehouses/{warehouseId}
```json
{
  "name": "string",
  "addressId": "string",
  "settings": {
    "palletLabeling": "boolean",
    "expiryWarnings": "boolean",
    "autoEmailOnDispatch": "boolean",
    "labeling": "enabled" | "disabled"
  },
  "admins": ["userId"],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 3. locations/{locationId}
```json
{
  "warehouseId": "string",
  "zone": "string",
  "shelf": "string",
  "bin": "string",
  "capacity": "number",
  "currentStock": "number",
  "status": "active" | "inactive",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 4. products/{productId}
```json
{
  "name": "string",
  "sku": "string",
  "quantity": "number",
  "warehouseId": "string",
  "locationId": "string",
  "expiryDate": "timestamp",
  "status": "active" | "damaged" | "expired",
  "customerId": "string",
  "createdBy": "string",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 5. orders/{orderId}
```json
{
  "type": "sale" | "purchase" | "return",
  "status": "pending" | "picked" | "packed" | "fulfilled" | "cancelled",
  "customerId": "string",
  "warehouseId": "string",
  "products": [
    {
      "productId": "string",
      "quantity": "number",
      "status": "picked" | "packed" | "fulfilled"
    }
  ],
  "packerId": "string",
  "timestamps": {
    "created": "timestamp",
    "packed": "timestamp",
    "fulfilled": "timestamp"
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 6. stockTakes/{takeId}
```json
{
  "warehouseId": "string",
  "createdBy": "string",
  "status": "in_progress" | "reviewed",
  "items": [
    {
      "productId": "string",
      "actualCount": "number",
      "expectedCount": "number",
      "discrepancy": "number"
    }
  ],
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 7. wavePicks/{waveId}
```json
{
  "warehouseId": "string",
  "orderIds": ["string"],
  "packerId": "string",
  "status": "assigned" | "in_progress" | "done",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 8. files/{fileId}
```json
{
  "fileName": "string",
  "fileType": "purchase_order" | "document" | "invoice",
  "uploadedBy": "string",
  "linkedTo": "string",
  "status": "parsed" | "error",
  "timestamp": "timestamp",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 9. reports/{reportId}
```json
{
  "type": "discrepancy" | "stock_movement" | "expiry_warning" | "customer_stock" | "stats",
  "warehouseId": "string",
  "filters": {
    "dateRange": {
      "start": "timestamp",
      "end": "timestamp"
    },
    "productStatus": "string"
  },
  "generatedAt": "timestamp",
  "generatedBy": "string",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 10. contacts/{contactId}
```json
{
  "type": "customer" | "supplier" | "driver" | "api_client",
  "name": "string",
  "email": "string",
  "phone": "string",
  "addressId": "string",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### 11. logs/{logId}
```json
{
  "type": "bolt" | "import" | "print",
  "userId": "string",
  "action": "string",
  "timestamp": "timestamp",
  "details": {
    "locationId": "string",
    "productId": "string"
  },
  "createdAt": "timestamp"
}
```

### 12. settings/{settingId}
```json
{
  "global": {
    "rateCards": ["string"],
    "cashOnDeliveryEnabled": "boolean"
  },
  "warehouseSettings": {
    "warehouseId": {
      "labeling": "enabled" | "disabled",
      "autoEmailOnDispatch": "boolean"
    }
  },
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

## Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    
    function isClient() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'client';
    }
    
    function isPacker() {
      return isAuthenticated() && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'packer';
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || request.auth.uid == userId;
    }
    
    // Warehouses collection
    match /warehouses/{warehouseId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Products collection
    match /products/{productId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || isPacker();
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || isPacker();
    }
    
    // Stock takes collection
    match /stockTakes/{takeId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || isPacker();
    }
    
    // Wave picks collection
    match /wavePicks/{waveId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || isPacker();
    }
    
    // Files collection
    match /files/{fileId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || isClient();
    }
    
    // Reports collection
    match /reports/{reportId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Contacts collection
    match /contacts/{contactId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
    
    // Logs collection
    match /logs/{logId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin() || isPacker();
    }
    
    // Settings collection
    match /settings/{settingId} {
      allow read: if isAuthenticated();
      allow write: if isAdmin();
    }
  }
}
```

## Indexes

The following indexes should be created for optimal query performance:

1. `products` collection:
   - `warehouseId` ASC, `status` ASC
   - `customerId` ASC, `status` ASC
   - `expiryDate` ASC

2. `orders` collection:
   - `warehouseId` ASC, `status` ASC
   - `customerId` ASC, `status` ASC
   - `type` ASC, `status` ASC

3. `stockTakes` collection:
   - `warehouseId` ASC, `status` ASC
   - `createdBy` ASC, `status` ASC

4. `wavePicks` collection:
   - `warehouseId` ASC, `status` ASC
   - `packerId` ASC, `status` ASC

5. `reports` collection:
   - `type` ASC, `generatedAt` DESC
   - `warehouseId` ASC, `generatedAt` DESC

## Cloud Functions

The following Cloud Functions should be implemented:

1. `onOrderStatusChange`: Triggered when an order status changes
   - Updates related collections
   - Sends notifications to relevant users

2. `onStockTakeComplete`: Triggered when a stock take is completed
   - Generates discrepancy reports
   - Updates product quantities

3. `onProductExpiry`: Triggered when a product is approaching expiry
   - Generates expiry warning reports
   - Sends notifications to relevant users

4. `onFileUpload`: Triggered when a file is uploaded
   - Parses file content
   - Updates relevant collections

5. `onWavePickComplete`: Triggered when a wave pick is completed
   - Updates order statuses
   - Generates picking reports

## Best Practices

1. Use batch operations for related updates
2. Implement pagination for large collections
3. Use transactions for critical operations
4. Implement proper error handling
5. Use proper indexing for frequently queried fields
6. Implement proper validation rules
7. Use proper security rules
8. Implement proper logging
9. Use proper error handling
10. Implement proper monitoring

## Recommended Firestore Composite Indexes

Add these composite indexes to your Firestore for optimal query performance and to avoid runtime errors:

1. **orders**
   - Fields: `type` ASC, `status` ASC
   - Fields: `status` ASC, `createdAt` DESC
   - Fields: `customerId` ASC, `status` ASC
   - Fields: `createdAt` DESC

2. **products**
   - Fields: `warehouseId` ASC, `status` ASC
   - Fields: `customerId` ASC, `status` ASC
   - Fields: `expiryDate` ASC
   - Fields: `createdAt` DESC

3. **locations**
   - Fields: `warehouseId` ASC, `status` ASC
   - Fields: `createdAt` DESC

4. **stockTakes**
   - Fields: `warehouseId` ASC, `status` ASC
   - Fields: `createdBy` ASC, `status` ASC
   - Fields: `createdAt` DESC

5. **wavePicks**
   - Fields: `warehouseId` ASC, `status` ASC
   - Fields: `packerId` ASC, `status` ASC
   - Fields: `createdAt` DESC

6. **reports**
   - Fields: `type` ASC, `generatedAt` DESC
   - Fields: `warehouseId` ASC, `generatedAt` DESC

7. **Any collection with queries on `status` and `createdAt`**
   - Fields: `status` ASC, `createdAt` DESC

To deploy these indexes, create a `firestore.indexes.json` file and run `firebase deploy --only firestore:indexes`. 