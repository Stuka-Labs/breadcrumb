import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart' show FieldValue;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      debugPrint('Sign in error: $e');
      rethrow;
    }
  }

  // Create new user (admin only)
  Future<void> createUser({
    required String email,
    required String password,
    required String username,
    required String role,
  }) async {
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('createUserWithRole');
    await callable.call(<String, dynamic>{
      'email': email,
      'password': password,
      'role': role,
    });
    // Optionally, you can store username in Firestore here if needed
    // await _firestore.collection('users').doc(result.data['uid']).update({'username': username});
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user role
  Future<String?> getUserRole(String uid) async {
    try {
      // First try the 'users' collection (new structure)
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          final role = data['role'] as String?;
          debugPrint('User role from users collection: $role');
          return role;
        }
      }
      
      // If not found, try the 'user' collection (old structure)
      debugPrint('User not found in users collection, checking user collection...');
      final oldDoc = await _firestore.collection('user').doc(uid).get();
      if (oldDoc.exists) {
        final data = oldDoc.data();
        if (data != null) {
          // Handle old role structure (object with boolean flags)
          String? role;
          if (data['role'] is String) {
            role = data['role'] as String;
          } else if (data['role'] is Map) {
            final roleMap = data['role'] as Map<String, dynamic>;
            if (roleMap['admin'] == true) {
              role = 'admin';
            } else if (roleMap['client'] == true) {
              role = 'client';
            } else if (roleMap['packer'] == true) {
              role = 'packer';
            }
          }
          debugPrint('User role from user collection: $role');
          return role;
        }
      }
      
      debugPrint('User document does not exist for uid: $uid in either collection');
      return null;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createUserWithRole(String email, String password, String role) async {
    try {
      final url = Uri.parse('https://remix-wgxs2bbz5q-uc.a.run.app/createUserWithRoleHttp');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Migrate user from old collection to new collection
  Future<void> migrateUserToNewCollection(String uid) async {
    try {
      // Check if user exists in old collection
      final oldDoc = await _firestore.collection('user').doc(uid).get();
      if (!oldDoc.exists) {
        debugPrint('User not found in old collection for migration');
        return;
      }

      final userData = oldDoc.data();
      if (userData == null) return;

      // Determine role from old structure
      String role = 'client'; // default
      if (userData['role'] is String) {
        role = userData['role'] as String;
      } else if (userData['role'] is Map) {
        final roleMap = userData['role'] as Map<String, dynamic>;
        if (roleMap['admin'] == true) {
          role = 'admin';
        } else if (roleMap['client'] == true) {
          role = 'client';
        } else if (roleMap['packer'] == true) {
          role = 'packer';
        }
      }

      // Create new user document
      await _firestore.collection('users').doc(uid).set({
        'email': userData['email'] ?? '',
        'role': role,
        'username': userData['username'] ?? '',
        'createdAt': userData['createdAt'] ?? FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'active',
        'warehouseId': userData['warehouseId'] ?? '',
        'customerId': userData['customerId'] ?? '',
        'lastLogin': FieldValue.serverTimestamp()
      });

      debugPrint('User migrated successfully to new collection');
    } catch (e) {
      debugPrint('Error migrating user: $e');
    }
  }
} 