import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  final ImagePicker _picker = ImagePicker();
  bool _isScanned = false;
  bool _isPickingFromGallery = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isScanned) return;

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final code = barcodes.first.rawValue;

    print('Scan result: $code');

    if (code == null || code.trim().isEmpty) return;

    _finishScan(code.trim());
  }

  void _finishScan(String code) {
    setState(() {
      _isScanned = true;
    });

    _controller.stop();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      Navigator.pop(context, code);
    });
  }

  void _resetScanner() {
    setState(() {
      _isScanned = false;
    });
    _controller.start();
  }

  Future<void> _pickFromGallery() async {
    if (_isScanned || _isPickingFromGallery) return;

    setState(() => _isPickingFromGallery = true);

    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);

      if (picked == null) {
        setState(() => _isPickingFromGallery = false);
        return;
      }

      // Hentikan kamera dulu sebelum analisa gambar dari galeri.
      await _controller.stop();

      final BarcodeCapture? capture = await _controller.analyzeImage(picked.path);

      if (!mounted) return;

      if (capture != null && capture.barcodes.isNotEmpty) {
        final code = capture.barcodes.first.rawValue;
        if (code != null && code.trim().isNotEmpty) {
          setState(() => _isPickingFromGallery = false);
          _finishScan(code.trim());
          return;
        }
      }

      // Tidak ditemukan barcode pada gambar.
      setState(() => _isPickingFromGallery = false);
      await _controller.start();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barcode tidak ditemukan pada gambar tersebut')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isPickingFromGallery = false);
      await _controller.start();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membaca gambar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetScanner,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          if (_isPickingFromGallery)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),

          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Arahkan kamera ke barcode produk',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isPickingFromGallery ? null : _pickFromGallery,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.65),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.white70),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_outlined, color: Colors.white),
                    label: const Text(
                      'Pilih dari Galeri',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}