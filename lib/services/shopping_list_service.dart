import 'api_service.dart';

class ShoppingListService {
  static Future<Map<String, dynamic>> AddItem() async {
    return await ApiService.get('shopping_list/add_item.php');
  }
  static Future<Map<String, dynamic>> GetList() async {
    return await ApiService.get('shopping_list/get_lists.php'); 
  }
  static Future<Map<String, dynamic>> AddList(int id) async {
    return await ApiService.get('shopping_list/add_list.php?id=$id'); 
  }
  static Future<Map<String, dynamic>> UpdateItemStatus(int id) async {
    return await ApiService.get('shopping_list/update_item_status.php?id=$id'); 
  }
}