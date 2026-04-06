import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../data/app_data.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool _isScanning = false;
  bool _hasResult = false;

  // Dummy hasil OCR — nanti ganti dengan OCR engine asli
  final List<Map<String, dynamic>> _scannedItems = [
    {'name': 'Rice',      'price': 21500, 'category': 'Pantry'},
    {'name': 'Eggs',      'price': 25000, 'category': 'Pantry'},
    {'name': 'Drinks',    'price': 28000, 'category': 'Beverages'},
    {'name': 'Dish Soap', 'price': 15000, 'category': 'Toiletries'},
    {'name': 'Detergent', 'price': 17000, 'category': 'Toiletries'},
  ];

  void _onScan() {
    setState(() => _isScanning = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() { _isScanning = false; _hasResult = true; });
    });
  }

  void _onSave() {
    final items = _scannedItems.map((e) => InventoryItem(
      name: e['name'],
      category: e['category'],
      price: e['price'],
      scannedAt: DateTime.now(),
    )).toList();

    AppData().addItems(items);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Items saved to inventory!"),
        backgroundColor: AppColors.primary,
      ),
    );
    Navigator.pop(context);
  }

  int get _total => _scannedItems.fold(0, (s, i) => s + (i['price'] as int));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Scan Struk",
            style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Preview area
            Container(
              width: double.infinity,
              height: 220,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isScanning ? AppColors.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: _buildPreview(),
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isScanning ? null : _onScan,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: _isScanning
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.surface))
                    : const Icon(Icons.document_scanner_outlined, color: AppColors.surface),
                label: Text(
                  _isScanning ? "Scanning..." : "Auto Scan",
                  style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.surface),
                ),
              ),
            ),

            if (_hasResult) ...[
              const SizedBox(height: 24),
              const Text("Hasil Scan",
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                      fontSize: 15, color: AppColors.textPrimary)),
              const SizedBox(height: 10),
              ..._scannedItems.map((item) => _scannedTile(item)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total", style: TextStyle(fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  Text("Rp $_total", style: const TextStyle(fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Simpan ke Inventaris",
                      style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_isScanning) {
      return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircularProgressIndicator(color: AppColors.primary),
        SizedBox(height: 12),
        Text("Memproses struk...",
            style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
      ]);
    }
    if (_hasResult) {
      return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.check_circle_outline, color: AppColors.primary, size: 48),
        SizedBox(height: 8),
        Text("Scan berhasil!", style: TextStyle(fontFamily: 'Poppins',
            fontWeight: FontWeight.w600, color: AppColors.primary)),
      ]);
    }
    return const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textSecondary),
      SizedBox(height: 8),
      Text("Tekan Auto Scan untuk memindai struk",
          style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary, fontSize: 13),
          textAlign: TextAlign.center),
    ]);
  }

  Widget _scannedTile(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(item['category'],
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 10,
                      color: AppColors.primary, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 10),
            Text(item['name'], style: const TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ]),
          Text("Rp ${item['price']}", style: const TextStyle(fontFamily: 'Poppins',
              color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}