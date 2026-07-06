import 'package:flutter/material.dart';
import '../constants/colors.dart';

String formatRupiah(int v) => v.toString()
    .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

/// Tile untuk item yang sudah terkonfirmasi (bisa di-swipe hapus, tap edit)
class ScanItemTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ScanItemTile({super.key, required this.item, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final name = item['name']?.toString() ?? '-';
    final category = item['category']?.toString() ?? 'Others';
    final price = (item['price'] as num?)?.toInt() ?? 0;
    final qty = (item['quantity'] as num?)?.toInt() ?? 1;
    final total = price * qty;

    return Dismissible(
      key: ValueKey('${name}_$price\_$qty'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                    child: Text(category, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500)),
                  ),
                  const SizedBox(width: 8),
                  Text('Qty: $qty', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ]),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('Rp ${formatRupiah(price)}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text('Total: Rp ${formatRupiah(total)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              const Icon(Icons.edit_outlined, size: 14, color: AppColors.textSecondary),
            ]),
          ]),
        ),
      ),
    );
  }
}

/// Tile untuk item ambigu (perlu konfirmasi: abaikan / edit / tambah)
class AmbiguousItemTile extends StatelessWidget {
  final Map<String, dynamic> parsed;
  final String rawText;
  final String reason;
  final VoidCallback onIgnore;
  final VoidCallback onEdit;
  final VoidCallback onAdd;

  const AmbiguousItemTile({
    super.key,
    required this.parsed,
    required this.rawText,
    required this.reason,
    required this.onIgnore,
    required this.onEdit,
    required this.onAdd,
  });

  // Data dianggap lengkap & aman ditambah langsung kalau harga & qty
  // sudah kebaca OCR dengan valid (bukan sekadar default 0/1).
  bool get _hasCompleteData {
    final price = parsed['price'];
    final qty = parsed['quantity'];
    return price is num && price > 0 && qty is num && qty > 0;
  }

  @override
  Widget build(BuildContext context) {
    final name = parsed['name']?.toString() ?? '-';
    final category = parsed['category']?.toString() ?? 'Others';
    final price = (parsed['price'] as num?)?.toInt() ?? 0;
    final qty = (parsed['quantity'] as num?)?.toInt() ?? 1;
    final complete = _hasCompleteData;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.45)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.help_outline, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(name.isEmpty ? 'Item OCR' : name,
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
        ]),
        const SizedBox(height: 6),

        // Kalau harga/qty belum kebaca, jangan tampilkan "Rp 0" yang menyesatkan.
        // Tampilkan status yang jujur supaya user tahu ini wajib dilengkapi.
        Row(children: [
          Icon(
            complete ? Icons.check_circle_outline : Icons.error_outline,
            size: 13,
            color: complete ? AppColors.primary : Colors.orange,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              complete
                  ? 'Qty $qty • Rp ${formatRupiah(price)} • $category'
                  : 'Harga/qty belum terbaca • lengkapi manual',
              style: TextStyle(
                fontSize: 12,
                fontWeight: complete ? FontWeight.normal : FontWeight.w600,
                color: complete ? AppColors.textPrimary : Colors.orange,
              ),
            ),
          ),
        ]),
        if (rawText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('Raw: $rawText', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
        const SizedBox(height: 4),
        Text(reason, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 10),

        Row(children: [
          Expanded(child: OutlinedButton(onPressed: onIgnore, child: const Text('Abaikan'))),
          const SizedBox(width: 8),

          // Kalau data belum lengkap: sembunyikan "Tambah" (mencegah item
          // masuk inventaris dengan harga Rp 0), jadikan tombol edit sebagai
          // aksi utama dengan label yang jelas.
          if (!complete)
            Expanded(
              flex: 2,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: onEdit,
                child: const Text('Lengkapi Data', style: TextStyle(color: Colors.white)),
              ),
            )
          else ...[
            Expanded(child: OutlinedButton(onPressed: onEdit, child: const Text('Edit'))),
            const SizedBox(width: 8),
            Expanded(child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: onAdd,
              child: const Text('Tambah', style: TextStyle(color: Colors.white)),
            )),
          ],
        ]),
      ]),
    );
  }
}