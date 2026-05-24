import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/product_model.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Product product;

  final units = const ['pcs', 'kg', 'gram', 'liter', 'ml', 'botol', 'bungkus'];

  @override
  void initState() {
    super.initState();
    product = widget.product;
  }

  int get daysLeft => product.expiryDate.difference(DateTime.now()).inDays;

  Color get statusColor {
    if (daysLeft < 0) return AppColors.danger;
    if (daysLeft <= 3) return AppColors.warning;
    return AppColors.primary;
  }

  String get statusText {
    if (daysLeft < 0) return "Expired";
    if (daysLeft == 0) return "Expires today";
    if (daysLeft <= 3) return "Expires in $daysLeft days";
    return "Still safe";
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
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, "deleted");
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _editProduct() {
    final nameC = TextEditingController(text: product.name);
    final qtyC = TextEditingController(text: product.quantity.toString());
    final priceC = TextEditingController(text: product.price.toString());
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
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                            ),
                          ),
                          child: child!,
                        );
                      },
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
                    onPressed: () {
                      final updated = product.copyWith(
                        name: nameC.text.trim(),
                        quantity: int.tryParse(qtyC.text) ?? product.quantity,
                        unit: unit,
                        price: int.tryParse(priceC.text) ?? product.price,
                        expiryDate: expiredDate,
                        barcode: barcodeC.text.trim().isEmpty
                            ? null
                            : barcodeC.text.trim(),
                      );

                      setState(() => product = updated);
                      Navigator.pop(context);
                      Navigator.pop(context, updated);
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
          _statusCard(),
          const SizedBox(height: 16),

          _infoTile(Icons.label_outline, "Name", product.name),
          _infoTile(Icons.category_outlined, "Category", product.category),
          _infoTile(
            Icons.inventory_2_outlined,
            "Stock",
            "${product.quantity} ${product.unit}",
          ),
          _infoTile(Icons.price_change_outlined, "Price", "Rp ${product.price}"),
          _infoTile(Icons.calendar_today_outlined, "Expired Date", expiredDate),

          if (product.barcode != null)
            _infoTile(Icons.qr_code_outlined, "Barcode", product.barcode!),

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

  Widget _statusCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: statusColor.withOpacity(0.15),
            child: Icon(Icons.access_time, color: statusColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoTile(IconData icon, String title, String value) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.10),
          child: Icon(icon, color: AppColors.primary),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
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