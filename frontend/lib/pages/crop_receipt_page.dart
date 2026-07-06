import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../constants/colors.dart';

enum _HandlePos { topLeft, topRight, bottomLeft, bottomRight }

/// Halaman crop struk sebelum masuk ke OCR.
///
/// Return value:
/// - `File` (hasil crop) jika user menekan "Gunakan Foto Ini"
/// - `null` jika user menekan "Ulangi Foto" / back (batal)
class CropReceiptPage extends StatefulWidget {
  final File imageFile;
  const CropReceiptPage({super.key, required this.imageFile});

  @override
  State<CropReceiptPage> createState() => _CropReceiptPageState();
}

class _CropReceiptPageState extends State<CropReceiptPage> {
  ui.Image? _image;
  bool _processing = false;

  Rect _cropRect = Rect.zero;
  Size _lastDisplaySize = Size.zero;

  static const double _handleTouchSize = 44;
  static const double _minCropSize = 60;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.imageFile.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _image = frame.image);
  }

  void _ensureCropRect(Size displaySize) {
    if (_lastDisplaySize == displaySize && _cropRect != Rect.zero) return;
    _lastDisplaySize = displaySize;
    final insetX = displaySize.width * 0.06;
    final insetY = displaySize.height * 0.04;
    _cropRect = Rect.fromLTRB(
      insetX,
      insetY,
      displaySize.width - insetX,
      displaySize.height - insetY,
    );
  }

  void _dragHandle(_HandlePos handle, Offset delta) {
    setState(() {
      var r = _cropRect;
      switch (handle) {
        case _HandlePos.topLeft:
          r = Rect.fromLTRB(r.left + delta.dx, r.top + delta.dy, r.right, r.bottom);
          break;
        case _HandlePos.topRight:
          r = Rect.fromLTRB(r.left, r.top + delta.dy, r.right + delta.dx, r.bottom);
          break;
        case _HandlePos.bottomLeft:
          r = Rect.fromLTRB(r.left + delta.dx, r.top, r.right, r.bottom + delta.dy);
          break;
        case _HandlePos.bottomRight:
          r = Rect.fromLTRB(r.left, r.top, r.right + delta.dx, r.bottom + delta.dy);
          break;
      }

      final left = r.left.clamp(0.0, _lastDisplaySize.width - _minCropSize);
      final top = r.top.clamp(0.0, _lastDisplaySize.height - _minCropSize);
      final right = r.right.clamp(_minCropSize, _lastDisplaySize.width);
      final bottom = r.bottom.clamp(_minCropSize, _lastDisplaySize.height);

      if (right - left >= _minCropSize && bottom - top >= _minCropSize) {
        _cropRect = Rect.fromLTRB(left, top, right, bottom);
      }
    });
  }

  Future<void> _confirmCrop() async {
    final image = _image;
    if (image == null || _lastDisplaySize == Size.zero) return;

    setState(() => _processing = true);
    try {
      final scaleX = image.width / _lastDisplaySize.width;
      final scaleY = image.height / _lastDisplaySize.height;

      final srcRect = Rect.fromLTRB(
        (_cropRect.left * scaleX).clamp(0, image.width.toDouble()),
        (_cropRect.top * scaleY).clamp(0, image.height.toDouble()),
        (_cropRect.right * scaleX).clamp(0, image.width.toDouble()),
        (_cropRect.bottom * scaleY).clamp(0, image.height.toDouble()),
      );

      final outWidth = srcRect.width.round();
      final outHeight = srcRect.height.round();

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final dstRect = Rect.fromLTWH(0, 0, outWidth.toDouble(), outHeight.toDouble());
      canvas.drawImageRect(image, srcRect, dstRect, Paint());
      final picture = recorder.endRecording();
      final croppedImage = await picture.toImage(outWidth, outHeight);
      final byteData = await croppedImage.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) throw Exception('Gagal encode gambar hasil crop');

      final bytes = byteData.buffer.asUint8List();
      final outPath =
          '${widget.imageFile.parent.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.png';
      final outFile = await File(outPath).writeAsBytes(bytes);

      if (!mounted) return;
      Navigator.pop(context, outFile);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal crop foto: $e'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _retake() => Navigator.pop(context, null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Sesuaikan Area Struk', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _image == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'Geser sudut kotak agar pas dengan bagian daftar belanja pada struk',
              style: TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: _image!.width / _image!.height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final displaySize = Size(constraints.maxWidth, constraints.maxHeight);
                    _ensureCropRect(displaySize);
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: RawImage(image: _image, fit: BoxFit.fill),
                        ),
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CropMaskPainter(cropRect: _cropRect),
                          ),
                        ),
                        _buildHandle(_HandlePos.topLeft),
                        _buildHandle(_HandlePos.topRight),
                        _buildHandle(_HandlePos.bottomLeft),
                        _buildHandle(_HandlePos.bottomRight),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            color: Colors.black,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _processing ? null : _retake,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Colors.white54),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Ulangi Foto', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _processing ? null : _confirmCrop,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: _processing
                        ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : const Icon(Icons.check, color: Colors.white),
                    label: Text(
                      _processing ? 'Memproses...' : 'Gunakan Foto Ini',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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

  Widget _buildHandle(_HandlePos pos) {
    late double left;
    late double top;
    switch (pos) {
      case _HandlePos.topLeft:
        left = _cropRect.left;
        top = _cropRect.top;
        break;
      case _HandlePos.topRight:
        left = _cropRect.right;
        top = _cropRect.top;
        break;
      case _HandlePos.bottomLeft:
        left = _cropRect.left;
        top = _cropRect.bottom;
        break;
      case _HandlePos.bottomRight:
        left = _cropRect.right;
        top = _cropRect.bottom;
        break;
    }

    return Positioned(
      left: left - _handleTouchSize / 2,
      top: top - _handleTouchSize / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => _dragHandle(pos, details.delta),
        child: SizedBox(
          width: _handleTouchSize,
          height: _handleTouchSize,
          child: Center(
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 4)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CropMaskPainter extends CustomPainter {
  final Rect cropRect;
  _CropMaskPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final maskPath = Path.combine(
      PathOperation.difference,
      Path()..addRect(fullRect),
      Path()..addRect(cropRect),
    );
    canvas.drawPath(maskPath, Paint()..color = Colors.black.withOpacity(0.55));

    final borderPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropRect, borderPaint);

    // Garis bantu grid 3x3 ala rule-of-thirds
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 1;
    for (int i = 1; i < 3; i++) {
      final dx = cropRect.left + cropRect.width * i / 3;
      canvas.drawLine(Offset(dx, cropRect.top), Offset(dx, cropRect.bottom), gridPaint);
      final dy = cropRect.top + cropRect.height * i / 3;
      canvas.drawLine(Offset(cropRect.left, dy), Offset(cropRect.right, dy), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CropMaskPainter oldDelegate) => oldDelegate.cropRect != cropRect;
}