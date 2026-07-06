import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/colors.dart';

/// Key SharedPreferences untuk flag "jangan tampilkan lagi".
const String kHideScanTipsPrefKey = 'hide_scan_tips';

/// Tampilkan dialog tips hanya jika user belum pernah memilih
/// "Jangan tampilkan lagi" sebelumnya. Panggil ini di initState ScanPage.
Future<void> maybeShowTipsScanDialog(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final hide = prefs.getBool(kHideScanTipsPrefKey) ?? false;
  if (hide) return;
  if (!context.mounted) return;
  await showTipsScanDialog(context);
}

/// Paksa tampilkan dialog tips (misal dari tombol bantuan "?" di AppBar),
/// terlepas dari preferensi yang tersimpan.
Future<void> showTipsScanDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => const _TipsScanDialogContent(),
  );
}

class _TipItem {
  final IconData icon;
  final String text;
  final bool isWarning;
  const _TipItem(this.icon, this.text, {this.isWarning = false});
}

class _TipsScanDialogContent extends StatelessWidget {
  const _TipsScanDialogContent();

  static const _tips = [
    _TipItem(Icons.crop_free, 'Pastikan seluruh struk terlihat dalam foto'),
    _TipItem(Icons.center_focus_strong, 'Fokuskan kamera pada bagian daftar belanja (body struk)'),
    _TipItem(Icons.wb_sunny_outlined, 'Hindari foto yang buram atau terlalu gelap'),
    _TipItem(Icons.table_bar_outlined, 'Letakkan struk di permukaan datar'),
    _TipItem(
      Icons.info_outline,
      'Nama toko, alamat, promo, dan footer tidak terlalu penting. Fokus utama adalah daftar item dan harga.',
      isWarning: true,
    ),
  ];

  Future<void> _onMengerti(BuildContext context) async {
    Navigator.pop(context);
  }

  Future<void> _onJanganTampilkanLagi(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kHideScanTipsPrefKey, true);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long, color: AppColors.primary, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'Tips Scan Struk',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
            ]),
            const SizedBox(height: 18),
            ..._tips.map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (tip.isWarning ? Colors.orange : AppColors.primary).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      tip.icon,
                      size: 18,
                      color: tip.isWarning ? Colors.orange : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tip.text,
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.4),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _onMengerti(context),
                child: const Text(
                  'Mengerti',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _onJanganTampilkanLagi(context),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                child: const Text(
                  'Jangan tampilkan lagi',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}