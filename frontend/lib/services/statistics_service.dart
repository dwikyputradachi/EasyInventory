import 'api_service.dart';

class StatisticsService {
  static Future<Map<String, dynamic>> getMonthlySpending(int year) async {
    return await ApiService.get('statistics/monthly_spending.php?year=$year');
  }
}