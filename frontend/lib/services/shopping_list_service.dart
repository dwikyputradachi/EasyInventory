import 'api_service.dart';

class ShoppingListService {
  static Future<List<dynamic>> getShoppingLists() async {
    final res = await ApiService.get('shopping_list/get_lists.php');
    if (res['status'] == 'success') return res['data'] ?? [];
    throw Exception(res['message'] ?? 'Failed to load shopping list');
  }

  static Future<int> createShoppingList(String title) async {
    final now = DateTime.now();
    final res = await ApiService.post('shopping_list/add_list.php', {
      'title': title,
      'month': now.month,
      'year':  now.year,
    });
    if (res['status'] == 'success') {
      return int.parse(res['data']['id_shopping_list'].toString());
    }
    throw Exception(res['message'] ?? 'Failed to create shopping list');
  }

  static Future<void> addItem({
    required int    idShoppingList,
    required String nameItem,
    required int    quantity,
    required String unit,
    required String priority,
  }) async {
    final res = await ApiService.post('shopping_list/add_item.php', {
      'id_shopping_list': idShoppingList,
      'name_item':        nameItem,
      'quantity':         quantity,
      'unit':             unit,
      'priority':         priority,
    });
    if (res['status'] != 'success') {
      throw Exception(res['message'] ?? 'Failed to add item');
    }
  }

  static Future<void> updateStatus({
    required int  idShoppingItem,
    required bool isBought,
  }) async {
    final res = await ApiService.post('shopping_list/update_item_status.php', {
      'id_shopping_item': idShoppingItem,
      'is_bought':        isBought ? 1 : 0,
    });
    if (res['status'] != 'success') {
      throw Exception(res['message'] ?? 'Failed to update status');
    }
  }
}