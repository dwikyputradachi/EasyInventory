import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/app_data.dart';
import '../models/product_model.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost/easy_inventory/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/easy_inventory/api';
    }

    return 'http://localhost/easy_inventory/api';
  }

  static Map<String, String> get _headers {
    final token = '${AppData().token}';

    return {
      'Content-Type': 'application/json',
      if (token.isNotEmpty && token != 'null') 'Authorization': 'Bearer $token',
    };
  }

  // =====================================================
  // GENERIC
  // =====================================================

  static Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');

      debugPrint('========== API GET ==========');
      debugPrint('URL: $url');
      debugPrint('TOKEN: ${AppData().token}');

      final res = await http.get(url, headers: _headers);

      debugPrint('STATUS: ${res.statusCode}');
      debugPrint('BODY: ${res.body}');

      if (res.body.isEmpty) {
        return {
          'success': false,
          'status': 'error',
          'message': 'Empty response from server',
        };
      }

      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('GET ERROR: $e');

      return {
        'success': false,
        'status': 'error',
        'message': 'Network/JSON error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');

      debugPrint('========== API POST ==========');
      debugPrint('URL: $url');
      debugPrint('TOKEN: ${AppData().token}');
      debugPrint('BODY SENT: $data');

      final res = await http.post(
        url,
        headers: _headers,
        body: jsonEncode(data),
      );

      debugPrint('STATUS: ${res.statusCode}');
      debugPrint('BODY RESPONSE: ${res.body}');

      if (res.body.isEmpty) {
        return {
          'success': false,
          'status': 'error',
          'message': 'Empty response from server',
        };
      }

      return jsonDecode(res.body);
    } catch (e) {
      debugPrint('POST ERROR: $e');

      return {
        'success': false,
        'status': 'error',
        'message': 'Network/JSON error: $e',
      };
    }
  }

  // =====================================================
  // BARCODE
  // =====================================================

  static Future<Map<String, dynamic>?> findProductByBarcode(
    String barcode,
  ) async {
    final body = await get('item/find_by_barcode.php?barcode=$barcode');

    if (body['status'] == 'success' || body['success'] == true) {
      return body['data'];
    }

    return null;
  }

  // =====================================================
  // CATEGORY
  // =====================================================

  static Future<List<dynamic>> getCategories() async {
    final body = await get('category/get_categories.php');

    return body['data'] ?? [];
  }

  // =====================================================
  // ITEMS
  // =====================================================

  static Future<List<Product>> getItemsByCategory(
    int categoryId,
    String categoryName,
  ) async {
    final body = await get(
      'item/get_items_by_category.php?id_category=$categoryId',
    );

    final List data = body['data'] ?? [];

    return data
        .map(
          (e) => Product.fromJson(
            e,
            category: categoryName,
          ),
        )
        .toList();
  }

  static Future<bool> addItem(
    Map<String, dynamic> data, {
    int? categoryId,
  }) async {
    try {
      final endpoint = categoryId == null
          ? 'item/add_item.php'
          : 'item/add_item.php?id_category=$categoryId';

      final res = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );

      debugPrint('========== ADD ITEM ==========');
      debugPrint('URL: $baseUrl/$endpoint');
      debugPrint('TOKEN: ${AppData().token}');
      debugPrint('BODY SENT: $data');
      debugPrint('STATUS: ${res.statusCode}');
      debugPrint('BODY: ${res.body}');

      if (res.body.isEmpty) {
        return false;
      }

      final body = jsonDecode(res.body);

      return (res.statusCode == 200 || res.statusCode == 201) &&
          (body['success'] == true || body['status'] == 'success');
    } catch (e) {
      debugPrint('ADD ITEM ERROR: $e');
      return false;
    }
  }

  static Future<bool> updateItem(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    try {
      final bodyData = {
        ...data,
        'id_item': itemId,
      };

      final res = await http.put(
        Uri.parse('$baseUrl/item/update_item.php'),
        headers: _headers,
        body: jsonEncode(bodyData),
      );

      debugPrint('========== UPDATE ITEM ==========');
      debugPrint('URL: $baseUrl/item/update_item.php');
      debugPrint('TOKEN: ${AppData().token}');
      debugPrint('BODY SENT: $bodyData');
      debugPrint('STATUS: ${res.statusCode}');
      debugPrint('BODY: ${res.body}');

      if (res.body.isEmpty) {
        return false;
      }

      final body = jsonDecode(res.body);

      return res.statusCode == 200 &&
          (body['success'] == true || body['status'] == 'success');
    } catch (e) {
      debugPrint('UPDATE ITEM ERROR: $e');
      return false;
    }
  }

  static Future<bool> updateItemStock(String idItem, int change) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/item/update_stock.php'),
        headers: _headers,
        body: jsonEncode({
          'id_item': idItem,
          'change': change,
        }),
      );

      debugPrint('========== UPDATE STOCK ==========');
      debugPrint('URL: $baseUrl/item/update_stock.php');
      debugPrint('TOKEN: ${AppData().token}');
      debugPrint('BODY SENT: {id_item: $idItem, change: $change}');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY: ${response.body}');

      if (response.body.isEmpty) {
        return false;
      }

      final data = jsonDecode(response.body);

      return response.statusCode == 200 && data['success'] == true;
    } catch (e) {
      debugPrint('UPDATE STOCK ERROR: $e');
      return false;
    }
  }

  static Future<bool> deleteItem(String itemId) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/item/delete_item.php?id_item=$itemId'),
        headers: _headers,
      );

      debugPrint('========== DELETE ITEM ==========');
      debugPrint('URL: $baseUrl/item/delete_item.php?id_item=$itemId');
      debugPrint('TOKEN: ${AppData().token}');
      debugPrint('STATUS: ${res.statusCode}');
      debugPrint('BODY: ${res.body}');

      if (res.body.isEmpty) {
        return false;
      }

      final body = jsonDecode(res.body);

      return res.statusCode == 200 &&
          (body['success'] == true || body['status'] == 'success');
    } catch (e) {
      debugPrint('DELETE ITEM ERROR: $e');
      return false;
    }
  }

  // =====================================================
  // DASHBOARD
  // =====================================================

  static Future<Map<String, dynamic>?> getDashboard() async {
    final body = await get('dashboard/dashboard.php');

    if (body['status'] == 'success' || body['success'] == true) {
      return body['data'];
    }

    return null;
  }

  static Future<Map<String, dynamic>?> getStockHealth() async {
    final body = await get(
      'dashboard/stock_health.php?id_user=${AppData().userId}',
    );

    if (body['status'] == 'success' || body['success'] == true) {
      return body['data'];
    }

    return null;
  }

  // =====================================================
  // NOTIFICATION
  // =====================================================

  static Future<List<dynamic>> getNotifications() async {
    final body = await get('notification/get_notifications.php');

    return body['data'] ?? [];
  }

  static Future<bool> markNotificationAsRead(String id) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/notification/mark_read.php?id=$id'),
        headers: _headers,
      );

      debugPrint('========== MARK NOTIFICATION READ ==========');
      debugPrint('URL: $baseUrl/notification/mark_read.php?id=$id');
      debugPrint('TOKEN: ${AppData().token}');
      debugPrint('STATUS: ${res.statusCode}');
      debugPrint('BODY: ${res.body}');

      if (res.body.isEmpty) {
        return false;
      }

      final body = jsonDecode(res.body);

      return res.statusCode == 200 &&
          (body['success'] == true || body['status'] == 'success');
    } catch (e) {
      debugPrint('MARK NOTIFICATION READ ERROR: $e');
      return false;
    }
  }

  static Future<bool> markAllNotificationsAsRead() async {
    try {
      final res = await http.put(
        Uri.parse(
          '$baseUrl/notification/mark_all_read.php?id_user=${AppData().userId}',
        ),
        headers: _headers,
      );

      debugPrint('========== MARK ALL NOTIFICATIONS READ ==========');
      debugPrint(
        'URL: $baseUrl/notification/mark_all_read.php?id_user=${AppData().userId}',
      );
      debugPrint('TOKEN: ${AppData().token}');
      debugPrint('STATUS: ${res.statusCode}');
      debugPrint('BODY: ${res.body}');

      if (res.body.isEmpty) {
        return false;
      }

      final body = jsonDecode(res.body);

      return res.statusCode == 200 &&
          (body['success'] == true || body['status'] == 'success');
    } catch (e) {
      debugPrint('MARK ALL NOTIFICATIONS READ ERROR: $e');
      return false;
    }
  }
}