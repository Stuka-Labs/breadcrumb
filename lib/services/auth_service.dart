import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
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
    final doc = await _firestore.collection('user').doc(uid).get();
    final role = doc.data()?['role'];
    if (role == null) return null;
    if (role['admin'] == true) return 'admin';
    if (role['packer'] == true) return 'packer';
    if (role['client'] == true) return 'client';
    return null;
  }

  Future<Map<String, dynamic>> createUserWithRole(String email, String password, String role) async {
    try {
      final url = Uri.parse('https://us-central1-breadcrumb-bd857.cloudfunctions.net/createUserWithRoleHttp');
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
        throw Exception('Failed to create user: \\nStatus: \\${response.statusCode}\\nBody: \\${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }
} 