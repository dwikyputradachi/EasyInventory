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

  // ── Session user (diisi setelah login) ──
  String token   = '';
  int    userId  = 0;
  String name    = '';
  String email   = '';

  bool get isLoggedIn => token.isNotEmpty;

  void setSession({
    required String token,
    required int userId,
    required String name,
    required String email,
  }) {
    this.token  = token;
    this.userId = userId;
    this.name   = name;
    this.email  = email;
  }

  void clearSession() {
    token  = '';
    userId = 0;
    name   = '';
    email  = '';
    inventory.clear();
  }

  // ── Inventory sementara (nanti diganti dari API) ──
  final List<InventoryItem> inventory = [];
  bool budgetRecommendationEnabled = true;

  void addItems(List<InventoryItem> items) => inventory.addAll(items);

  String _monthLabel(DateTime date) {
    const months = ['', 'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month]} ${date.year}';
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
}