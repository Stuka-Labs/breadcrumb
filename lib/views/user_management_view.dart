import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class UserManagementView extends StatefulWidget {
  @override
  _UserManagementViewState createState() => _UserManagementViewState();
}

class _UserManagementViewState extends State<UserManagementView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'user';
  final AuthService _authService = AuthService();
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('User Management')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) => value?.isEmpty ?? true ? 'Please enter an email' : null,
              ),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value?.isEmpty ?? true ? 'Please enter a password' : null,
              ),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: [
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  DropdownMenuItem(value: 'packer', child: Text('Packer')),
                  DropdownMenuItem(value: 'client', child: Text('Client')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedRole = value!;
                  });
                },
                decoration: InputDecoration(labelText: 'Role'),
              ),
              if (_errorMessage != null)
                Text(_errorMessage!, style: TextStyle(color: Colors.red)),
              ElevatedButton(
                onPressed: _createUser,
                child: Text('Create User'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createUser() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final result = await _authService.createUserWithRole(
          _emailController.text,
          _passwordController.text,
          _selectedRole,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User created successfully: ${result['uid']}')),
        );
        _emailController.clear();
        _passwordController.clear();
        setState(() {
          _errorMessage = null;
        });
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }
} 