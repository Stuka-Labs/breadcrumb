import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/signup_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/packer_screen.dart';
import 'services/auth_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
  runApp(const MyApp());
    } catch (e, stack) {
      debugPrint('Error initializing Firebase: $e');
      debugPrint('Stack trace: $stack');
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ));
    }
  }, (error, stack) {
    debugPrint('Error in main: $error');
    debugPrint('Stack trace: $stack');
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breadcrumb',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/signin': (context) => const SignInScreen(),
        '/admin': (context) => const AdminScreen(),
        '/packer': (context) => const PackerScreen(),
        '/client': (context) => const ClientScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }
        
        if (snapshot.hasData) {
          final user = snapshot.data!;
          if (user.email == 'fed@gmail.com') {
            return const AdminScreen();
          } else {
            return FutureBuilder<String?>(
              future: authService.getUserRole(user.uid),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                if (roleSnapshot.hasError) {
                  return Scaffold(
                    body: Center(
                      child: Text('Error: ${roleSnapshot.error}'),
                    ),
                  );
                }
                
                final role = roleSnapshot.data;
                if (role == 'packer') {
                  return const PackerScreen();
                } else if (role == 'client') {
                  return const ClientScreen();
                }
                
                return const SignInScreen();
              },
            );
          }
        }
        
        return const SignInScreen();
      },
    );
  }
}

class ClientScreen extends StatelessWidget {
  const ClientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            ),
          ],
        ),
      body: const Center(
        child: Text('Welcome to the Client Portal'),
      ),
    );
  }
}