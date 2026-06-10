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
}