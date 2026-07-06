import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'scan_item_tile.dart';

class ScanReceiptSummary extends StatelessWidget {
  final String? store;
  final String? date;
  final int? subtotal;
  final int? total;
  final int itemTotal;
  final int discountTotal;
  final int? paid;
  final int? change;
  final bool isMatched;
  final int? diff;

  const ScanReceiptSummary({
    super.key,
    this.store, this.date, this.subtotal, this.total,
    required this.itemTotal, required this.discountTotal,
    this.paid, this.change, required this.isMatched, this.diff,
  });

  String _safe(String? t) => (t == null || t.trim().isEmpty || t.trim() == 'null') ? '-' : t.trim();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Ringkasan Struk', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 10),
        _line('Toko', _safe(store)),
        _line('Tanggal', _safe(date)),
        if (subtotal != null) _line('Subtotal OCR', 'Rp ${formatRupiah(subtotal!)}'),
        if (total != null) _line('Total Struk', 'Rp ${formatRupiah(total!)}'),
        _line('Total Item', 'Rp ${formatRupiah(itemTotal)}'),
        if (discountTotal > 0) _line('Diskon/Hemat', 'Rp ${formatRupiah(discountTotal)}'),
        if (paid != null && paid! > 0) _line('Bayar', 'Rp ${formatRupiah(paid!)}'),
        if (change != null && change! >= 0) _line('Kembali', 'Rp ${formatRupiah(change!)}'),
        if (!isMatched && diff != null) ...[
          const Divider(height: 18),
          _line('Selisih', 'Rp ${formatRupiah(diff!.abs())}', color: AppColors.danger),
        ],
      ]),
    );
  }

  Widget _line(String label, String value, {Color? color}) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const SizedBox(width: 14),
      Expanded(child: Text(value, textAlign: TextAlign.right,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? AppColors.textPrimary))),
    ]),
  );
}


class ScanWarningBox extends StatelessWidget {
  final List<String> warnings;
  const ScanWarningBox({super.key, required this.warnings});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.info_outline, size: 18, color: Colors.orange),
          SizedBox(width: 8),
          Text('Perlu Review', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ]),
        const SizedBox(height: 8),
        ...warnings.map((w) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text('• $w', style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
        )),
      ]),
    );
  }
}