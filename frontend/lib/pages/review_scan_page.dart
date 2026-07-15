import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/receipt_service.dart';
import '../widgets/scan_item_tile.dart';
import '../widgets/scan_item_editor.dart';
import '../widgets/ambiguous_item_compact.dart';

/// Halaman review hasil OCR. Dipush setelah OCR selesai dari ScanPage.
///
/// Return value ke ScanPage:
/// - `true` jika berhasil disimpan ke inventaris
/// - `false` / `null` jika user hanya kembali tanpa menyimpan
class ReviewScanPage extends StatefulWidget {
  final Map<String, dynamic> receipt;

  const ReviewScanPage({super.key, required this.receipt});

  @override
  State<ReviewScanPage> createState() => _ReviewScanPageState();
}

class _ReviewScanPageState extends State<ReviewScanPage> {
  // Jumlah item ambigu yang ditampilkan sebelum disembunyikan di balik
  // tombol "Lihat item lainnya" — mencegah daftar terasa penuh/berantakan
  // saat hasil OCR menghasilkan banyak item yang perlu dikonfirmasi.
  static const int _ambiguousPreviewCount = 3;

  late List<Map<String, dynamic>> _scannedItems;
  late List<Map<String, dynamic>> _ambiguousItems;
  bool _isSaving = false;
  bool _showAllAmbiguous = false;

  @override
  void initState() {
    super.initState();
    _scannedItems = _asMapList(widget.receipt['items']);
    _ambiguousItems = _asMapList(widget.receipt['ambiguous_items']);
  }

  // ── Actions ──

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

