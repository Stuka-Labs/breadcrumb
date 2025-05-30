import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class ShopifyService {
  static const String baseUrl = 'https://cardiac-statistical-oral-made.trycloudflare.com/api'; // Update with your deployed Remix app URL

  static Future<List<dynamic>> fetchOrders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }
    final idToken = await user.getIdToken();
    final response = await http.get(
      Uri.parse('$baseUrl/orders'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['orders']['edges'];
    } else {
      throw Exception('Failed to load orders');
    }
  }

  static Future<List<dynamic>> fetchProducts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not signed in');
    }
    final idToken = await user.getIdToken();
    final response = await http.get(
      Uri.parse('$baseUrl/products'),
      headers: {'Authorization': 'Bearer $idToken'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['products']['edges'];
    } else {
      throw Exception('Failed to load products');
    }
  }
} 