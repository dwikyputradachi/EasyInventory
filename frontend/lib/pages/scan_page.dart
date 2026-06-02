import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/ocr_service.dart';
import '../services/receipt_service.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isScanning = false;
  bool _isSaving = false;
  List<Map<String, dynamic>> _scannedItems = [];

  bool get _hasResult => _scannedItems.isNotEmpty;

  static const _categories = [
    'Pantry',
    'Fresh Food',
    'Beverages',
    'Toiletries',
    'Cleaning Supplies',
    'Household Items',
    'Others',
  ];

  Future<void> _onScanCamera() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      final items = await OcrService.scanFromCamera();

      if (!mounted) return;

      if (items == null) {
        setState(() => _isScanning = false);
        return;
      }

      setState(() {
        _scannedItems = items;
        _isScanning = false;
      });

      if (items.isEmpty) {
        _snack(
          'Tidak ada item terdeteksi. Coba foto struk lebih jelas.',
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isScanning = false);
      _snack('Gagal scan kamera: $e', error: true);
    }
  }

  Future<void> _onScanGallery() async {
    if (_isScanning) return;

    setState(() => _isScanning = true);

    try {
      final items = await OcrService.scanFromGallery();

      if (!mounted) return;

      if (items == null) {
        setState(() => _isScanning = false);
        return;
      }

      setState(() {
        _scannedItems = items;
        _isScanning = false;
      });

      if (items.isEmpty) {
        _snack(
          'Tidak ada item terdeteksi dari gambar tersebut.',
          error: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isScanning = false);
      _snack('Gagal scan dari galeri: $e', error: true);
    }
  }

  Future<void> _onSave() async {
    if (_scannedItems.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final res = await ReceiptService.saveReceipt(_scannedItems);

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

  void _deleteItem(int index) {
    setState(() {
      _scannedItems.removeAt(index);
    });
  }

  void _editItem(int index) {
    final item = _scannedItems[index];

    final nameCtrl = TextEditingController(text: item['name']?.toString() ?? '');
    final priceCtrl = TextEditingController(text: item['price'].toString());
    final qtyCtrl = TextEditingController(text: item['quantity'].toString());

    String category = item['category']?.toString() ?? 'Others';

    if (!_categories.contains(category)) {
      category = 'Others';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Item',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _field(nameCtrl, 'Nama barang'),
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          priceCtrl,
                          'Harga satuan',
                          keyboard: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 90,
                        child: _field(
                          qtyCtrl,
                          'Qty',
                          keyboard: TextInputType.number,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: _inputDeco('Kategori'),
                    items: _categories.map((c) {
                      return DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setSheet(() => category = v);
                    },
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        final name = nameCtrl.text.trim();
                        final price = int.tryParse(priceCtrl.text.trim());
                        final qty = int.tryParse(qtyCtrl.text.trim());

                        if (name.isEmpty) {
                          _snack('Nama barang tidak boleh kosong', error: true);
                          return;
                        }

                        setState(() {
                          _scannedItems[index] = {
                            'name': name,
                            'price': price ?? item['price'],
                            'quantity': qty ?? item['quantity'],
                            'category': category,
                          };
                        });

                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Simpan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.danger : AppColors.primary,
      ),
    );
  }

  int get _total {
    return _scannedItems.fold(0, (sum, item) {
      final price = item['price'];
      final quantity = item['quantity'];

      final itemPrice = price is int ? price : int.tryParse(price.toString()) ?? 0;
      final itemQty = quantity is int ? quantity : int.tryParse(quantity.toString()) ?? 1;

      return sum + (itemPrice * itemQty);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Scan Struk',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _previewBox(),

            const SizedBox(height: 16),

            _scanButtons(),

            if (_hasResult) ...[
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Hasil Scan (${_scannedItems.length} item)',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(
                    'Swipe kiri untuk hapus',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              const Text(
                'Tap item untuk edit nama, harga, qty, atau kategori',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 10),

              ..._scannedItems.asMap().entries.map(
                    (e) => _itemTile(e.key, e.value),
              ),

              const SizedBox(height: 12),

              _totalRow(),

              const SizedBox(height: 20),

              _saveButton(),

              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _previewBox() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isScanning ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: _buildPreview(),
    );
  }

  Widget _scanButtons() {
    if (_isScanning) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: null,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.7),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          ),
          label: const Text(
            'Memproses OCR...',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _onScanCamera,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
            ),
            label: Text(
              _hasResult ? 'Scan Ulang' : 'Kamera',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: OutlinedButton.icon(
            onPressed: _onScanGallery,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(
                color: AppColors.primary,
                width: 1.4,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.photo_library_outlined,
              color: AppColors.primary,
            ),
            label: const Text(
              'Galeri',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    if (_isScanning) {
      return const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: 12),
          Text(
            'Membaca struk...',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    if (_hasResult) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            color: AppColors.primary,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            '${_scannedItems.length} item terdeteksi',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Periksa dan edit sebelum disimpan',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 48,
          color: AppColors.textSecondary,
        ),
        SizedBox(height: 8),
        Text(
          'Pilih kamera atau galeri untuk membaca struk belanja',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _itemTile(int index, Map<String, dynamic> item) {
    final name = item['name']?.toString() ?? '-';
    final category = item['category']?.toString() ?? 'Others';

    final priceRaw = item['price'];
    final qtyRaw = item['quantity'];

    final price = priceRaw is int ? priceRaw : int.tryParse(priceRaw.toString()) ?? 0;
    final qty = qtyRaw is int ? qtyRaw : int.tryParse(qtyRaw.toString()) ?? 1;

    return Dismissible(
      key: ValueKey('$index-$name-$price-$qty'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteItem(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      child: GestureDetector(
        onTap: () => _editItem(index),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            category,
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        Text(
                          'Qty: $qty',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp ${_formatRupiah(price)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  if (qty > 1) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Total: Rp ${_formatRupiah(price * qty)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],

                  const SizedBox(height: 2),

                  const Icon(
                    Icons.edit_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Total',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          'Rp ${_formatRupiah(_total)}',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _saveButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isSaving ? null : _onSave,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white,
          ),
        )
            : const Text(
          'Simpan ke Inventaris',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _field(
      TextEditingController ctrl,
      String hint, {
        TextInputType keyboard = TextInputType.text,
      }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(
        fontSize: 13,
        color: AppColors.textPrimary,
      ),
      decoration: _inputDeco(hint),
    );
  }

  InputDecoration _inputDeco(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: AppColors.textSecondary,
      ),
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: AppColors.primary,
        ),
      ),
    );
  }

  String _formatRupiah(int v) {
    return v.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
    );
  }
}