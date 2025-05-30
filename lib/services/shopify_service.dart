import 'package:http/http.dart' as http;
import 'dart:convert';

class ShopifyService {
  static const String baseUrl = 'https://your-remix-app.com/api'; // Update with your deployed Remix app URL

  static Future<List<dynamic>> fetchOrders() async {
    final response = await http.get(Uri.parse('$baseUrl/orders'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['orders']['edges'];
    } else {
      throw Exception('Failed to load orders');
    }
  }

  static Future<List<dynamic>> fetchProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data']['products']['edges'];
    } else {
      throw Exception('Failed to load products');
    }
  }
} 