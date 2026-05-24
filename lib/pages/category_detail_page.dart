import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../constants/colors.dart';
import '../models/product_model.dart';
import 'product_detail_page.dart';
import 'add_product_page.dart';

class CategoryDetailPage extends StatefulWidget {
  final String categoryName;

  const CategoryDetailPage({super.key, required this.categoryName});

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  late List<Product> _products;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _products = DummyData.getProductsByCategory(widget.categoryName);
  }

  List<Product> get _filteredProducts {
    return _products
        .where((p) => p.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  Color _categoryColor() {
    if (widget.categoryName == 'Fresh Food') return const Color(0xFF22C55E);
    if (widget.categoryName == 'Pantry') return const Color(0xFFF59E0B);
    if (widget.categoryName == 'Beverages') return const Color(0xFF38BDF8);
    if (widget.categoryName == 'Toiletries') return const Color(0xFF8B5CF6);
    return AppColors.primary;
  }

  void _openAddProduct() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddProductPage(categoryName: widget.categoryName),
      ),
    );

    if (result != null && result is Product) {
      setState(() => _products.add(result));
    }
  }

  void _openDetail(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
    );

    if (result == 'deleted') {
      setState(() => _products.remove(product));
    } else if (result is Product) {
      setState(() {
        final index = _products.indexOf(product);
        if (index != -1) _products[index] = result;
      });
    }
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Stock is 0. Do you want to delete this product?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _products.remove(product));
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _increaseQty(Product p) {
    setState(() {
      final index = _products.indexOf(p);
      if (index != -1) {
        _products[index] = p.copyWith(quantity: p.quantity + 1);
      }
    });
  }

  void _decreaseQty(Product p) {
    final index = _products.indexOf(p);

    if (index != -1) {
      if (p.quantity > 1) {
        setState(() {
          _products[index] = p.copyWith(quantity: p.quantity - 1);
        });
      } else {
        _showDeleteDialog(p);
      }
    }
  }

  Color _expiryColor(DateTime expiry) {
    final diff = expiry.difference(DateTime.now()).inDays;
    if (diff < 0) return AppColors.danger;
    if (diff <= 3) return AppColors.warning;
    return AppColors.primary;
  }

  String _expiryLabel(DateTime expiry) {
    final diff = expiry.difference(DateTime.now()).inDays;
    if (diff < 0) return 'Expired';
    if (diff == 0) return 'Expires today';
    if (diff <= 3) return 'Expires in $diff days';
    return '${expiry.day}/${expiry.month}/${expiry.year}';
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _openAddProduct,
            icon: const Icon(Icons.add_circle_outline,
                color: AppColors.primary),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: InputDecoration(
                hintText: 'Search product...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: _filteredProducts.isEmpty
                ? _emptyState(color)
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              itemCount: _filteredProducts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final p = _filteredProducts[index];

                return Slidable(
                  key: ValueKey(p.id),
                  endActionPane: ActionPane(
                    motion: const StretchMotion(),
                    extentRatio: 0.48,
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _qtyButton(
                                Icons.remove,
                                AppColors.danger,
                                    () => _decreaseQty(p),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${p.quantity}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              _qtyButton(
                                Icons.add,
                                AppColors.primary,
                                    () => _increaseQty(p),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  child: _productCard(p, color),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _productCard(Product p, Color color) {
    return InkWell(
      onTap: () => _openDetail(p),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(Icons.inventory_2_outlined, color: color),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _badge(
                        _expiryLabel(p.expiryDate),
                        _expiryColor(p.expiryDate),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Stock: ${p.quantity} ${p.unit}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: color,
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }

  Widget _emptyState(Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 64, color: color.withOpacity(0.35)),
          const SizedBox(height: 12),
          const Text(
            'No product found',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}