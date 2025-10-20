import 'dart:convert';
import 'package:http/http.dart' as http;

class PurchaseOrderService {
  static const String baseUrl = 'https://us-central1-breadcrumb-bd857.cloudfunctions.net/remix/api/purchase-orders';

  static Future<List<dynamic>> fetchPurchaseOrders() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load purchase orders');
    }
  }

  static Future<Map<String, dynamic>> createPurchaseOrder({
    required String clientId,
    required List<Map<String, dynamic>> items,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'clientId': clientId,
        'items': items,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create purchase order');
    }
  }

  static Future<Map<String, dynamic>> fetchPurchaseOrderById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load purchase order');
    }
  }
} 