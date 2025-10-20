import 'dart:convert';
import 'package:http/http.dart' as http;

class ClientService {
  static const String baseUrl = 'https://us-central1-breadcrumb-bd857.cloudfunctions.net/remix/api/clients';

  static Future<List<dynamic>> fetchClients() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load clients');
    }
  }

  static Future<Map<String, dynamic>> createClient({
    required String name,
    required String shopType,
  }) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'shopType': shopType,
      }),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create client');
    }
  }

  static Future<Map<String, dynamic>> fetchClientById(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load client');
    }
  }

  static Future<Map<String, dynamic>> updateClient({
    required String id,
    required String name,
    required String shopType,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'shopType': shopType,
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update client');
    }
  }

  static Future<void> deleteClient(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete client');
    }
  }
} 