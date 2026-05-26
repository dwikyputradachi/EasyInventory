import 'dart:convert';
import 'package:http/http.dart' as http;
import '../data/app_data.dart';

class ApiService {
  static const String baseUrl = 'http://localhost/easy_inventory/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${AppData().token}',
      };

  // GET request
  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _headers,
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }

  // POST request
  static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _headers,
        body: jsonEncode(body),
      );
      return jsonDecode(res.body);
    } catch (e) {
      return {'status': 'error', 'message': 'Network error: $e'};
    }
  }
}