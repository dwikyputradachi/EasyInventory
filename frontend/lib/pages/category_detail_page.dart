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

  // id item yang sedang diproses network call (untuk disable tombol + spinner kecil)
  // Product.id bertipe String, jadi Set-nya juga harus String.
  final Set<String> _pendingIds = {};

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
    // Navigasi TIDAK diubah.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductDetailPage(product: product)),
    );

    if (result == true || result == 'deleted') {
      await _loadProducts();
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          backgroundColor: isError ? AppColors.danger : const Color(0xFF16A34A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // Product.id bertipe String -> parameter juga String.
  int _indexOf(String id) => _products.indexWhere((e) => e.id == id);

  // ================= PLUS =================
  // Langsung update state + call backend + snackbar. TIDAK ada dialog.
  Future<void> _increaseQty(Product p) async {
    if (_pendingIds.contains(p.id)) return;
    final index = _indexOf(p.id);
    if (index == -1) return;

    final oldStock = p.stock;
    final oldPrice = p.price;

    setState(() {
      _pendingIds.add(p.id);
      _products[index] = p.copyWith(stock: oldStock + 1); // optimistic, stok saja
    });

    final result = await ApiService.updateItemStock(p.id, 1, unitPrice: p.price);

    if (!mounted) return;
    setState(() => _pendingIds.remove(p.id));

    if (result != null) {
      final newStock = int.tryParse(result['stok'].toString()) ?? oldStock + 1;
      final newPrice = double.tryParse(result['price'].toString())?.toInt() ?? oldPrice;

      final i = _indexOf(p.id);
      if (i != -1) {
        setState(() {
          _products[i] = _products[i].copyWith(stock: newStock, price: newPrice);
        });
      }
      _showSnack('Quantity berhasil ditambahkan');
    } else {
      final i = _indexOf(p.id);
      if (i != -1) {
        setState(() => _products[i] = _products[i].copyWith(stock: oldStock, price: oldPrice));
      }
      _showSnack('Gagal menambah quantity', isError: true);
    }
  }

  // ================= MINUS =================
  // Jika stock > 1: langsung update, tanpa dialog.
  // Jika stock == 1: tampilkan dialog konfirmasi hapus (stock akan jadi 0).
  Future<void> _decreaseQty(Product p) async {
    if (_pendingIds.contains(p.id)) return;

    if (p.stock <= 1) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Hapus Item?'),
          content: Text(
            'Quantity akan menjadi 0.\n'
            '${p.name} akan dihapus dari inventory.\n\nLanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('NO'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('YES'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      setState(() => _pendingIds.add(p.id));

      final success = await ApiService.deleteItem(p.id);

      if (!mounted) return;

      if (success) {
        setState(() {
          _products.removeWhere((e) => e.id == p.id);
          _pendingIds.remove(p.id);
        });
        _showSnack('Item berhasil dihapus');
      } else {
        setState(() => _pendingIds.remove(p.id));
        _showSnack('Gagal menghapus item', isError: true);
      }
      return;
    }

    final index = _indexOf(p.id);
    if (index == -1) return;

    final oldStock = p.stock;
    final oldPrice = p.price;

    setState(() {
      _pendingIds.add(p.id);
      _products[index] = p.copyWith(stock: oldStock - 1); // optimistic, stok saja
    });

    final result = await ApiService.updateItemStock(p.id, -1);

    if (!mounted) return;
    setState(() => _pendingIds.remove(p.id));

    if (result != null) {
      final newStock = int.tryParse(result['stok'].toString()) ?? oldStock - 1;
      final newPrice = double.tryParse(result['price'].toString())?.toInt() ?? oldPrice;

      final i = _indexOf(p.id);
      if (i != -1) {
        setState(() {
          _products[i] = _products[i].copyWith(stock: newStock, price: newPrice);
        });
      }
      _showSnack('Quantity berhasil dikurangi');
    } else {
      final i = _indexOf(p.id);
      if (i != -1) {
        setState(() => _products[i] = _products[i].copyWith(stock: oldStock, price: oldPrice));
      }
      _showSnack('Gagal mengurangi quantity', isError: true);
    }
  }

  String _formatRupiah(num value) {
    final str = value.toInt().toString();
    final chars = str.split('').reversed.toList();
    final result = <String>[];
    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(chars[i]);
    }
    return result.reversed.join();
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
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context, false),
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
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
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
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _filteredProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final p = _filteredProducts[index];
                          return _buildSlidableCard(p, color);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlidableCard(Product p, Color color) {
    final isPending = _pendingIds.contains(p.id);

    return Slidable(
      key: ValueKey(p.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.34,
        children: [
          Expanded(  
            child: Padding(
              padding: const EdgeInsets.only(left: 8, top: 2, bottom: 2),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _qtyButton(
                      Icons.remove_rounded,
                      AppColors.danger,
                      isPending ? null : () => _decreaseQty(p),
                    ),
                    _qtyButton(
                      Icons.add_rounded,
                      const Color(0xFF22C55E),
                      isPending ? null : () => _increaseQty(p),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      child: _productCard(p, color, isPending),
    );
  }

  Widget _productCard(Product p, Color color, bool isPending) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _openDetail(p),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.black.withOpacity(0.045)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(Icons.inventory_2_rounded, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0, 0.35),
                                end: Offset.zero,
                              ).animate(anim),
                              child: child,
                            ),
                          ),
                          child: Container(
                            key: ValueKey('${p.id}-${p.stock}'),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${p.stock} ${p.unit}',
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Text(
                              'Rp ${_formatRupiah(p.price)}',
                              key: ValueKey('${p.id}-price-${p.price}'),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isPending)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, Color color, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: onTap == null ? color.withOpacity(0.05) : color.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: onTap == null ? color.withOpacity(0.35) : color, size: 20),
      ),
    );
  }

  Widget _emptyState(Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: color.withOpacity(0.35)),
          const SizedBox(height: 12),
          const Text(
            'No product found',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}