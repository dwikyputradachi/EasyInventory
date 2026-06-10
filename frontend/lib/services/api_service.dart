import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/app_data.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/easy_inventory/api';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2/easy_inventory/api';
    }
    return 'http://localhost/easy_inventory/api';
  }
  // return 'http://10.177.71.210/easy_inventory/api';

  static Map<String, String> get _headers {
    final token = AppData().token;

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');

      print('========== API GET ==========');
      print('URL: $url');
      print('TOKEN: ${AppData().token}');

      final res = await http.get(
        url,
        headers: _headers,
      );

      print('STATUS: ${res.statusCode}');
      print('BODY: ${res.body}');

      if (res.body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Empty response from server',
        };
      }

      return jsonDecode(res.body);
    } catch (e) {
      print('GET ERROR: $e');

      return {
        'status': 'error',
        'message': 'Network/JSON error: $e',
      };
    }
  }
  static Future<Map<String, dynamic>> post(
      String endpoint,
      Map<String, dynamic> body,
      ) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');

      print('========== API POST ==========');
      print('URL: $url');
      print('TOKEN: ${AppData().token}');
      print('BODY SENT: $body');

      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(body),
      );

      print('STATUS: ${res.statusCode}');
      print('BODY RESPONSE: ${res.body}');

      if (res.body.isEmpty) {
        return {
          'status': 'error',
          'message': 'Empty response from server',
        };
      }

      return jsonDecode(res.body);
    } catch (e) {
      print('POST ERROR: $e');

      return {
        'status': 'error',
        'message': 'Network/JSON error: $e',
      };
    }
  }
}