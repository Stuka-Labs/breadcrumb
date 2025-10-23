import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/demo_data_service.dart';

class SignUpScreen extends StatefulWidget {
  final bool isAdminCreating;
  const SignUpScreen({super.key, this.isAdminCreating = false});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  String _selectedRole = 'client';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        if (widget.isAdminCreating) {
          // Admin creates user with email/password and selected role
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'email': _emailController.text.trim(),
            'username': _usernameController.text.trim(),
            'role': _selectedRole,
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          // Auto-populate demo data for client@gmail.com
          if (_emailController.text.trim() == 'client@gmail.com' && _selectedRole == 'client') {
            try {
              await DemoDataService.populateDemoData(userCredential.user!.uid);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 Demo account created! You now have access to sample orders, products, and analytics.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
            } catch (e) {
              debugPrint('Error populating demo data: $e');
            }
          }
          // Delete the new user's session so admin stays signed in
          await FirebaseAuth.instance.currentUser?.delete();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User created successfully!')),
          );
          if (mounted) Navigator.pop(context);
        } else {
          // Normal user self-signup
          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
          // Ask for role
          if (mounted) {
            final selectedRole = await showDialog<String>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('What\'s your role?'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, 'admin'),
                      child: const Text('Admin'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, 'packer'),
                      child: const Text('Packer'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, 'client'),
                      child: const Text('Client'),
                    ),
                  ],
                ),
              ),
            );
            // Assign selected role in Firestore
            if (selectedRole != null) {
              await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
                'email': _emailController.text.trim(),
                'username': _usernameController.text.trim(),
                'role': selectedRole,
                'createdAt': FieldValue.serverTimestamp(),
              });
              
                  // Auto-populate demo data for client@gmail.com
                  if (_emailController.text.trim() == 'client@gmail.com' && selectedRole == 'client') {
                    try {
                      await DemoDataService.populateDemoData(userCredential.user!.uid);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🎉 Demo account created! You now have access to sample orders, products, and analytics.'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 4),
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('Error populating demo data: $e');
                    }
                  }
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account created successfully!')),
            );
            // Clear the form
            _formKey.currentState!.reset();
            _emailController.clear();
            _passwordController.clear();
            _confirmPasswordController.clear();
            _usernameController.clear();
            // Navigate to sign-in screen
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/signin');
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isAdminCreating ? 'Admin - Create User' : 'Create Account'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/Breadcrumb.png', height: 80),
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a username';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm the password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  if (widget.isAdminCreating) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'packer', child: Text('Packer')),
                        DropdownMenuItem(value: 'client', child: Text('Client')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedRole = value);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signUp,
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Text(widget.isAdminCreating ? 'Create User' : 'Create Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 