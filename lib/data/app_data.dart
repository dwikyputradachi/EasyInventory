// lib/data/app_data.dart
// Penyimpanan sementara di memori — nanti ganti dengan database asli

class InventoryItem {
  final String name;
  final String category;
  final int price;
  final DateTime scannedAt;

  InventoryItem({
    required this.name,
    required this.category,
    required this.price,
    required this.scannedAt,
  });
}

class AppData {
  // Singleton agar data bisa diakses dari mana saja
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  final List<InventoryItem> inventory = [];

  void addItems(List<InventoryItem> items) {
    inventory.addAll(items);
  }

  // Total spending per bulan
  Map<String, int> get spendingPerMonth {
    final Map<String, int> result = {};
    for (final item in inventory) {
      final key = _monthLabel(item.scannedAt);
      result[key] = (result[key] ?? 0) + item.price;
    }
    return result;
  }

  // Jumlah item per kategori
  Map<String, int> get itemsPerCategory {
    final Map<String, int> result = {};
    for (final item in inventory) {
      result[item.category] = (result[item.category] ?? 0) + 1;
    }
    return result;
  }

  String _monthLabel(DateTime date) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month]} ${date.year}';
  }
}