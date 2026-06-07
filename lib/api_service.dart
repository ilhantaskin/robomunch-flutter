import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiService {
  // Backend 1: laptop IP
  static const String baseUrl = 'http://192.168.1.22:5000';

  // Backend 2: Google Cloud VM IP
  static const String cloudUrl = 'http://35.188.117.155:8000';

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
        .timeout(const Duration(seconds: 120));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] as String? ?? '...';
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Chat request failed');
    }
  }

  static Future<String> paint(String prompt) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/paint'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'prompt': prompt}),
        )
        .timeout(const Duration(minutes: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['image'] as String;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['error'] ?? 'Paint request failed');
    }
  }

  static Uint8List _decodeImageBase64(String imageB64) {
    // Eğer "data:image/png;base64,...." formatında gelirse başlığı siler.
    final cleanBase64 = imageB64.contains(',')
        ? imageB64.split(',').last
        : imageB64;

    return base64Decode(cleanBase64);
  }

  static Future<Map<String, dynamic>> colorize(String imageB64) async {
    final imageBytes = _decodeImageBase64(imageB64);

    final result = <String, dynamic>{};

    // 1) Get resolution
    final resolutionRequest = http.MultipartRequest(
      'POST',
      Uri.parse('$cloudUrl/get/resolution'),
    );

    resolutionRequest.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'generated.png',
      ),
    );

    final resolutionResponse = await resolutionRequest
        .send()
        .timeout(const Duration(seconds: 60));

    final resolutionBody = await resolutionResponse.stream.bytesToString();

    if (resolutionResponse.statusCode == 200) {
      final data = jsonDecode(resolutionBody);
      result['resolution'] = data['resolution'];
    } else {
      throw Exception(
        'Resolution failed: ${resolutionResponse.statusCode} $resolutionBody',
      );
    }

    // 2) Convert to grayscale
    final grayscaleRequest = http.MultipartRequest(
      'POST',
      Uri.parse('$cloudUrl/convert/grayscale'),
    );

    grayscaleRequest.files.add(
      http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'generated.png',
      ),
    );

    final grayscaleResponse = await grayscaleRequest
        .send()
        .timeout(const Duration(seconds: 60));

    final grayscaleBytes = await grayscaleResponse.stream.toBytes();

    if (grayscaleResponse.statusCode == 200) {
      // UI tarafı zaten base64 image beklediği için geri base64 veriyoruz.
      result['image'] = base64Encode(grayscaleBytes);
    } else {
      final errorBody = utf8.decode(grayscaleBytes, allowMalformed: true);
      throw Exception(
        'Grayscale failed: ${grayscaleResponse.statusCode} $errorBody',
      );
    }

    return result;
  }
}