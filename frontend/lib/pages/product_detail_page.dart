import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter/services.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Product product;

  final units = const ['pcs', 'kg', 'gram', 'liter', 'ml', 'botol', 'bungkus'];
  String _formatRupiah(String value) {
  final number = value.replaceAll(RegExp(r'[^0-9]'), '');

  if (number.isEmpty) return '';

  final chars = number.split('').reversed.toList();
  final result = <String>[];

  for (int i = 0; i < chars.length; i++) {
    if (i > 0 && i % 3 == 0) {
      result.add('.');
    }
    result.add(chars[i]);
  }

  return result.reversed.join();
}

int _parseRupiah(String value) {
  return int.tryParse(
        value.replaceAll('.', ''),
      ) ??
      0;
}
  @override
  void initState() {
    super.initState();
    product = widget.product;
  }

  void _deleteProduct() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Product?"),
        content: Text("${product.name} will be removed from inventory."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
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
    final qtyC = TextEditingController(text: product.stock.toString());
    final priceC = TextEditingController(
  text: _formatRupiah(product.price.toString()),
);
    final barcodeC = TextEditingController(text: product.barcode ?? '');

    String unit = product.unit;
    DateTime expiredDate = product.expiryDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, setModal) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: ListView(
              shrinkWrap: true,
              children: [
                const Text(
                  "Edit Product",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameC,
                  decoration: _input("Product Name"),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: qtyC,
                        keyboardType: TextInputType.number,
                        decoration: _input("Quantity"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: unit,
                        decoration: _input("Unit"),
                        items: units
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(u),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setModal(() => unit = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
  controller: priceC,
  keyboardType: TextInputType.number,
  inputFormatters: [
    FilteringTextInputFormatter.digitsOnly,
    TextInputFormatter.withFunction((oldValue, newValue) {
      final formatted = _formatRupiah(newValue.text);

      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(
          offset: formatted.length,
        ),
      );
    }),
  ],
  decoration: _input("Price"),
),
                const SizedBox(height: 12),
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
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "${expiredDate.day}/${expiredDate.month}/${expiredDate.year}",
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: barcodeC,
                  keyboardType: TextInputType.number,
                  decoration: _input("Barcode (optional)"),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () async {
                      final success = await ApiService.updateItem(
                        product.id,
                        {
                          'name': nameC.text.trim(),
                          'quantity':
                              int.tryParse(qtyC.text) ?? product.stock,
                    'price': _parseRupiah(priceC.text),
                          'unit': unit,
                          'barcode': barcodeC.text.trim(),
                          'expired_date':
                              expiredDate.toIso8601String().split('T').first,
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

await QuickAlert.show(
  context: context,
  type: QuickAlertType.success,
  title: 'Success',
  text: 'Product updated successfully.',
);

if (!mounted) return;

Navigator.pop(context, true);
                    },
                    child: const Text(
                      "Save Changes",
                      style: TextStyle(color: Colors.white),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.category,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const Divider(height: 30),
                _rowInfo("Stock", "${product.stock} ${product.unit}"),
            _rowInfo(
  "Price",
  "Rp ${_formatRupiah(product.price.toString())}",
),
                _rowInfo("Expired", expiredDate),
                if (product.barcode != null && product.barcode!.isNotEmpty)
                  _rowInfo("Barcode", product.barcode!),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _editProduct,
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              label: const Text(
                "Edit Product",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 85,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _input(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}