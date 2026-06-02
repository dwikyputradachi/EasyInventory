import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final _picker = ImagePicker();

  static final _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  // =========================================================
  // PUBLIC SCAN METHODS
  // =========================================================

  static Future<List<Map<String, dynamic>>?> scanFromCamera() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (photo == null) return null;

    return _processImage(photo.path);
  }

  static Future<List<Map<String, dynamic>>?> scanFromGallery() async {
    final photo = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );

    if (photo == null) return null;

    return _processImage(photo.path);
  }

  static Future<List<Map<String, dynamic>>> _processImage(String path) async {
    final inputImage = InputImage.fromFile(File(path));
    final result = await _recognizer.processImage(inputImage);

    print('========== RAW OCR TEXT ==========');
    print(result.text);

    final lines = _extractLinesByPosition(result);

    print('========== OCR LINES ==========');
    for (final line in lines) {
      print(line);
    }

    final parsed = parseReceiptText(lines.join('\n'));

    print('========== PARSED RECEIPT ==========');
    print('STORE     : ${parsed['store_name']}');
    print('DATE      : ${parsed['date']}');
    print('SUBTOTAL  : ${parsed['subtotal']}');
    print('TOTAL     : ${parsed['total']}');
    print('PAID      : ${parsed['paid']}');
    print('CHANGE    : ${parsed['change']}');
    print('SAVINGS   : ${parsed['savings']}');

    print('========== PARSED ITEMS ==========');
    for (final item in parsed['items']) {
      print(item);
    }

    // ScanPage kamu kemungkinan masih butuh List<Map>.
    return List<Map<String, dynamic>>.from(parsed['items']);
  }

  // =========================================================
  // PUBLIC PARSER FOR TESTING
  // Bisa dipanggil manual:
  // final result = OcrService.parseReceiptText(rawText);
  // =========================================================

  static Map<String, dynamic> parseReceiptText(String rawText) {
    final lines = rawText
        .split('\n')
        .map(_normalizeText)
        .where((line) => line.trim().isNotEmpty)
        .toList();

    final storeName = _detectStoreName(lines);
    final date = _detectDate(lines);

    final items = <Map<String, dynamic>>[];
    final discounts = <Map<String, dynamic>>[];

    int? subtotal;
    int? total;
    int? paid;
    int? change;
    int? savings;

    String? pendingName;
    String? pendingCode;

    bool footerStarted = false;

    for (int i = 0; i < lines.length; i++) {
      final line = _normalizeText(lines[i]);
      final lower = line.toLowerCase();

      if (line.length < 2) continue;

      // Ambil summary/footer walau sudah footer.
      final summary = _parseSummaryLine(line);
      if (summary != null) {
        final key = summary['key'] as String;
        final value = summary['value'] as int;

        if (key == 'subtotal') subtotal = value;
        if (key == 'total') total = value;
        if (key == 'paid') paid = value;
        if (key == 'change') change = value;
        if (key == 'savings') savings = value;

        footerStarted = true;
        pendingName = null;
        pendingCode = null;
        continue;
      }

      if (_isFooterStarter(lower)) {
        footerStarted = true;
        pendingName = null;
        pendingCode = null;
        continue;
      }

      if (footerStarted) {
        continue;
      }

      if (_isDiscountLine(lower)) {
        final discount = _parseDiscountLine(line);
        if (discount != null) {
          discounts.add(discount);
        }
        continue;
      }

      if (_shouldSkipLine(lower)) {
        continue;
      }

      // =====================================================
      // Pattern 1: numbered item
      // Contoh:
      // 1. Vaseline Lip Rosy Lips x1 Rp36,900
      // =====================================================
      final numbered = _parseNumberedItem(line);
      if (numbered != null) {
        items.add(numbered);
        pendingName = null;
        pendingCode = null;
        continue;
      }

      // =====================================================
      // Pattern 2: single line item
      // Contoh:
      // PIATTOS SAPI PNG 68G 2 11200 22,400
      // POP MIE AYAM 75G 1 4900 4,900
      // =====================================================
      final singleLine = _parseSingleLineItem(line);
      if (singleLine != null) {
        items.add(singleLine);
        pendingName = null;
        pendingCode = null;
        continue;
      }

      // =====================================================
      // Pattern 3: qty name price
      // Contoh:
      // 4 Nasi Putih 24.000
      // 1 Jengkol Goreng Satuan 3.000
      // =====================================================
      final qtyNamePrice = _parseQtyNamePrice(line);
      if (qtyNamePrice != null) {
        items.add(qtyNamePrice);
        pendingName = null;
        pendingCode = null;
        continue;
      }

      // =====================================================
      // Pattern 4: name price
      // Contoh:
      // Beras 5 kg 60.000
      // Gula Pasir 15.000
      // =====================================================
      final namePrice = _parseNamePrice(line);
      if (namePrice != null) {
        items.add(namePrice);
        pendingName = null;
        pendingCode = null;
        continue;
      }

      // =====================================================
      // Pattern 5: detail line for previous item
      // Contoh:
      // FINNA ULEG SAMBAL UDANG 10'SX15G/10
      // 1,00 X @14.500 : 14.500
      //
      // 2041361 MENTOS SAK FRUIT /PCS
      // 1 x 6.400 = 6.400
      // =====================================================
      final detail = _parseQtyPriceDetail(line);

      if (detail != null && pendingName != null) {
        final qty = detail['quantity'] as int;
        final unitPrice = detail['unit_price'] as int;
        final lineTotal = detail['line_total'] as int;

        final item = _buildItem(
          name: pendingName,
          quantity: qty,
          unitPrice: unitPrice,
          lineTotal: lineTotal,
          code: pendingCode,
        );

        if (item != null) {
          items.add(item);
        }

        pendingName = null;
        pendingCode = null;
        continue;
      }

      // =====================================================
      // Pattern 6: product name line, wait for detail line next.
      // Contoh:
      // FINNA ULEG SAMBAL UDANG 10'SX15G/10
      // 10219819 CARPET PVC 216 LIGHT BROWN 120
      // =====================================================
      if (_looksLikeProductName(line)) {
        final codeAndName = _extractCodeAndName(line);

        pendingCode = codeAndName['code'];
        pendingName = codeAndName['name'];
        continue;
      }
    }

    final mergedItems = _mergeDuplicateItems(items);

    final sumItems = _sumItemTotals(mergedItems);
    final finalSubtotal = subtotal ?? sumItems;
    final finalTotal = total ?? subtotal ?? sumItems;

    return {
      'store_name': storeName,
      'date': date,
      'items': mergedItems,
      'subtotal': finalSubtotal,
      'total': finalTotal,
      'paid': paid,
      'change': change,
      'savings': savings,
      'discounts': discounts,
      'raw_lines': lines,
      'raw_text': rawText,
      'warnings': _buildWarnings(
        items: mergedItems,
        total: finalTotal,
        sumItems: sumItems,
      ),
    };
  }

  // =========================================================
  // OCR LINE EXTRACTION
  // =========================================================

  static List<String> _extractLinesByPosition(RecognizedText result) {
    final ocrLines = result.blocks
        .expand((block) => block.lines)
        .where((line) => line.text.trim().isNotEmpty)
        .toList();

    ocrLines.sort((a, b) {
      final ay = a.boundingBox.top;
      final by = b.boundingBox.top;

      if ((ay - by).abs() < 12) {
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }

      return ay.compareTo(by);
    });

    final rows = <List<TextLine>>[];

    for (final line in ocrLines) {
      final centerY = line.boundingBox.center.dy;

      final rowIndex = rows.indexWhere((row) {
        final rowCenterY = row.first.boundingBox.center.dy;
        return (rowCenterY - centerY).abs() < 8;
      });

      if (rowIndex == -1) {
        rows.add([line]);
      } else {
        rows[rowIndex].add(line);
      }
    }

    final resultLines = <String>[];

    for (final row in rows) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));

      final text = row.map((e) => e.text.trim()).join(' ');
      final normalized = _normalizeText(text);

      if (normalized.isNotEmpty) {
        resultLines.add(normalized);
      }
    }

    return resultLines;
  }

  // =========================================================
  // ITEM PARSERS
  // =========================================================

  static Map<String, dynamic>? _parseNumberedItem(String line) {
    final clean = _normalizeText(line);

    final match = RegExp(
      r'^\d+\.\s*(.+?)\s+x\s*(\d+)\s+(?:rp\s*)?([\d.,]+)$',
      caseSensitive: false,
    ).firstMatch(clean);

    if (match == null) return null;

    final name = _cleanName(match.group(1)!);
    final qty = int.tryParse(match.group(2)!) ?? 1;
    final price = _parsePrice(match.group(3)!);

    if (name.isEmpty || !_isValidItemPrice(price)) return null;

    final unitPrice = qty > 1 ? (price / qty).round() : price;

    return _buildItem(
      name: name,
      quantity: qty,
      unitPrice: unitPrice,
      lineTotal: price,
    );
  }

  static Map<String, dynamic>? _parseSingleLineItem(String line) {
    final clean = _normalizeText(line);

    // Nama + qty + harga satuan + total
    // PIATTOS SAPI PNG 68G 2 11200 22,400
    // NESTLE PURE LIFE 600 2 3600 7,200
    final match = RegExp(
      r'^(.+?\D)\s+(\d{1,3})\s+([\d.,]{3,})\s+([\d.,]{3,})$',
      caseSensitive: false,
    ).firstMatch(clean);

    if (match == null) return null;

    final name = _cleanName(match.group(1)!);
    final qty = int.tryParse(match.group(2)!) ?? 1;
    final unitPrice = _parsePrice(match.group(3)!);
    final lineTotal = _parsePrice(match.group(4)!);

    if (name.isEmpty) return null;
    if (!_isValidQty(qty)) return null;
    if (!_isValidItemPrice(unitPrice)) return null;
    if (!_isValidItemPrice(lineTotal)) return null;

    // Validasi ringan: total harus mendekati qty * unitPrice.
    // Kalau beda jauh, kemungkinan bukan item.
    final expected = qty * unitPrice;
    final diff = (lineTotal - expected).abs();

    if (qty > 1 && diff > 1000) {
      return null;
    }

    return _buildItem(
      name: name,
      quantity: qty,
      unitPrice: unitPrice,
      lineTotal: lineTotal,
    );
  }

  static Map<String, dynamic>? _parseQtyNamePrice(String line) {
    final clean = _normalizeText(line);
    final pricePattern = _priceLikePattern();

    // 4 Nasi Putih 24.000
    // 1 Jengkol Goreng Satuan 3.000
    final match = RegExp(
      '^'
      r'(\d{1,3})'
      r'\s+'
      r'(.+?)'
      r'\s+'
      '($pricePattern)'
      r'$',
      caseSensitive: false,
    ).firstMatch(clean);

    if (match == null) return null;

    final qty = int.tryParse(match.group(1)!) ?? 1;
    final name = _cleanName(match.group(2)!);
    final lineTotal = _parsePrice(match.group(3)!);

    if (name.isEmpty) return null;
    if (!_isValidQty(qty)) return null;
    if (!_isValidItemPrice(lineTotal)) return null;

    final unitPrice = qty > 1 ? (lineTotal / qty).round() : lineTotal;

    return _buildItem(
      name: name,
      quantity: qty,
      unitPrice: unitPrice,
      lineTotal: lineTotal,
    );
  }

  static Map<String, dynamic>? _parseNamePrice(String line) {
    final clean = _normalizeText(line);
    final pricePattern = _priceLikePattern();

    // Hindari line detail seperti:
    // 1 x 6400 = 6400
    if (_parseQtyPriceDetail(clean) != null) return null;

    final match = RegExp(
      '^'
      r'(.+?)'
      r'\s+'
      '($pricePattern)'
      r'$',
      caseSensitive: false,
    ).firstMatch(clean);

    if (match == null) return null;

    final name = _cleanName(match.group(1)!);
    final price = _parsePrice(match.group(2)!);

    if (name.isEmpty) return null;
    if (!_looksLikeProductName(name)) return null;
    if (!_isValidItemPrice(price)) return null;

    return _buildItem(
      name: name,
      quantity: 1,
      unitPrice: price,
      lineTotal: price,
    );
  }

  static Map<String, dynamic>? _parseQtyPriceDetail(String line) {
    final clean = _normalizeText(line);

    // 1,00 X @14.500 : 14.500
    // 1 x 6.400 = 6.400
    // 2 x 4.700 = 9.400
    final match = RegExp(
      r'^(\d+[.,]?\d*)\s*[xX]\s*@?\s*([\d.,]+)\s*[:=]?\s*([\d.,]+)?$',
      caseSensitive: false,
    ).firstMatch(clean);

    if (match == null) return null;

    final qtyRaw = match.group(1)!.replaceAll(',', '.');
    final qtyDouble = double.tryParse(qtyRaw) ?? 1;
    final qty = qtyDouble.round();

    final unitPrice = _parsePrice(match.group(2)!);
    final lineTotalRaw = match.group(3);
    final lineTotal = lineTotalRaw == null || lineTotalRaw.trim().isEmpty
        ? unitPrice * qty
        : _parsePrice(lineTotalRaw);

    if (!_isValidQty(qty)) return null;
    if (!_isValidItemPrice(unitPrice)) return null;
    if (!_isValidItemPrice(lineTotal)) return null;

    return {
      'quantity': qty,
      'unit_price': unitPrice,
      'line_total': lineTotal,
    };
  }

  // =========================================================
  // SUMMARY / FOOTER PARSERS
  // =========================================================

  static Map<String, dynamic>? _parseSummaryLine(String line) {
    final lower = line.toLowerCase();

    final price = _lastPriceInLine(line);
    if (price == null || price < 0) return null;

    if (lower.contains('subtotal') || lower.contains('harga jual')) {
      return {'key': 'subtotal', 'value': price};
    }

    if (_containsAny(lower, [
      'total sales',
      'total sale',
      'total belanja',
      'total tagihan',
      'total bayar',
    ])) {
      return {'key': 'total', 'value': price};
    }

    // Hati-hati: "Total saving" jangan dianggap total belanja.
    if (lower.contains('total') &&
        !lower.contains('saving') &&
        !lower.contains('hemat') &&
        !lower.contains('item') &&
        !lower.contains('qty')) {
      return {'key': 'total', 'value': price};
    }

    if (_containsAny(lower, [
      'tunai',
      'cash',
      'non tunai',
      'debit',
      'kredit',
      'dibayar',
      'bayar',
      'payment',
      'total payment',
    ])) {
      return {'key': 'paid', 'value': price};
    }

    if (_containsAny(lower, [
      'kembali',
      'kembalian',
      'change',
    ])) {
      return {'key': 'change', 'value': price};
    }

    if (_containsAny(lower, [
      'anda hemat',
      'total saving',
      'saving',
      'hemat',
    ])) {
      return {'key': 'savings', 'value': price};
    }

    return null;
  }

  static Map<String, dynamic>? _parseDiscountLine(String line) {
    final lower = line.toLowerCase();

    if (!_isDiscountLine(lower)) return null;

    final price = _lastPriceInLine(line);
    if (price == null) return null;

    return {
      'label': _cleanName(line.replaceAll(RegExp(r'[\d.,()\-]+$'), '')),
      'amount': price,
    };
  }

  static int? _lastPriceInLine(String line) {
    final pricePattern = _priceLikePattern();

    final matches = RegExp(
      pricePattern,
      caseSensitive: false,
    ).allMatches(line).toList();

    if (matches.isEmpty) return null;

    return _parsePrice(matches.last.group(0)!);
  }

  // =========================================================
  // DETECTION HELPERS
  // =========================================================

  static String? _detectStoreName(List<String> lines) {
    for (final line in lines.take(8)) {
      final lower = line.toLowerCase();

      if (_shouldSkipLine(lower)) continue;
      if (!RegExp(r'[a-zA-Z]').hasMatch(line)) continue;
      if (line.length < 3) continue;

      return _toTitleCase(
        line
            .replaceAll(RegExp(r'[_=~\-]+'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim(),
      );
    }

    return null;
  }

  static String? _detectDate(List<String> lines) {
    for (final line in lines) {
      // 31.10.24 [19:47]
      final dotDate = RegExp(
        r'(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})(?:\s*\[?(\d{1,2}:\d{2})\]?)?',
      ).firstMatch(line);

      if (dotDate != null) {
        final day = dotDate.group(1)!.padLeft(2, '0');
        final month = dotDate.group(2)!.padLeft(2, '0');
        var year = dotDate.group(3)!;
        final time = dotDate.group(4);

        if (year.length == 2) year = '20$year';

        return time == null ? '$year-$month-$day' : '$year-$month-$day $time';
      }

      // 2025/05/09 18:19:21
      final ymd = RegExp(
        r'(\d{4})[./-](\d{1,2})[./-](\d{1,2})(?:\s+(\d{1,2}:\d{2}(?::\d{2})?))?',
      ).firstMatch(line);

      if (ymd != null) {
        final year = ymd.group(1)!;
        final month = ymd.group(2)!.padLeft(2, '0');
        final day = ymd.group(3)!.padLeft(2, '0');
        final time = ymd.group(4);

        return time == null ? '$year-$month-$day' : '$year-$month-$day $time';
      }
    }

    return null;
  }

  static bool _looksLikeProductName(String line) {
    final clean = _normalizeText(line);
    final lower = clean.toLowerCase();

    if (clean.length < 3) return false;
    if (_shouldSkipLine(lower)) return false;
    if (_isDiscountLine(lower)) return false;
    if (_isFooterStarter(lower)) return false;
    if (_isOnlyPrice(clean)) return false;

    // Harus ada huruf.
    if (!RegExp(r'[a-zA-Z]').hasMatch(clean)) return false;

    final letterCount = RegExp(r'[a-zA-Z]').allMatches(clean).length;
    if (letterCount < 3) return false;

    // Hindari line alamat / header.
    if (_containsAny(lower, [
      'jl ',
      'jl.',
      'jalan',
      'rt.',
      'rw.',
      'kel ',
      'kec ',
      'kab ',
      'kota',
      'npwp',
      'telp',
      'phone',
      'kasir',
      'kassa',
      'trans',
      'receipt',
      'nota',
      'waktu',
      'salinan pelanggan',
      'layanan konsumen',
      'customer service',
    ])) {
      return false;
    }

    return true;
  }

  static Map<String, String?> _extractCodeAndName(String line) {
    final clean = _normalizeText(line);

    // Kode panjang di depan:
    // 2041361 MENTOS SAK FRUIT /PCS
    // 10219819 CARPET PVC...
    final match = RegExp(r'^(\d{5,})\s+(.+)$').firstMatch(clean);

    if (match != null) {
      return {
        'code': match.group(1),
        'name': _cleanName(match.group(2)!),
      };
    }

    return {
      'code': null,
      'name': _cleanName(clean),
    };
  }

  static bool _isFooterStarter(String lower) {
    return _containsAny(lower, [
      'subtotal',
      'harga jual',
      'total',
      'tunai',
      'cash',
      'non tunai',
      'debit',
      'kredit',
      'kembali',
      'change',
      'dpp',
      'ppn',
      'anda hemat',
      'total saving',
      'saving',
      'layanan konsumen',
      'customer service',
      'terima kasih',
      'terimakasih',
      'closed bill',
      'print',
    ]);
  }

  static bool _isDiscountLine(String lower) {
    return _containsAny(lower, [
      'vc ',
      'voucher',
      'discount',
      'diskon',
      'saving',
      'hemat',
      'potongan',
      'rounding',
    ]);
  }

  static bool _shouldSkipLine(String lower) {
    return _containsAny(lower, [
      // header
      'npwp',
      'kasir',
      'kassa',
      'trans',
      'receipt no',
      'receipt',
      'nota',
      'struk',
      'invoice',
      'waktu',
      'tanggal',
      'date',
      'time',
      'print',
      'closed',
      'salinan pelanggan',

      // alamat / identitas toko
      'jl.',
      'jl ',
      'jalan',
      'rt.',
      'rw.',
      'kel ',
      'kec ',
      'kab ',
      'kota',
      'telp',
      'hp ',
      'wa ',
      'email',
      'www',
      'ruko',
      'outlet',

      // footer / non item
      'subtotal',
      'harga jual',
      'total',
      'tunai',
      'cash',
      'debit',
      'kredit',
      'kembali',
      'change',
      'ppn',
      'dpp',
      'pajak',
      'tax',
      'layanan konsumen',
      'customer service',
      'terima kasih',
      'terimakasih',
      'kunjungan',
      'closed bill',
      'anda hemat',
      'product discount',
      'total saving',
      'points',
      'approval',
      'cardid',
      'holder',
    ]);
  }

  // =========================================================
  // ITEM BUILDING
  // =========================================================

  static Map<String, dynamic>? _buildItem({
    required String name,
    required int quantity,
    required int unitPrice,
    required int lineTotal,
    String? code,
  }) {
    final cleanName = _cleanName(name);

    if (cleanName.isEmpty) return null;
    if (!_isValidQty(quantity)) return null;
    if (!_isValidItemPrice(unitPrice)) return null;
    if (!_isValidItemPrice(lineTotal)) return null;

    final item = <String, dynamic>{
      'name': _toTitleCase(cleanName),
      'price': unitPrice,
      'quantity': quantity,
      'line_total': lineTotal,
      'category': _guessCategory(cleanName),
    };

    if (code != null && code.trim().isNotEmpty) {
      item['code'] = code;
    }

    return item;
  }

  static List<Map<String, dynamic>> _mergeDuplicateItems(
      List<Map<String, dynamic>> items,
      ) {
    final merged = <String, Map<String, dynamic>>{};

    for (final item in items) {
      final key = item['name'].toString().toLowerCase();

      if (!merged.containsKey(key)) {
        merged[key] = Map<String, dynamic>.from(item);
      } else {
        final oldQty = merged[key]!['quantity'] as int;
        final newQty = item['quantity'] as int;

        final oldTotal = merged[key]!['line_total'] as int;
        final newTotal = item['line_total'] as int;

        merged[key]!['quantity'] = oldQty + newQty;
        merged[key]!['line_total'] = oldTotal + newTotal;

        final totalQty = merged[key]!['quantity'] as int;
        if (totalQty > 0) {
          merged[key]!['price'] =
              ((merged[key]!['line_total'] as int) / totalQty).round();
        }
      }
    }

    return merged.values.toList();
  }

  static int _sumItemTotals(List<Map<String, dynamic>> items) {
    int total = 0;

    for (final item in items) {
      final lineTotal = item['line_total'];
      final price = item['price'];
      final qty = item['quantity'];

      if (lineTotal is int) {
        total += lineTotal;
      } else if (price is int && qty is int) {
        total += price * qty;
      }
    }

    return total;
  }

  static List<String> _buildWarnings({
    required List<Map<String, dynamic>> items,
    required int total,
    required int sumItems,
  }) {
    final warnings = <String>[];

    if (items.isEmpty) {
      warnings.add('No items detected. Try a clearer receipt photo.');
    }

    if (total > 0 && sumItems > 0) {
      final diff = (total - sumItems).abs();

      if (diff > 1000) {
        warnings.add(
          'Total receipt and item sum are different. This may be caused by discount, voucher, or OCR error.',
        );
      }
    }

    return warnings;
  }

  // =========================================================
  // NORMALIZATION
  // =========================================================

  static String _normalizeText(String text) {
    return text
        .replaceAll('|', ' ')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll('：', ':')
        .replaceAll('；', ':')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _cleanName(String raw) {
    var name = raw;

    name = name.replaceAll(RegExp(r'\brp\b', caseSensitive: false), '');

    // Buang nomor urut di depan.
    name = name.replaceAll(RegExp(r'^\d+\.\s*'), '');

    // Buang kode panjang di depan kalau masih nyangkut.
    name = name.replaceAll(RegExp(r'^\d{5,}\s+'), '');

    // Bersihkan unit teknis di akhir.
    name = name.replaceAll(RegExp(r'\/PCS\b', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\/RCG\b', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\/PT\b', caseSensitive: false), '');

    // Kurung tetap dipertahankan isinya.
    name = name.replaceAll('(', ' ');
    name = name.replaceAll(')', ' ');

    // Simpan huruf, angka, slash, dot, strip.
    name = name.replaceAll(RegExp(r'[^\w\s\-./&]'), ' ');

    // Buang kata non-item.
    name = name.replaceAll(RegExp(r'\bqty\b', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\bitem\b', caseSensitive: false), '');

    // Harga yang kadang nyangkut di nama.
    name = name.replaceAll(
      RegExp(r'\b(?:rp\s*)?[0-9]{1,3}(?:[.,]\d{3})+\b$', caseSensitive: false),
      '',
    );

    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (RegExp(r'^[0-9\s.,/]+$').hasMatch(name)) {
      return '';
    }

    if (name.length < 2) return '';

    return name;
  }

  static String _toTitleCase(String text) {
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;

      if (RegExp(r'\d').hasMatch(word)) {
        return word.toUpperCase();
      }

      if (word.length == 1) {
        return word.toUpperCase();
      }

      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  // =========================================================
  // PRICE HELPERS
  // =========================================================

  static String _priceLikePattern() {
    // Support:
    // Rp 60,000
    // 60,000
    // 60.000
    // 60 000
    // 24. 000
    // 36, 000
    // OCR salah baca: O/I/l/L sebagai 0/1.
    return r'(?:Rp\s*)?[0-9OIlL]{1,3}(?:[.,\s]*[0-9OIlL]{3})+';
  }

  static bool _isOnlyPrice(String line) {
    final cleaned = _normalizePriceText(line)
        .replaceAll(RegExp(r'rp', caseSensitive: false), '');

    return RegExp(r'^[0-9]{1,3}([.,]?[0-9]{3})+$').hasMatch(cleaned) ||
        RegExp(r'^[0-9]{3,}$').hasMatch(cleaned);
  }

  static int _parsePrice(String raw) {
    final cleaned = _normalizePriceText(raw)
        .replaceAll(RegExp(r'rp', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^\d]'), '');

    return int.tryParse(cleaned) ?? 0;
  }

  static String _normalizePriceText(String text) {
    return text
        .trim()
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('I', '1')
        .replaceAll('i', '1')
        .replaceAll('l', '1')
        .replaceAll('L', '1')
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(',.', ',')
        .replaceAll('.,', '.');
  }

  static bool _isValidItemPrice(int price) {
    if (price < 100) return false;
    if (price > 10000000) return false;
    return true;
  }

  static bool _isValidQty(int qty) {
    if (qty <= 0) return false;
    if (qty > 999) return false;
    return true;
  }

  // =========================================================
  // CATEGORY GUESSER
  // =========================================================

  static String _guessCategory(String name) {
    final lower = name.toLowerCase();

    if (_containsAny(lower, [
      'beras',
      'nasi',
      'mie',
      'mi ',
      'indomi',
      'indomie',
      'pop mie',
      'tepung',
      'gula',
      'garam',
      'minyak',
      'roti',
      'bread',
      'biskuit',
      'cookies',
      'wafer',
      'oreo',
      'chitato',
      'piattos',
      'pocky',
      'mentos',
      'sambal',
      'telur',
      'tempe',
      'lalapan',
      'jengkol',
      'bakso',
      'sosis',
      'kanzler',
      'knzler',
      'nutrijel',
      'nutrijell',
      'ger y',
      'gery',
      'slai',
      'nabati',
    ])) {
      return 'Pantry';
    }

    if (_containsAny(lower, [
      'ayam',
      'ikan',
      'daging',
      'sayur',
      'buah',
      'sate',
      'ati',
      'ampela',
      'goreng',
    ])) {
      return 'Fresh Food';
    }

    if (_containsAny(lower, [
      'teh',
      'kopi',
      'susu',
      'aqua',
      'air',
      'le minerale',
      'nestle pure life',
      'ultra',
      'milk',
      'juice',
      'latte',
      'minuman',
      'es teh',
      'javanna',
    ])) {
      return 'Beverages';
    }

    if (_containsAny(lower, [
      'sabun',
      'shampoo',
      'shampo',
      'sampo',
      'odol',
      'pasta gigi',
      'tissue',
      'tisu',
      'vaseline',
      'body spray',
      'feminine wash',
      'lip',
    ])) {
      return 'Toiletries';
    }

    if (_containsAny(lower, [
      'detergen',
      'rinso',
      'soklin',
      'sunlight',
      'pembersih',
      'karbol',
      'cleaner',
    ])) {
      return 'Cleaning Supplies';
    }

    if (_containsAny(lower, [
      'carpet',
      'karpet',
      'pvc',
      'pillow',
      'bantal',
      'slipper',
      'mat',
      'keset',
      'home',
    ])) {
      return 'Household Items';
    }

    return 'Others';
  }

  // =========================================================
  // GENERAL HELPERS
  // =========================================================

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }

  static void dispose() {
    _recognizer.close();
  }
}