  Future<void> _onSave() async {
    if (_isSaving) return;
    final itemsForSave = _itemsForSave();
    if (itemsForSave.isEmpty) return _snack('Belum ada item yang bisa disimpan.', error: true);

    if (!_isTotalMatched || _ambiguousItems.isNotEmpty) {
      final confirmed = await _confirmSaveWithWarnings();
      if (!confirmed) return;
    }

    setState(() => _isSaving = true);
    try {
      final res = await ReceiptService.saveReceipt(itemsForSave);
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (res['status'] == 'success') {
        _snack('Berhasil disimpan ke inventaris!');
        Navigator.pop(context, true);
      } else {
        _snack(res['message'] ?? 'Gagal menyimpan ke inventaris', error: true);
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
        content: const Text(
          'Beberapa item kemungkinan belum terbaca dengan benar, atau masih ada item yang perlu dikonfirmasi. Yakin ingin tetap menyimpan?',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Periksa Lagi')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tetap Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: error ? AppColors.danger : AppColors.primary),
    );
  }

  // ── Computed ──

  int get _totalHasilScan =>
      _scannedItems.fold(0, (s, i) => s + _toInt(i['price']) * _toInt(i['quantity'], fallback: 1));

  int? get _totalStrukOcr =>
      _toIntNullable(widget.receipt['ocr_detected_total']) ?? _toIntNullable(widget.receipt['total']);

  bool get _isTotalMatched {
    final ocrTotal = _totalStrukOcr;
    if (ocrTotal == null) return true;
    return (_totalHasilScan - ocrTotal).abs() <= 1000;
  }

  int? get _selisih {
    final ocrTotal = _totalStrukOcr;
    if (ocrTotal == null) return null;
    return _totalHasilScan - ocrTotal;
  }

  /// Entry item ambigu yang sedang ditampilkan. Dibatasi ke
  /// [_ambiguousPreviewCount] kecuali user menekan "Lihat item lainnya",
  /// supaya daftar tidak langsung memenuhi layar saat item ambigu banyak.
  List<MapEntry<int, Map<String, dynamic>>> get _visibleAmbiguousEntries {
    final entries = _ambiguousItems.asMap().entries.toList();
    if (_showAllAmbiguous || entries.length <= _ambiguousPreviewCount) return entries;
    return entries.take(_ambiguousPreviewCount).toList();
  }

  List<Map<String, dynamic>> _itemsForSave() {
    return _scannedItems.map((item) {
      final price = _toInt(item['price']);
      final qty = _toInt(item['quantity'], fallback: 1);
      final category = item['category']?.toString().trim() ?? 'Others';
      return {
        'name': item['name']?.toString().trim() ?? '',
        'price': price,
        'quantity': qty,
        'line_total': price * qty,
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
      'price': price,
      'quantity': qty,
      'line_total': price * qty,
      'category': kScanCategories.contains(category) ? category : 'Others',
    };
  }

  List<Map<String, dynamic>> _asMapList(dynamic v) =>
      v is! List ? [] : v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();

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

  String _formatRupiah(int v) => v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

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
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text('Hasil Scan Struk', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Periksa kembali hasil scan sebelum disimpan',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),

                  const Text('Ringkasan Scan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                  const SizedBox(height: 10),
                  _summaryCards(),
                  const SizedBox(height: 12),
                  _statusCard(),

                  if (_ambiguousItems.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text('Item Perlu Konfirmasi (${_ambiguousItems.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    const Text(
                      'Tap item untuk lengkapi. Gunakan ikon centang/silang untuk tambah/abaikan cepat.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    ..._visibleAmbiguousEntries.map((e) => CompactAmbiguousTile(
                          parsed: _itemFromAmbiguous(e.value),
                          rawText: e.value['raw_text']?.toString() ?? '',
                          reason: e.value['reason']?.toString() ?? 'Perlu dikonfirmasi sebelum disimpan.',
                          onTap: () => _editAmbiguous(e.key),
                          onAdd: () => _addAmbiguous(e.key),
                          onIgnore: () => _ignoreAmbiguous(e.key),
                        )),
                    if (_ambiguousItems.length > _ambiguousPreviewCount)
                      Center(
                        child: TextButton.icon(
                          onPressed: () => setState(() => _showAllAmbiguous = !_showAllAmbiguous),
                          icon: Icon(
                            _showAllAmbiguous ? Icons.expand_less : Icons.expand_more,
                            size: 18,
                          ),
                          label: Text(
                            _showAllAmbiguous
                                ? 'Sembunyikan sebagian'
                                : 'Lihat ${_ambiguousItems.length - _ambiguousPreviewCount} item lainnya',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                  ],

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Daftar Belanja (${_scannedItems.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                      TextButton.icon(
                        onPressed: _addManualItem,
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: const Text('Tambah', style: TextStyle(fontSize: 14)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Tap item untuk edit. Geser ke kiri untuk hapus.',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 12),

                  if (_scannedItems.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                      child: const Text(
                        'Belum ada item di daftar belanja. Tambahkan item manual atau konfirmasi item di atas.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    )
                  else
                    ..._scannedItems.asMap().entries.map((e) => ScanItemTile(
                      item: e.value,
                      onTap: () => _editItem(e.key),
                      onDelete: () => _deleteItem(e.key),
                    )),
                ],
              ),
            ),
          ),
          _bottomSaveBar(),
        ],
      ),
    );
  }

  Widget _summaryCards() {
    final ocrTotal = _totalStrukOcr;
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Text('TOTAL STRUK', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(
            ocrTotal != null ? 'Rp ${_formatRupiah(ocrTotal)}' : 'Tidak terbaca',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          const Text('TOTAL HASIL SCAN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white70, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text('Rp ${_formatRupiah(_totalHasilScan)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        ]),
      ),
    ]);
  }

  Widget _statusCard() {
    final ocrTotal = _totalStrukOcr;
    final matched = _isTotalMatched;
    final selisih = _selisih;

    if (ocrTotal == null) {
      return _statusBox(
        color: Colors.orange,
        icon: Icons.info_outline,
        text: 'Total struk tidak terbaca. Periksa daftar belanja sebelum menyimpan.',
      );
    }
    if (matched) {
      return _statusBox(
        color: AppColors.primary,
        icon: Icons.check_circle_outline,
        text: 'Cocok — total belanja sesuai dengan total struk.',
        bold: true,
      );
    }
    return _statusBox(
      color: AppColors.danger,
      icon: Icons.warning_amber_rounded,
      text: selisih != null ? 'Selisih Rp ${_formatRupiah(selisih.abs())}' : 'Total tidak cocok',
      subtext: 'Beberapa item mungkin belum terbaca dengan benar. Periksa daftar belanja sebelum menyimpan.',
      bold: true,
    );
  }

  Widget _statusBox({
    required Color color,
    required IconData icon,
    required String text,
    String? subtext,
    bool bold = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: color),
              ),
            ),
          ]),
          if (subtext != null) ...[
            const SizedBox(height: 6),
            Text(subtext, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          ],
        ],
      ),
    );
  }

  Widget _bottomSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: FilledButton(
            onPressed: _isSaving || _scannedItems.isEmpty ? null : _onSave,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.45),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _isSaving
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Simpan ke Inventaris', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}