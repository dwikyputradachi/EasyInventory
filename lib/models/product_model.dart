class Product {
  final String id;
  final String name;
  final int price;
  final String category;
  final DateTime expiryDate;
  final int quantity;
  final String unit;
  final String? barcode;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.expiryDate,
    required this.quantity,
    this.unit = 'pcs',
    this.barcode,
  });

  Product copyWith({
    String? name,
    DateTime? expiryDate,
    String? category,
    int? price,
    int? quantity,
    String? unit,
    String? barcode,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      expiryDate: expiryDate ?? this.expiryDate,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
    );
  }
}

class DummyData {
  static final List<Product> _products = [
    // Fresh Food
    Product(id: '1', name: 'Apel Fuji', price: 20000, category: 'Fresh Food', expiryDate: DateTime.now().add(const Duration(days: 5)), quantity: 12, unit: 'kg'),
    Product(id: '2', name: 'Bayam', price: 20000, category: 'Fresh Food', expiryDate: DateTime.now().add(const Duration(days: 2)), quantity: 3, unit: 'ikat'),
    Product(id: '3', name: 'Daging Sapi', price: 20000, category: 'Fresh Food', expiryDate: DateTime.now().add(const Duration(days: 1)), quantity: 2, unit: 'kg'),
    Product(id: '4', name: 'Ikan Salmon', price: 20000, category: 'Fresh Food', expiryDate: DateTime.now().subtract(const Duration(days: 1)), quantity: 1, unit: 'kg'),
    Product(id: '5', name: 'Telur Ayam', price: 20000, category: 'Fresh Food', expiryDate: DateTime.now().add(const Duration(days: 14)), quantity: 30, unit: 'butir'),
    Product(id: '6', name: 'Susu Segar', price: 20000, category: 'Fresh Food', expiryDate: DateTime.now().add(const Duration(days: 3)), quantity: 5, unit: 'liter'),
    Product(id: '7', name: 'Roti Tawar', price: 20000, category: 'Fresh Food', expiryDate: DateTime.now().add(const Duration(days: 4)), quantity: 2, unit: 'bungkus'),

    // Pantry
    Product(id: '8', name: 'Beras Premium', price: 20000, category: 'Pantry', expiryDate: DateTime.now().add(const Duration(days: 180)), quantity: 10, unit: 'kg'),
    Product(id: '9', name: 'Minyak Goreng', price: 20000, category: 'Pantry', expiryDate: DateTime.now().add(const Duration(days: 90)), quantity: 4, unit: 'liter'),
    Product(id: '10', name: 'Gula Pasir', price: 20000, category: 'Pantry', expiryDate: DateTime.now().add(const Duration(days: 365)), quantity: 3, unit: 'kg'),

    // Beverages
    Product(id: '11', name: 'Teh Botol', price: 20000, category: 'Beverages', expiryDate: DateTime.now().add(const Duration(days: 30)), quantity: 24, unit: 'botol'),
    Product(id: '12', name: 'Air Mineral', price: 20000, category: 'Beverages', expiryDate: DateTime.now().add(const Duration(days: 365)), quantity: 48, unit: 'botol'),
    Product(id: '13', name: 'Jus Jeruk', price: 20000, category: 'Beverages', expiryDate: DateTime.now().add(const Duration(days: 7)), quantity: 6, unit: 'kotak'),

    // Toiletries
    Product(id: '14', name: 'Sabun Mandi', price: 20000, category: 'Toiletries', expiryDate: DateTime.now().add(const Duration(days: 730)), quantity: 6, unit: 'batang'),
    Product(id: '15', name: 'Sampo', price: 20000, category: 'Toiletries', expiryDate: DateTime.now().add(const Duration(days: 365)), quantity: 3, unit: 'botol'),

    // Household Items
    Product(id: '16', name: 'Deterjen', price: 20000, category: 'Households Items', expiryDate: DateTime.now().add(const Duration(days: 365)), quantity: 4, unit: 'kg'),
    Product(id: '17', name: 'Sabun Cuci Piring', price: 20000, category: 'Households Items', expiryDate: DateTime.now().add(const Duration(days: 365)), quantity: 2, unit: 'botol'),

    // Others
    Product(id: '18', name: 'Baterai AA', price: 20000, category: 'Others', expiryDate: DateTime.now().add(const Duration(days: 1095)), quantity: 8, unit: 'pcs'),
  ];

  static List<Product> getProductsByCategory(String category) {
    return _products.where((p) => p.category == category).toList();
  }
}