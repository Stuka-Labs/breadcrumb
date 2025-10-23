import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

class TestUserService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Creates a comprehensive test user with sample data for WMS demonstration
  /// Returns the test user credentials and available features
  static Future<Map<String, dynamic>> createTestUser() async {
    try {
      final callable = _functions.httpsCallable('setupTestUser');
      final result = await callable.call();
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        return {
          'success': true,
          'email': data['email'],
          'password': data['password'],
          'message': data['message'],
          'features': data['features'] as List<dynamic>? ?? [],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create test user',
          'error': data['error'],
        };
      }
    } catch (e) {
      debugPrint('Error creating test user: $e');
      return {
        'success': false,
        'message': 'Failed to create test user',
        'error': e.toString(),
      };
    }
  }

  /// Gets information about the test user setup
  static Future<Map<String, dynamic>> getTestUserInfo() async {
    return {
      'email': 'client@gmail.com',
      'password': 'demo123456',
      'role': 'client',
      'company': 'Demo E-commerce Store',
      'features': [
        'Shopify integration with sample orders',
        'Product management with 4 sample products',
        'Order processing and fulfillment',
        'Analytics dashboard with real metrics',
        'Warehouse management with locations',
        'Stock movement tracking',
        'Multi-platform support (Shopify + Etsy)',
        'AI-powered insights and competitor analysis',
        'Real-time order synchronization',
        'Automated fulfillment workflows'
      ],
      'sampleData': {
        'products': 4,
        'orders': 3,
        'shopConnections': 2,
        'warehouseLocations': 4,
        'analyticsMetrics': 9
      }
    };
  }

  /// Checks if the test user already exists
  static Future<bool> testUserExists() async {
    try {
      final callable = _functions.httpsCallable('setupTestUser');
      final result = await callable.call();
      
      final data = result.data as Map<String, dynamic>;
      return data['success'] == false && data['message']?.contains('already exists') == true;
    } catch (e) {
      debugPrint('Error checking test user existence: $e');
      return false;
    }
  }
}
