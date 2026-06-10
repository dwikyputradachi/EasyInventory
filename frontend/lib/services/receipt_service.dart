import 'package:intl/intl.dart';
import 'api_service.dart';

class ReceiptService {
  static const Map<String, int> _categoryMap = {
    'Fresh Food': 1,
    'Pantry': 2,
    'Beverages': 3,
    'Toiletries': 4,
    'Households Items': 5,
    'Household Items': 5,
    'Others': 6,
    'Cleaning Supplies': 7,
    'Cleaning': 7,
  };

  static int getCategoryId(String categoryName) {
    return _categoryMap[categoryName] ?? 6;
  }

  static Future<Map<String, dynamic>> saveReceipt(
      List<Map<String, dynamic>> scannedItems,
      ) async {
    final receiptName =
        'Receipt ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}';

    final items = scannedItems.map((item) {
      return {
        'name': item['name'],
        'price': item['price'],
        'quantity': item['quantity'] ?? 1,
        'id_category': getCategoryId(item['category'] ?? 'Others'),
      };
    }).toList();

    return await ApiService.post('receipt/save_receipt.php', {
      'receipt_name': receiptName,
      'items': items,
    });
  }
}