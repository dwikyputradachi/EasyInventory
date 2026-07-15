import 'package:flutter/material.dart';
import '../constants/colors.dart';

/// Kartu ringkas untuk satu item ambigu di halaman review.
///
/// Didesain jauh lebih ramping dibanding kartu lama (yang menampilkan raw
/// text + reason + tombol besar sekaligus untuk SETIAP item) supaya daftar
/// "Item Perlu Konfirmasi" tidak terasa penuh/berantakan ketika jumlah
/// itemnya banyak.
///
/// - Tap kartu       -> buka editor lengkap (nama, harga, qty, kategori).
/// - Ikon centang    -> langsung tambahkan ke daftar belanja apa adanya.
/// - Ikon silang     -> abaikan item ini.
///
/// Detail (raw_text OCR asli & alasan) tidak dihapus — hanya dipindah jadi
/// subtitle satu baris (price kalau ada, atau reason kalau harga kosong),
/// dan tetap bisa dilihat lengkap lewat tap -> editor.
class CompactAmbiguousTile extends StatelessWidget {
  final Map<String, dynamic> parsed;
  final String rawText;
  final String reason;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onIgnore;

  const CompactAmbiguousTile({
    super.key,
    required this.parsed,
    required this.rawText,
    required this.reason,
    required this.onTap,
    required this.onAdd,
    required this.onIgnore,
  });

  String _formatRupiah(int v) =>
      v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.round();
    final t = v.toString().replaceAll(RegExp(r'[^0-9-]'), '');
    return (t.isEmpty || t == '-') ? fallback : (int.tryParse(t) ?? fallback);
  }

  @override
  Widget build(BuildContext context) {
    final name = (parsed['name'] ?? '').toString().trim().isNotEmpty
        ? (parsed['name'] as String).trim()
        : rawText;
    final price = _toInt(parsed['price']);
    final qty = _toInt(parsed['quantity'], fallback: 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.35)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name.isEmpty ? '(Tanpa nama)' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        price > 0 ? 'Rp ${_formatRupiah(price)}  x$qty' : reason,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 2),
                _iconAction(
                  icon: Icons.check_circle_outline,
                  color: AppColors.primary,
                  tooltip: 'Tambahkan',
                  onTap: onAdd,
                ),
                _iconAction(
                  icon: Icons.close_rounded,
                  color: AppColors.textSecondary,
                  tooltip: 'Abaikan',
                  onTap: onIgnore,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}