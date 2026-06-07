import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ⚠️  Bilgisayarının IP adresini buraya yaz (ipconfig ile bul)
  static const String baseUrl = 'http://192.168.1.22:5000';

  /// Sends a chat message and returns the reply string.
  static Future<String> chat({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/chat'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'message': message, 'history': history}),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] as String? ?? '...';
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Chat request failed');
    }
  }

  /// Sends a prompt and returns a base64-encoded PNG string.
  static Future<String> paint(String prompt) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/paint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'prompt': prompt}),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['image'] as String;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Paint request failed');
    }
  }
}
