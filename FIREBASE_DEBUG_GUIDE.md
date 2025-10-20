# 🔥 Firebase Debugging Guide for Breadcrumb WMS

## 🚀 Quick Start

### Option 1: Run with Maximum Debugging (Recommended)
```bash
./run-with-debug.sh
```

### Option 2: Manual Setup
```bash
# Terminal 1: Start Firebase Emulator
firebase emulators:start --only firestore,auth,storage,functions --inspect-functions --debug

# Terminal 2: Run Flutter App
flutter run --debug --verbose --enable-asserts
```

## 📊 What You'll See in the Terminal

### 🔍 Firestore Operations
- **Collection Access**: Every time your app accesses a Firestore collection
- **Document Operations**: All document reads, writes, updates, and deletes
- **Query Results**: Success/failure of all Firestore queries
- **Index Errors**: Missing indexes and how to fix them

### 🔐 Authentication Operations
- **User Sign-ins/Sign-outs**: Every authentication state change
- **User Creation/Updates**: User profile modifications
- **Password/Email Changes**: Authentication credential updates

### 📦 Storage Operations
- **File Uploads/Downloads**: All file operations
- **Storage Errors**: Permission and quota issues
- **Metadata Changes**: File property updates

### ⚡ Functions Operations
- **Function Calls**: Every Cloud Function invocation
- **Function Results**: Success/failure of function execution
- **Performance Metrics**: Execution time and resource usage

## 🛠️ Debug Tools Available

### 1. FirebaseLoggingInterceptor
- **Location**: `lib/services/firebase_logging_interceptor.dart`
- **Purpose**: Intercepts and logs ALL Firebase operations
- **Output**: Structured logs with timestamps and operation details

### 2. FirebaseDebugService
- **Location**: `lib/services/firebase_debug_service.dart`
- **Purpose**: Provides debugging utilities and monitoring
- **Features**: Error tracking, operation logging, performance monitoring

### 3. Environment Variables
- **FIREBASE_DEBUG**: Enables comprehensive Firebase debugging
- **FIRESTORE_DEBUG**: Enables Firestore-specific debugging
- **FIREBASE_AUTH_DEBUG**: Enables authentication debugging
- **FLUTTER_VERBOSE**: Enables verbose Flutter logging

## 🔍 Reading the Debug Output

### Example Output:
```
🔥 FIREBASE_DEBUG: 🔍 FIRESTORE_COLLECTION_ACCESS
   📊 Data: {path: orders, timestamp: 2024-01-15T10:30:00.000Z, operation: collection_access}
   ⏰ Time: 2024-01-15T10:30:00.000Z
   ---

🔥 FIREBASE_DEBUG: 📚 FIRESTORE_OPERATION
   📊 Data: {operation: query, path: orders, data: {type: purchase, status: pending}}
   ⏰ Time: 2024-01-15T10:30:01.000Z
   ---
```

### Error Output:
```
🔥 FIREBASE_DEBUG: ❌ FIREBASE_ERROR
   📊 Data: {operation: query_orders, error: Missing index, error_type: FirebaseException}
   ⏰ Time: 2024-01-15T10:30:02.000Z
   ---
```

## 🚨 Common Issues & Solutions

### 1. Missing Firestore Indexes
**Problem**: `The query requires an index`
**Solution**: 
```bash
# Deploy updated indexes
firebase deploy --only firestore:indexes

# Or create manually via Firebase Console
# Link provided in error message
```

### 2. Authentication Errors
**Problem**: `User not found` or `Permission denied`
**Solution**: Check user roles and Firestore security rules

### 3. Storage Permission Errors
**Problem**: `Storage permission denied`
**Solution**: Verify Firebase Storage rules and user authentication

## 📱 Flutter App Debugging

### Debug Console
- All Firebase operations appear in Flutter debug console
- Use `developer.log()` for custom logging
- Check console for real-time operation tracking

### Performance Monitoring
- Firebase Performance traces are automatically logged
- Monitor database operation timing
- Track network request performance

## 🔧 Custom Debugging

### Add Custom Logs
```dart
import '../services/firebase_logging_interceptor.dart';

// Log custom operations
FirebaseLoggingInterceptor.logFirestoreOperation('custom_query', 'orders', {'filter': 'active'});
FirebaseLoggingInterceptor.logSuccess('user_creation', {'user_id': '123'});
FirebaseLoggingInterceptor.logError('data_sync', error, stackTrace);
```

### Monitor Specific Collections
```dart
// Monitor specific Firestore operations
FirebaseLoggingInterceptor.logCollectionAccess('orders', 'read');
FirebaseLoggingInterceptor.logDocumentOperation('orders/123', 'update', {'status': 'completed'});
```

## 🎯 Debugging Workflow

1. **Start Debug Session**: Run `./run-with-debug.sh`
2. **Monitor Terminal**: Watch for Firebase operation logs
3. **Identify Issues**: Look for error messages and missing indexes
4. **Fix Problems**: Deploy indexes, update rules, fix code
5. **Verify Solutions**: Check that operations succeed
6. **Repeat**: Continue monitoring until all issues resolved

## 📚 Additional Resources

- **Firebase Console**: https://console.firebase.google.com/project/breadcrumb-bd857
- **Firestore Indexes**: Check `firestore.indexes.json` for current configuration
- **Security Rules**: Review Firestore and Storage security rules
- **Flutter Debugging**: Use Flutter Inspector for UI debugging

## 🆘 Troubleshooting

### Debug Script Not Working
```bash
# Check permissions
chmod +x run-with-debug.sh

# Verify Firebase CLI
firebase --version

# Check project configuration
firebase projects:list
```

### No Logs Appearing
- Ensure `kDebugMode` is true
- Check Flutter console output
- Verify Firebase emulator is running
- Check network connectivity

### Performance Issues
- Monitor Firebase emulator resource usage
- Check for infinite loops in queries
- Verify index usage in Firestore queries
- Monitor memory usage in Flutter app

---

**Happy Debugging! 🐛✨**
