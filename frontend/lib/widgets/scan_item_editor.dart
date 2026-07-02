import 'package:flutter/material.dart';
import '../constants/colors.dart';

const kScanCategories = [
  'Pantry', 'Fresh Food', 'Beverages', 'Toiletries',
  'Cleaning Supplies', 'Household Items', 'Others',
];

InputDecoration scanInputDeco(String hint) => InputDecoration(
  hintText: hint,
  hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
  filled: true, fillColor: AppColors.background,
  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
);

/// Bottom sheet untuk edit / tambah item (manual, hasil edit, atau dari ambiguous)
Future<void> showScanItemEditor({
  required BuildContext context,
  required Map<String, dynamic> initialItem,
  required String title,
  required String submitLabel,
  required void Function(Map<String, dynamic> item) onSubmit,
  required void Function(String msg) onError,
}) {
  final nameCtrl = TextEditingController(text: initialItem['name']?.toString() ?? '');
  final priceCtrl = TextEditingController(text: ((initialItem['price'] as num?)?.toInt() ?? 0).toString());
  final qtyCtrl = TextEditingController(text: ((initialItem['quantity'] as num?)?.toInt() ?? 1).toString());
  String category = initialItem['category']?.toString() ?? 'Others';
  if (!kScanCategories.contains(category)) category = 'Others';

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => Padding(
      padding: EdgeInsets.only(left: 18, right: 18, top: 18, bottom: MediaQuery.of(context).viewInsets.bottom + 18),
      child: StatefulBuilder(builder: (ctx, setSheet) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 14),
          TextField(controller: nameCtrl, style: const TextStyle(fontSize: 13), decoration: scanInputDeco('Nama barang')),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: TextField(controller: priceCtrl, keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13), decoration: scanInputDeco('Harga satuan'))),
            const SizedBox(width: 10),
            SizedBox(width: 90, child: TextField(controller: qtyCtrl, keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 13), decoration: scanInputDeco('Qty'))),
          ]),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: category,
            decoration: scanInputDeco('Kategori'),
            items: kScanCategories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => v != null ? setSheet(() => category = v) : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () {
                final name = nameCtrl.text.trim();
                final price = int.tryParse(priceCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
                final qty = int.tryParse(qtyCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));

                if (name.isEmpty) return onError('Nama barang tidak boleh kosong');
                if (price == null || price <= 0) return onError('Harga harus lebih dari 0');
                if (qty == null || qty <= 0) return onError('Qty harus lebih dari 0');

                onSubmit({'name': name, 'price': price, 'quantity': qty, 'line_total': price * qty, 'category': category});
                Navigator.pop(ctx);
              },
              child: Text(submitLabel, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      )),
    ),
  );
}