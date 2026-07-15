import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/ocr_service.dart';
import 'crop_receipt_page.dart';
import 'review_scan_page.dart';
import '../widgets/tips_scan_dialog.dart';
import '../services/groq_ocr_service.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

enum _PreviewState { idle, scanning, success, failed }

class _ScanPageState extends State<ScanPage> {
  _PreviewState _preview = _PreviewState.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) maybeShowTipsScanDialog(context);
    });
  }

  @override
  void dispose() {
    OcrService.dispose();
    super.dispose();
  }

  bool get _isBusy => _preview == _PreviewState.scanning;

  Future<void> _onScanCamera() => _startFlow(camera: true);
  Future<void> _onScanGallery() => _startFlow(camera: false);

  Future<void> _startFlow({required bool camera}) async {
  if (_isBusy) return;

  final File? picked = camera
      ? await OcrService.pickImageFromCamera()
      : await OcrService.pickImageFromGallery();

  if (picked == null || !mounted) return;

  final File? cropped = await Navigator.push<File?>(
    context,
    MaterialPageRoute(
      builder: (_) => CropReceiptPage(imageFile: picked),
    ),
  );

  if (cropped == null || !mounted) return;

  setState(() => _preview = _PreviewState.scanning);

  try {
    final receipt = await OcrService.scanReceiptFromFile(cropped);

    if (!mounted) return;

    if (receipt != null) {
      final rawItems =
          List<Map<String, dynamic>>.from(receipt['items'] ?? []);
      final originalAmbiguous =
          List<Map<String, dynamic>>.from(receipt['ambiguous_items'] ?? []);

      if (rawItems.isNotEmpty) {
        try {
          final enhanced = await GroqOcrService.enhanceItems(
            rawItems,
            ocrDetectedTotal: receipt['ocr_detected_total'] as int?,
          );

          receipt['items'] = enhanced.items;
          // Gabungkan item ambigu dari parser awal (OcrService) dengan yang
          // baru terdeteksi lewat validasi Groq, alih-alih menghapusnya
          // (rule #9: confidence rendah -> masuk ambiguous_items, bukan
          // dibuang begitu saja).
          receipt['ambiguous_items'] = [
            ...originalAmbiguous,
            ...enhanced.ambiguousItems,
          ];
        } catch (e) {
          print("Groq gagal, menggunakan hasil OCR asli.");
          print(e);

          receipt['items'] = rawItems;
          receipt['ambiguous_items'] = originalAmbiguous;
        }
      }
    }

    final items = List.from(receipt?['items'] ?? []);
    final ambiguous = List.from(receipt?['ambiguous_items'] ?? []);

    if (receipt == null || (items.isEmpty && ambiguous.isEmpty)) {
      setState(() => _preview = _PreviewState.failed);

      _snack(
        camera
            ? 'Tidak ada item terdeteksi. Coba foto struk lebih jelas.'
            : 'Tidak ada item terdeteksi dari gambar tersebut.',
        error: true,
      );

      return;
    }

    setState(() => _preview = _PreviewState.success);

    final saved = await Navigator.push<bool?>(
      context,
      MaterialPageRoute(
        builder: (_) => ReviewScanPage(receipt: receipt),
      ),
    );

    if (!mounted) return;

    if (saved == true) {
      Navigator.pop(context);
      return;
    }

    setState(() => _preview = _PreviewState.idle);
  } catch (e) {
    if (!mounted) return;

    setState(() => _preview = _PreviewState.failed);

    _snack(
      'Gagal scan: $e',
      error: true,
    );
  }
}

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? AppColors.danger : AppColors.primary),
    );
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan Struk', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppColors.textPrimary),
            tooltip: 'Tips Scan Struk',
            onPressed: () => showTipsScanDialog(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _previewBox(),
            const SizedBox(height: 20),
            _scanButtons(),
            const Spacer(),
            const Text(
              'Pastikan struk difoto dengan jelas agar hasil scan lebih akurat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewBox() => Container(
    width: double.infinity,
    height: 220,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _isBusy ? AppColors.primary : Colors.transparent, width: 2),
    ),
    child: _buildPreviewContent(),
  );

  Widget _buildPreviewContent() {
    switch (_preview) {
      case _PreviewState.scanning:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 14),
            Text('Membaca struk...', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
          ],
        );
      case _PreviewState.success:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 56),
            const SizedBox(height: 12),
            const Text('Scan berhasil', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Periksa hasil scan sebelum menyimpan', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        );
      case _PreviewState.failed:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: AppColors.danger, size: 56),
            const SizedBox(height: 12),
            const Text('Scan gagal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            const Text('Coba ambil foto ulang dengan pencahayaan lebih baik',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        );
      case _PreviewState.idle:
        return const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_outlined, size: 56, color: AppColors.textSecondary),
            SizedBox(height: 12),
            Text('Foto struk belanja Anda', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: AppColors.textPrimary)),
            SizedBox(height: 4),
            Text('Ambil foto atau pilih gambar dari galeri',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
          ],
        );
    }
  }

  Widget _scanButtons() {
    if (_isBusy) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.7),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          label: const Text('Memproses...', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
        ),
      );
    }
    return Row(children: [
      Expanded(
        child: FilledButton.icon(
          onPressed: _onScanCamera,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
          label: const Text('Kamera', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16)),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _onScanGallery,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            side: const BorderSide(color: AppColors.primary, width: 1.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          icon: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
          label: const Text('Galeri', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 16)),
        ),
      ),
    ]);
  }
}