import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    // First verify admin
    final adminUser = await _auth.signInWithEmailAndPassword(
      email: 'fed@gmail.com',
      password: 'admin123', // TODO: Move to secure storage
    );

    if (adminUser.user?.email != 'fed@gmail.com') {
      throw FirebaseAuthException(
        code: 'permission-denied',
        message: 'Only admin can create users',
      );
    }

    // Create the new user
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Store user data in Firestore
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'username': username,
      'email': email,
      'role': role,
      'createdBy': 'fed@gmail.com',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Sign out admin
    await _auth.signOut();
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