import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
    final doc = await _firestore.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }
} 