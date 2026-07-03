class Product {
  final String id;
  final String name;
  final int price;
  final String category;
  final DateTime expiryDate;

  final int quantity;
  final int stock;

  final String unit;
  final String? barcode;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    required this.expiryDate,
    required this.quantity,
    required this.stock,
    this.unit = 'pcs',
    this.barcode,
  });
  
  Product copyWith({
    String? name,
    DateTime? expiryDate,
    String? category,
    int? price,
    int? quantity,
    int? stock,
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
      stock: stock ?? this.stock,
      unit: unit ?? this.unit,
      barcode: barcode ?? this.barcode,
    );
  }
  factory Product.fromJson(
    Map<String, dynamic> json, {
    String category = '',
  }) {
    return Product(
      id: json['id_item'].toString(),
      name: json['name'] ?? '',
      category: category,
      price: double.tryParse(json['price'].toString())?.toInt() ?? 0,
      expiryDate:
          DateTime.tryParse(json['expired_date']?.toString() ?? '') ??
          DateTime.now(),

      quantity: int.tryParse(json['quantity'].toString()) ?? 0,

      stock: int.tryParse(json['stok'].toString()) ?? 0,

      unit: json['unit'] ?? 'pcs',
      barcode: json['barcode'],
    );
  }
}