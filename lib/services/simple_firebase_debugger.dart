import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;

class SimpleFirebaseDebugger {
  static final SimpleFirebaseDebugger _instance = SimpleFirebaseDebugger._internal();
  factory SimpleFirebaseDebugger() => _instance;
  SimpleFirebaseDebugger._internal();

  static bool _isMonitoring = false;

  // Start monitoring
  static void startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _logToTerminal('🚀 SIMPLE_FIREBASE_MONITORING_STARTED', {
      'message': 'Firebase monitoring enabled (simple mode)',
      'timestamp': DateTime.now().toIso8601String(),
      'features': ['firestore', 'auth', 'storage']
    });

    _monitorAuth();
    _monitorStorage();
  }

  // Monitor authentication operations
  static void _monitorAuth() {
    try {
      // Check if Firebase is initialized before accessing Auth
      if (Firebase.apps.isNotEmpty) {
        // Monitor auth state changes
        FirebaseAuth.instance.authStateChanges().listen((User? user) {
          _logToTerminal('👤 AUTH_STATE_CHANGE', {
            'user_id': user?.uid,
            'email': user?.email,
            'timestamp': DateTime.now().toIso8601String(),
            'operation': 'auth_state_change'
          });
        });

        // Monitor user changes
        FirebaseAuth.instance.userChanges().listen((User? user) {
          _logToTerminal('👤 AUTH_USER_CHANGE', {
            'user_id': user?.uid,
            'email': user?.email,
            'timestamp': DateTime.now().toIso8601String(),
            'operation': 'user_change'
          });
        });
      } else {
        _logToTerminal('⚠️ FIREBASE_NOT_INITIALIZED', {
          'message': 'Firebase not initialized yet, skipping auth monitoring',
          'timestamp': DateTime.now().toIso8601String(),
          'operation': 'auth_monitoring_skipped'
        });
      }
    } catch (e) {
      _logToTerminal('❌ AUTH_MONITORING_ERROR', {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'operation': 'auth_monitoring_error'
      });
    }
  }

  // Monitor storage operations
  static void _monitorStorage() {
    try {
      // Check if Firebase is initialized before accessing Storage
      if (Firebase.apps.isNotEmpty) {
        final bucket = FirebaseStorage.instance.app.options.storageBucket;
        _logToTerminal('📦 STORAGE_INITIALIZED', {
          'bucket': bucket,
          'timestamp': DateTime.now().toIso8601String(),
          'operation': 'storage_init'
        });
      } else {
        _logToTerminal('⚠️ FIREBASE_NOT_INITIALIZED', {
          'message': 'Firebase not initialized yet, skipping storage monitoring',
          'timestamp': DateTime.now().toIso8601String(),
          'operation': 'storage_monitoring_skipped'
        });
      }
    } catch (e) {
      _logToTerminal('❌ STORAGE_INIT_ERROR', {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
        'operation': 'storage_init_error'
      });
    }
  }

  // Log Firestore operations (called manually from your code)
  static void logFirestoreOperation(String operation, String path, [Map<String, dynamic>? data]) {
    _logToTerminal('📚 FIRESTORE_OPERATION', {
      'operation': operation,
      'path': path,
      'data': data,
      'timestamp': DateTime.now().toIso8601String()
    });
  }

  // Log authentication operations (called manually from your code)
  static void logAuthOperation(String operation, [Map<String, dynamic>? data]) {
    _logToTerminal('🔐 AUTH_OPERATION', {
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String()
    });
  }

  // Log storage operations (called manually from your code)
  static void logStorageOperation(String operation, String path, [Map<String, dynamic>? data]) {
    _logToTerminal('📦 STORAGE_OPERATION', {
      'operation': operation,
      'path': path,
      'data': data,
      'timestamp': DateTime.now().toIso8601String()
    });
  }

  // Log errors
  static void logError(String operation, dynamic error, [StackTrace? stackTrace]) {
    _logToTerminal('❌ FIREBASE_ERROR', {
      'operation': operation,
      'error': error.toString(),
      'error_type': error.runtimeType.toString(),
      'stack_trace': stackTrace?.toString(),
      'timestamp': DateTime.now().toIso8601String()
    });
  }

  // Log successful operations
  static void logSuccess(String operation, [Map<String, dynamic>? data]) {
    _logToTerminal('✅ FIREBASE_SUCCESS', {
      'operation': operation,
      'data': data,
      'timestamp': DateTime.now().toIso8601String()
    });
  }

  // Log to terminal with structured format
  static void _logToTerminal(String operation, Map<String, dynamic> data) {
    final timestamp = DateTime.now().toIso8601String();
    
    // Log to Flutter console
    developer.log('$operation: $data', name: 'FirebaseDebug');
    
    // Print to terminal for immediate visibility
    print('🔥 FIREBASE_DEBUG: $operation');
    print('   📊 Data: $data');
    print('   ⏰ Time: $timestamp');
    print('   ---');
  }

  // Stop monitoring
  static void stopMonitoring() {
    _isMonitoring = false;
    _logToTerminal('🛑 FIREBASE_MONITORING_STOPPED', {
      'message': 'Firebase monitoring stopped',
      'timestamp': DateTime.now().toIso8601String(),
      'operation': 'monitoring_stopped'
    });
  }
}
