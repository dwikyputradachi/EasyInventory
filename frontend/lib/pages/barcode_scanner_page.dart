  import 'package:flutter/material.dart';
  import 'package:mobile_scanner/mobile_scanner.dart';


  class BarcodeScannerPage extends StatefulWidget {
    const BarcodeScannerPage({super.key});

    @override
    State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
  }

  class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
    final MobileScannerController _controller = MobileScannerController();
    bool _isScanned = false;

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

    // Tambahin log di sini
    print('Scan result: $code');

    if (code == null || code.trim().isEmpty) return;

    setState(() {
      _isScanned = true;
    });

    _controller.stop();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      Navigator.pop(context, code.trim());
    });
  }


    void _resetScanner() {
      setState(() {
        _isScanned = false;
      });
      _controller.start();
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

            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: Container(
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
            ),
          ],
        ),
      );
    }
  }