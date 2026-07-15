import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'package:quickalert/quickalert.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Product product;

  final units = const ['pcs', 'kg', 'gram', 'liter', 'ml', 'botol', 'bungkus'];

  // NOTE (assumption): categories are loaded from ApiService.getCategories(),
  // expected to return a List of {'id_category': int, 'name_category': String}.
  List<Map<String, dynamic>> _categories = [];

  String _formatRupiah(String value) {
    final number = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (number.isEmpty) return '';

    final chars = number.split('').reversed.toList();
    final result = <String>[];

    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) result.add('.');
      result.add(chars[i]);
    }

    return result.reversed.join();
  }

  @override
  void initState() {
    super.initState();
    product = widget.product;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await ApiService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = List<Map<String, dynamic>>.from(cats);
      });
    } catch (e) {
      // Silent fail: edit sheet will just show "No Category" as the only
      // option if categories can't be loaded, rest of the page still works.
    }
  }

  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Product?"),
        content: Text("${product.name} will be removed from inventory."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final success = await ApiService.deleteItem(product.id);
              if (!mounted) return;

              if (!success) {
                Navigator.pop(context);
                QuickAlert.show(
                  context: context,
                  type: QuickAlertType.error,
                  title: 'Delete Failed',
                  text: 'Failed to delete product.',
                );
                return;
              }

              Navigator.pop(context);
              await QuickAlert.show(
                context: context,
                type: QuickAlertType.success,
                title: 'Deleted',
                text: 'Product deleted successfully.',
                confirmBtnText: 'OK',
              );

              if (!mounted) return;
              Navigator.pop(context, 'deleted');
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _editProduct() {
    final nameC = TextEditingController(text: product.name);
    final barcodeC = TextEditingController(text: product.barcode ?? '');

    String unit = product.unit;
    DateTime expiredDate = product.expiryDate;

    // Product model doesn't carry id_category (only the category name), so
    // we resolve the current category's id by matching product.category
    // against the loaded _categories list.
    int? selectedCategoryId;
    final matchedCategory = _categories.firstWhere(
      (c) =>
          (c['name_category']?.toString().toLowerCase() ?? '') ==
          product.category.toLowerCase(),
      orElse: () => const {},
    );
    if (matchedCategory.isNotEmpty) {
      selectedCategoryId = matchedCategory['id_category'] as int?;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) {
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  "Edit Product",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Update product details. Stock is managed from Category page.",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                _sectionLabel("Basic Info"),
                const SizedBox(height: 10),
                TextField(
                  controller: nameC,
                  decoration: _input("Product Name", icon: Icons.inventory_2_outlined),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int?>(
                  value: selectedCategoryId,
                  decoration: _input("Category", icon: Icons.category_outlined),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text("No Category"),
                    ),
                    ..._categories.map(
                      (c) => DropdownMenuItem<int?>(
                        value: c['id_category'] as int?,
                        child: Text(c['name_category']?.toString() ?? ''),
                      ),
                    ),
                  ],
                  onChanged: (v) => setModal(() => selectedCategoryId = v),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: unit,
                  decoration: _input("Unit", icon: Icons.straighten_outlined),
                  items: units
                      .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                      .toList(),
                  onChanged: (v) => setModal(() => unit = v!),
                ),

                const SizedBox(height: 24),
                _sectionLabel("Additional Details"),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: expiredDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (picked != null) {
                      setModal(() => expiredDate = picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Expired Date",
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "${expiredDate.day}/${expiredDate.month}/${expiredDate.year}",
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: barcodeC,
                  keyboardType: TextInputType.number,
                  decoration: _input(
                    "Barcode (optional)",
                    icon: Icons.qr_code_2_outlined,
                  ),
                ),

                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      // Stock & price stay untouched by the user — we still
                      // send the existing values because the update endpoint
                      // requires quantity and will overwrite price if it's
                      // not provided.
                      final success = await ApiService.updateItem(
                        product.id,
                        {
                          'name': nameC.text.trim(),
                          'quantity': product.stock,
                          'price': product.price,
                          'unit': unit,
                          'barcode': barcodeC.text.trim(),
                          'expired_date':
                              expiredDate.toIso8601String().split('T').first,
                          'id_category': selectedCategoryId,
                        },
                      );

                      if (!mounted) return;

                      if (!success) {
                        QuickAlert.show(
                          context: context,
                          type: QuickAlertType.error,
                          title: 'Update Failed',
                          text: 'Failed to update product.',
                        );
                        return;
                      }

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "${nameC.text.trim()} berhasil diperbarui!",
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );

                      if (!mounted) return;
                      Navigator.pop(context, true);
                    },
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      "Save Changes",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiredDate =
        "${product.expiryDate.day}/${product.expiryDate.month}/${product.expiryDate.year}";

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Product Detail",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _deleteProduct,
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header card — name & category
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    product.category,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Info card — read-only details
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionLabel("Inventory Info"),
                const SizedBox(height: 4),
                Text(
                  "Managed from Category page",
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 14),
                _rowInfo(
                  Icons.inventory_outlined,
                  "Stock",
                  "${product.stock} ${product.unit}",
                ),
                _rowInfo(
                  Icons.payments_outlined,
                  "Price",
                  "Rp ${_formatRupiah(product.price.toString())}",
                ),
                const Divider(height: 28),
                _sectionLabel("Product Details"),
                const SizedBox(height: 14),
                _rowInfo(Icons.event_outlined, "Expired", expiredDate),
                if (product.barcode != null && product.barcode!.isNotEmpty)
                  _rowInfo(
                    Icons.qr_code_2_outlined,
                    "Barcode",
                    product.barcode!,
                  ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: _editProduct,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text(
                "Edit Product",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _rowInfo(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}