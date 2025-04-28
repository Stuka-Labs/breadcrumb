import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ClaudeService {
  final String _apiKey = dotenv.env['CLAUDE_API_KEY'] ?? '';
  final String _baseUrl = 'https://api.anthropic.com/v1/messages';

  Future<String?> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': 'claude-3-5-sonnet-20241022',
        'max_tokens': 1024,
        'messages': [
          {'role': 'user', 'content': message}
        ],
      }),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Adjust this depending on the actual response structure
      return data['content']?.toString();
    } else {
      print('Claude API error: \\${response.statusCode} \\${response.body}');
      return null;
    }
  }
} 