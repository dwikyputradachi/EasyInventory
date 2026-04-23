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
  static final AppData _instance = AppData._internal();
  factory AppData() => _instance;
  AppData._internal();

  final List<InventoryItem> inventory = [];

  // --- TAMBAHKAN INI ---
  bool budgetRecommendationEnabled = false; 
  // --------------------

  void addItems(List<InventoryItem> items) {
    inventory.addAll(items);
  }

  void addItem(InventoryItem item) {
    inventory.add(item);
  }

  Map<String, int> get spendingPerMonth {
    final Map<String, int> result = {};
    for (final item in inventory) {
      final key = _monthLabel(item.scannedAt);
      result[key] = (result[key] ?? 0) + item.price;
    }
    return result;
  }

  Map<String, int> get itemsPerCategory {
    final Map<String, int> result = {};
    for (final item in inventory) {
      result[item.category] = (result[item.category] ?? 0) + 1;
    }
    return result;
  }

  int get totalSpending {
    return inventory.fold(0, (sum, item) => sum + item.price);
  }

  String _monthLabel(DateTime date) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month]} ${date.year}';
  }
}