import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _products = DummyData.getProductsByCategory(widget.categoryName);
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
        _products[index] = result;
      });
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
    if (diff == 0) return 'Exp. hari ini';
    if (diff <= 3) return 'Exp. $diff hari lagi';
    return 'Exp. ${expiry.day}/${expiry.month}/${expiry.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _openAddProduct,
              icon: const Icon(Icons.add, color: AppColors.primary, size: 18),
              label: const Text(
                'Tambah',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _products.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum ada produk',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final p = _products[index];
                return GestureDetector(
                  onTap: () => _openDetail(p),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _expiryColor(p.expiryDate).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _expiryLabel(p.expiryDate),
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        color: _expiryColor(p.expiryDate),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Stok: ${p.quantity} ${p.unit}',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
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
              },
            ),
    );
  }
}