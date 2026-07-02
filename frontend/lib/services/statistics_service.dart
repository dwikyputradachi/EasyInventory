import 'api_service.dart';

class StatisticsService {
  static Future<Map<String, dynamic>> getMonthlySpending(
      int year, {
        int? month,
      }) async {
    var endpoint = 'statistics/monthly_spending.php?year=$year';

    if (month != null) {
      endpoint += '&month=$month';
    }

    return await ApiService.get(endpoint);
  }
  static Future<List<Map<String, dynamic>>> getItemHistory({
    required int year,
    required int month,
  }) async {
    final response = await ApiService.get(
      'statistics/statistics_item_history.php?year=$year&month=$month',
    );

    if (response['status'] == 'success') {
      return List<Map<String, dynamic>>.from(
        response['data']['items'] ?? [],
      );
    }

    return [];
  }
  
  
}