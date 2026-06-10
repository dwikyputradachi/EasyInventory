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

  factory AppData() {
    return _instance;
  }

  AppData._internal();
  String token = '';
  int userId = 0;
  String name = '';
  String email = '';
  String profilePhoto = '';
  String profileImagePath = '';

  void setProfilePhoto(String photo) {
    profilePhoto = photo;
  }

bool get isLoggedIn => userId != 0;

  void setSession({
    required String token,
    required int userId,
    required String name,
    required String email,
  }) {
    this.token = token;
    this.userId = userId;
    this.name = name;
    this.email = email;

    print('========== APP DATA SESSION SET ==========');
    print('TOKEN: ${this.token}');
    print('USER ID: ${this.userId}');
    print('NAME: ${this.name}');
    print('EMAIL: ${this.email}');
    print('IS LOGGED IN: $isLoggedIn');
  }

  void clearSession() {
    token = '';
    userId = 0;
    name = '';
    email = '';
    profilePhoto = '';
    profileImagePath = '';
    inventory.clear();


    print('========== APP DATA SESSION CLEARED ==========');
  }
  final List<InventoryItem> inventory = [];

  bool budgetRecommendationEnabled = true;

  void addItems(List<InventoryItem> items) {
    inventory.addAll(items);

    print('========== INVENTORY ADDED ==========');
    print('TOTAL LOCAL INVENTORY: ${inventory.length}');
  }

  String _monthLabel(DateTime date) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

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

  // =========================================================
  // DEBUG HELPER
  // Panggil ini kalau mau cek session dari page/service lain
  // =========================================================
  void debugSession() {
    print('========== APP DATA DEBUG ==========');
    print('TOKEN: $token');
    print('USER ID: $userId');
    print('NAME: $name');
    print('EMAIL: $email');
    print('IS LOGGED IN: $isLoggedIn');
  }
}