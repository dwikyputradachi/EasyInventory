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

  factory Product.fromJson(
    Map<String, dynamic> json, {
    String category = '',
  }) {
    return Product(
      id: json['id_item'].toString(),
      name: json['name'] ?? '',
      category: category,
      price: double.tryParse(json['price'].toString())?.toInt() ?? 0,
      expiryDate: DateTime.tryParse(json['expired_date']?.toString() ?? '') ??
          DateTime.now(),
      quantity: int.tryParse(json['quantity'].toString()) ??
          int.tryParse(json['stok'].toString()) ??
          0,
      unit: json['unit'] ?? 'pcs',
      barcode: json['barcode'],
    );
  }

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