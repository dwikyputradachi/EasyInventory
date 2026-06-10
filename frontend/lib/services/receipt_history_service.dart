import 'api_service.dart';

class ReceiptHistoryService {
  static Future<List<Map<String, dynamic>>> getByMonth({
    required int year,
    required int month,
  }) async {
    final res = await ApiService.get(
      'receipt/get_receipts_by_month.php?year=$year&month=$month',
    );
    if (res['status'] == 'success') {
      return List<Map<String, dynamic>>.from(res['data'] ?? []);
    }

    return [];
  }
}
