import 'api_service.dart';

class ReceiptHistoryService {
  static Future<List<Map<String, dynamic>>> getItemHistory({
    required int year,
    required int month,
  }) async {
    final response = await ApiService.get(
      '/statistics_item_history.php?year=$year&month=$month',
    );

    if (response['status'] == 'success') {
      return List<Map<String, dynamic>>.from(
        response['data']['items'] ?? [],
      );
    }

    return [];
  }
}
