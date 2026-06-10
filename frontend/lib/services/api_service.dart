import 'dart:convert';
import 'package:http/http.dart' as http;

import '../data/app_data.dart';
import '../models/product_model.dart';

class ApiService {
  static const String baseUrl =
      'http://localhost/EasyInventory/backend/api';

  // =====================================================
  // GENERIC
  // =====================================================

  static Future<Map<String, dynamic>> get(String endpoint) async {
    final res = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
    );

    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    return jsonDecode(res.body);
  }

  // =====================================================
  // BARCODE
  // =====================================================

  static Future<Map<String, dynamic>?> findProductByBarcode(
    String barcode,
  ) async {
    final res = await http.get(
      Uri.parse('$baseUrl/item/find_by_barcode.php?barcode=$barcode'),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'];
    }

    return null;
  }

  // =====================================================
  // CATEGORY
  // =====================================================

  static Future<List<dynamic>> getCategories() async {
    final res = await http.get(
      Uri.parse(
        '$baseUrl/category/get_categories.php?id_user=${AppData().userId}',
      ),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'] ?? [];
    }

    return [];
  }

  // =====================================================
  // ITEMS
  // =====================================================

  static Future<List<Product>> getItemsByCategory(
    int categoryId,
    String categoryName,
  ) async {
    final res = await http.get(
      Uri.parse(
        '$baseUrl/item/get_items_by_category.php?id_category=$categoryId&id_user=${AppData().userId}',
      ),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
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

    return [];
  }

  static Future<bool> addItem(
    Map<String, dynamic> data, {
    int? categoryId,
  }) async {
    final url = categoryId == null
        ? '$baseUrl/item/add_item.php'
        : '$baseUrl/item/add_item.php?id_category=$categoryId';

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    return res.statusCode == 201;
  }

  static Future<bool> updateItem(
    String itemId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/item/update_item.php?id_item=$itemId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    return res.statusCode == 200;
  }

  static Future<bool> updateItemStock(
    String itemId,
    int quantity,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/item/update_stock.php?id_item=$itemId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'quantity': quantity}),
    );

    return res.statusCode == 200;
  }

  static Future<bool> deleteItem(String itemId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/item/delete_item.php?id_item=$itemId'),
    );

    return res.statusCode == 200;
  }

  // =====================================================
  // DASHBOARD
  // =====================================================

  static Future<Map<String, dynamic>?> getDashboard(int idUser) async {
    final res = await http.get(
      Uri.parse('$baseUrl/dashboard/dashboard.php?id_user=$idUser'),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'];
    }

    return null;
  }

  static Future<Map<String, dynamic>?> getStockHealth() async {
    final res = await http.get(
      Uri.parse(
        '$baseUrl/dashboard/stock_health.php?id_user=${AppData().userId}',
      ),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'];
    }

    return null;
  }

  // =====================================================
  // NOTIFICATION
  // =====================================================

  static Future<List<dynamic>> getNotifications() async {
    final res = await http.get(
      Uri.parse(
        '$baseUrl/notification/get_notifications.php?id_user=${AppData().userId}',
      ),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body['data'] ?? [];
    }

    return [];
  }

  static Future<bool> markNotificationAsRead(String id) async {
    final res = await http.put(
      Uri.parse('$baseUrl/notification/mark_read.php?id=$id'),
      headers: {'Content-Type': 'application/json'},
    );

    return res.statusCode == 200;
  }

  static Future<bool> markAllNotificationsAsRead() async {
    final res = await http.put(
      Uri.parse(
        '$baseUrl/notification/mark_all_read.php?id_user=${AppData().userId}',
      ),
      headers: {'Content-Type': 'application/json'},
    );

    return res.statusCode == 200;
  }
}