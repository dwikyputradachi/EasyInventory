import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../constants/colors.dart';
import '../models/product_model.dart';
import 'product_detail_page.dart';
import '../services/api_service.dart';

class CategoryDetailPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const CategoryDetailPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends State<CategoryDetailPage> {
  late List<Product> _products;
  String _search = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _products = [];
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    final data = await ApiService.getItemsByCategory(
      widget.categoryId,
      widget.categoryName,
    );

    if (!mounted) return;

    setState(() {
      _products = data;
      _isLoading = false;
    });
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

  void _openDetail(Product product) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
    );

    if (result == true || result == 'deleted') {
      setState(() {
        _isLoading = true;
      });

      await _loadProducts();
    }
  }

  Future<void> _showDeleteDialog(Product product) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Stock is 0. Do you want to delete this product?'),

      ),
    );
  }

  Future<void> _increaseQty(Product p) async {
    final newQty = p.quantity + 1;

    setState(() {
      _isLoading = true;
    });

    final success = await ApiService.updateItemStock(p.id, newQty);

    if (success) {
      await _loadProducts();
    } else {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update stock')),
      );
    }
  }

  Future<void> _decreaseQty(Product p) async {
    if (p.quantity <= 1) {
      _showDeleteDialog(p);
      return;
    }

    final newQty = p.quantity - 1;

    setState(() {
      _isLoading = true;
    });

    final success = await ApiService.updateItemStock(p.id, newQty);

    if (success) {
      await _loadProducts();
    } else {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update stock')),
      );
    }
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
    icon: const Icon(
      Icons.arrow_back_ios_new,
      color: AppColors.textPrimary,
      size: 18,
    ),
    onPressed: () => Navigator.pop(context, true),
  ),
  title: Text(
    widget.categoryName,
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      fontSize: 16,
    ),
  ),
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
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
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                p.name,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
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
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: color.withOpacity(0.35),
          ),
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