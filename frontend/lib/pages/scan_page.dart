import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/ocr_service.dart';
import '../services/receipt_service.dart';
import '../widgets/scan_item_tile.dart';
import '../widgets/scan_item_editor.dart';
import '../widgets/scan_receipt_summary.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isScanning = false;
  bool _isSaving = false;

  List<Map<String, dynamic>> _scannedItems = [];
  List<Map<String, dynamic>> _ambiguousItems = [];
  Map<String, dynamic>? _receiptInfo;
  List<String> _ocrWarnings = [];

  bool get _hasResult => _scannedItems.isNotEmpty || _ambiguousItems.isNotEmpty || _receiptInfo != null;

  Future<void> _scan(Future<Map<String, dynamic>?> Function() source, String emptyMsg) async {
    if (_isScanning) return;
    setState(() => _isScanning = true);
    try {
      final receipt = await source();
      if (!mounted) return;
      if (receipt == null) { setState(() => _isScanning = false); return; }

      _applyReceiptResult(receipt);

      if (_scannedItems.isEmpty && _ambiguousItems.isEmpty) {
        _snack(emptyMsg, error: true);
      } else if (_reviewWarnings.isNotEmpty) {
        _snack('Hasil OCR perlu diperiksa sebelum disimpan.', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isScanning = false);
      _snack('Gagal scan: $e', error: true);
    }
  }

  void _onScanCamera() => _scan(OcrService.scanReceiptFromCamera, 'Tidak ada item terdeteksi. Coba foto struk lebih jelas.');
  void _onScanGallery() => _scan(OcrService.scanReceiptFromGallery, 'Tidak ada item terdeteksi dari gambar tersebut.');

  void _applyReceiptResult(Map<String, dynamic> receipt) {
    setState(() {
      _receiptInfo = receipt;
      _scannedItems = _asMapList(receipt['items']);
      _ambiguousItems = _asMapList(receipt['ambiguous_items']);
      _ocrWarnings = _asStringList(receipt['warnings']);
      _isScanning = false;
    });
  }

  Future<void> _onSave() async {
    if (_isSaving) return;
    final itemsForSave = _itemsForSave();
    if (itemsForSave.isEmpty) return _snack('Belum ada item yang bisa disimpan.', error: true);

    if (_reviewWarnings.isNotEmpty) {
      final confirmed = await _confirmSaveWithWarnings();
      if (!confirmed) return;
    }

    setState(() => _isSaving = true);
    try {
      final res = await ReceiptService.saveReceipt(itemsForSave);
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (res['status'] == 'success') {
        _snack('Receipt berhasil disimpan!');
        Navigator.pop(context);
      } else {
        _snack(res['message'] ?? 'Gagal menyimpan receipt', error: true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _snack('Terjadi error saat menyimpan: $e', error: true);
    }
  }

  Future<bool> _confirmSaveWithWarnings() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(child: Text('Periksa hasil scan', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Hasil OCR masih memiliki catatan berikut:', style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          const SizedBox(height: 10),
          ..._reviewWarnings.map((w) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('• ', style: TextStyle(color: AppColors.textPrimary)),
              Expanded(child: Text(w, style: const TextStyle(color: AppColors.textPrimary, fontSize: 12))),
            ]),
          )),
          const SizedBox(height: 8),
          const Text('Sebaiknya koreksi item terlebih dahulu sebelum menyimpan.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Review lagi')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tetap simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _deleteItem(int index) => setState(() => _scannedItems.removeAt(index));
  void _ignoreAmbiguous(int index) => setState(() => _ambiguousItems.removeAt(index));

  void _addAmbiguous(int index) {
    final newItem = _itemFromAmbiguous(_ambiguousItems[index]);
    setState(() {
      _scannedItems.add(newItem);
      _ambiguousItems.removeAt(index);
    });
  }

  void _editAmbiguous(int index) {
    showScanItemEditor(
      context: context,
      initialItem: _itemFromAmbiguous(_ambiguousItems[index]),
      title: 'Konfirmasi Item',
      submitLabel: 'Tambahkan Item',
      onError: (msg) => _snack(msg, error: true),
      onSubmit: (newItem) => setState(() {
        _scannedItems.add(newItem);
        _ambiguousItems.removeAt(index);
      }),
    );
  }

  void _editItem(int index) {
    showScanItemEditor(
      context: context,
      initialItem: _scannedItems[index],
      title: 'Edit Item',
      submitLabel: 'Simpan',
      onError: (msg) => _snack(msg, error: true),
      onSubmit: (newItem) => setState(() => _scannedItems[index] = {..._scannedItems[index], ...newItem}),
    );
  }

  void _addManualItem() {
    showScanItemEditor(
      context: context,
      initialItem: const {'name': '', 'price': 0, 'quantity': 1, 'category': 'Others'},
      title: 'Tambah Item Manual',
      submitLabel: 'Tambahkan',
      onError: (msg) => _snack(msg, error: true),
      onSubmit: (newItem) => setState(() => _scannedItems.add(newItem)),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? AppColors.danger : AppColors.primary),
    );
  }

  // ── Computed getters ──

  int get _total => _scannedItems.fold(0, (s, i) => s + _toInt(i['price']) * _toInt(i['quantity'], fallback: 1));

  int get _discountTotal {
    int total = _asMapList(_receiptInfo?['discounts'])
        .fold(0, (s, d) => s + _toInt(d['amount'] ?? d['value'] ?? d['price']));
    return total + _toInt(_receiptInfo?['savings']);
  }

  int? get _receiptTotal {
    final total = _toIntNullable(_receiptInfo?['total']);
    final subtotal = _toIntNullable(_receiptInfo?['subtotal']);
    if (total != null && total > 0) return total;
    if (subtotal != null && subtotal > 0) return subtotal;
    return null;
  }

  int? get _receiptSubtotal {
    final subtotal = _toIntNullable(_receiptInfo?['subtotal']);
    return (subtotal != null && subtotal > 0) ? subtotal : null;
  }

  bool get _isTotalMatched {
    final total = _receiptTotal, subtotal = _receiptSubtotal;
    if (total == null && subtotal == null) return true;
    if (total != null && _total == total) return true;
    if (subtotal != null && _total == subtotal) return true;
    if (total != null && _discountTotal > 0 && _total - _discountTotal == total) return true;
    return false;
  }

  int? get _totalDifference {
    final total = _receiptTotal;
    if (total == null) return null;
    return _discountTotal > 0 ? (_total - _discountTotal) - total : _total - total;
  }

  List<String> get _reviewWarnings {
    final warnings = <String>[];
    for (final w in _ocrWarnings) {
      final t = w.trim();
      if (t.isNotEmpty && !warnings.contains(t)) warnings.add(t);
    }
    if (_ambiguousItems.isNotEmpty) {
      warnings.add('${_ambiguousItems.length} item masih perlu dikonfirmasi. Tambahkan, edit, atau abaikan sebelum menyimpan.');
    }
    if (_receiptInfo != null && !_isTotalMatched) {
      final total = _receiptTotal, diff = _totalDifference;
      warnings.add(total == null
          ? 'Total struk tidak terbaca. Mohon periksa kembali item sebelum menyimpan.'
          : 'Total item belum sesuai dengan total struk. Mohon periksa, edit, atau tambahkan item sebelum menyimpan.${diff == null ? '' : ' Selisih: Rp ${formatRupiah(diff.abs())}.'}');
    }
    if (_scannedItems.isEmpty && _ambiguousItems.isNotEmpty) {
      warnings.add('Belum ada item terkonfirmasi. Pilih item ambigu yang benar atau tambah item manual.');
    }
    return warnings;
  }

  List<Map<String, dynamic>> _itemsForSave() {
    return _scannedItems.map((item) {
      final price = _toInt(item['price']);
      final qty = _toInt(item['quantity'], fallback: 1);
      final category = item['category']?.toString().trim() ?? 'Others';
      return {
        'name': item['name']?.toString().trim() ?? '',
        'price': price, 'quantity': qty, 'line_total': price * qty,
        'category': kScanCategories.contains(category) ? category : 'Others',
      };
    }).where((i) => i['name'].toString().isNotEmpty && (i['price'] as int) > 0 && (i['quantity'] as int) > 0).toList();
  }

  Map<String, dynamic> _itemFromAmbiguous(Map<String, dynamic> item) {
    final price = _toInt(item['suggested_price'] ?? item['price']);
    final qty = _toInt(item['suggested_quantity'] ?? item['quantity'], fallback: 1);
    final category = (item['suggested_category'] ?? item['category'] ?? 'Others').toString();
    return {
      'name': (item['suggested_name'] ?? item['name'] ?? item['raw_text'] ?? '').toString().trim(),
      'price': price, 'quantity': qty, 'line_total': price * qty,
      'category': kScanCategories.contains(category) ? category : 'Others',
    };
  }

  List<Map<String, dynamic>> _asMapList(dynamic v) =>
      v is! List ? [] : v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

  List<String> _asStringList(dynamic v) => v is! List ? [] : v.map((e) => e.toString()).toList();

  int _toInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is double) return v.round();
    final t = v.toString().replaceAll(RegExp(r'[^0-9-]'), '');
    return (t.isEmpty || t == '-') ? fallback : (int.tryParse(t) ?? fallback);
  }

  int? _toIntNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    final t = v.toString().replaceAll(RegExp(r'[^0-9-]'), '');
    return (t.isEmpty || t == '-') ? null : int.tryParse(t);
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18), onPressed: () => Navigator.pop(context)),
        title: const Text('Scan Struk', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _previewBox(),
          const SizedBox(height: 16),
          _scanButtons(),

          if (_hasResult) ...[
            const SizedBox(height: 20),
            ScanReceiptSummary(
              store: _receiptInfo?['store_name']?.toString(),
              date: _receiptInfo?['date']?.toString(),
              subtotal: _receiptSubtotal, total: _receiptTotal,
              itemTotal: _total, discountTotal: _discountTotal,
              paid: _toIntNullable(_receiptInfo?['paid']), change: _toIntNullable(_receiptInfo?['change']),
              isMatched: _isTotalMatched, diff: _totalDifference,
            ),

            if (_reviewWarnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              ScanWarningBox(warnings: _reviewWarnings),
            ],

            if (_ambiguousItems.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Perlu Konfirmasi (${_ambiguousItems.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Item berikut terbaca OCR, tetapi belum yakin. Tambahkan, edit, atau abaikan.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              ..._ambiguousItems.asMap().entries.map((e) => AmbiguousItemTile(
                parsed: _itemFromAmbiguous(e.value),
                rawText: e.value['raw_text']?.toString() ?? '',
                reason: e.value['reason']?.toString() ?? 'Format OCR perlu dikonfirmasi.',
                onIgnore: () => _ignoreAmbiguous(e.key),
                onEdit: () => _editAmbiguous(e.key),
                onAdd: () => _addAmbiguous(e.key),
              )),
            ],

            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Item Terkonfirmasi (${_scannedItems.length})', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              TextButton.icon(onPressed: _addManualItem, icon: const Icon(Icons.add_circle_outline, size: 18), label: const Text('Tambah')),
            ]),
            const SizedBox(height: 4),
            const Text('Tap item untuk edit. Swipe kiri untuk hapus.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 10),

            if (_scannedItems.isEmpty)
              Container(
                width: double.infinity, padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                child: const Text('Belum ada item terkonfirmasi. Tambahkan item manual atau konfirmasi item ambigu terlebih dahulu.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              )
            else
              ..._scannedItems.asMap().entries.map((e) => ScanItemTile(
                item: e.value, onTap: () => _editItem(e.key), onDelete: () => _deleteItem(e.key),
              )),

            const SizedBox(height: 12),
            _totalRow(),
            const SizedBox(height: 20),
            _saveButton(),
            const SizedBox(height: 24),
          ],
        ]),
      ),
    );
  }

  Widget _previewBox() => Container(
    width: double.infinity, height: 180,
    decoration: BoxDecoration(
      color: AppColors.surface, borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _isScanning ? AppColors.primary : Colors.transparent, width: 2),
    ),
    child: _buildPreview(),
  );

  Widget _scanButtons() {
    if (_isScanning) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: null,
          style: FilledButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.primary.withOpacity(0.7),
              padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          icon: const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          label: const Text('Memproses OCR...', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      );
    }
    return Row(children: [
      Expanded(child: FilledButton.icon(
        onPressed: _onScanCamera,
        style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        icon: const Icon(Icons.camera_alt_outlined, color: Colors.white),
        label: Text(_hasResult ? 'Scan Ulang' : 'Kamera', style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
      )),
      const SizedBox(width: 10),
      Expanded(child: OutlinedButton.icon(
        onPressed: _onScanGallery,
        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppColors.primary, width: 1.4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        icon: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
        label: const Text('Galeri', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
      )),
    ]);
  }

  Widget _buildPreview() {
    if (_isScanning) {
      return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: AppColors.primary),
        SizedBox(height: 12),
        Text('Membaca struk...', style: TextStyle(color: AppColors.textSecondary)),
      ]);
    }
    if (_hasResult) {
      final ok = _reviewWarnings.isEmpty;
      return Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(ok ? Icons.check_circle_outline : Icons.warning_amber_rounded, color: ok ? AppColors.primary : Colors.orange, size: 48),
        const SizedBox(height: 8),
        Text('${_scannedItems.length} item terkonfirmasi', style: TextStyle(fontWeight: FontWeight.w600, color: ok ? AppColors.primary : Colors.orange)),
        const SizedBox(height: 4),
        Text(_ambiguousItems.isEmpty ? 'Periksa dan edit sebelum disimpan' : '${_ambiguousItems.length} item perlu konfirmasi',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]);
    }
    return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondary),
      SizedBox(height: 8),
      Text('Pilih kamera atau galeri untuk membaca struk belanja', style: TextStyle(color: AppColors.textSecondary, fontSize: 13), textAlign: TextAlign.center),
    ]);
  }

  Widget _totalRow() {
    final total = _receiptTotal;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total Item', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text('Rp ${formatRupiah(_total)}', style: TextStyle(fontWeight: FontWeight.w700, color: _isTotalMatched ? AppColors.primary : AppColors.danger, fontSize: 16)),
        ]),
        if (total != null) ...[
          const SizedBox(height: 6),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Total Struk OCR', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            Text('Rp ${formatRupiah(total)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          ]),
        ],
      ]),
    );
  }

  Widget _saveButton() => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: _isSaving || _scannedItems.isEmpty ? null : _onSave,
      style: FilledButton.styleFrom(backgroundColor: AppColors.primary, disabledBackgroundColor: AppColors.primary.withOpacity(0.45),
          padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      child: _isSaving
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          : const Text('Simpan ke Inventaris', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
    ),
  );
  
}