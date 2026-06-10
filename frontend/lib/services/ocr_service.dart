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
    print('TAX       : ${parsed['tax']}');
    print('SERVICE   : ${parsed['service_charge']}');

    print('========== PARSED ITEMS ==========');
    for (final item in parsed['items']) {
      print(item);
    }

    print('========== WARNINGS ==========');
    for (final warning in parsed['warnings']) {
      print(warning);
    }

    return List<Map<String, dynamic>>.from(parsed['items']);
  }

  // =========================================================
  // MAIN PARSER
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
    final extraCharges = <Map<String, dynamic>>[];

    int? subtotal;
    int? total;
    int? paid;
    int? change;
    int? savings;
    int? tax;
    int? serviceCharge;

    String? pendingName;
    String? pendingCode;
    String? pendingSummaryKey;
    String? pendingExtraChargeKey;

    bool footerStarted = false;

    for (int i = 0; i < lines.length; i++) {
      final line = _normalizeText(lines[i]);
      final lower = line.toLowerCase();
      final keywordLower = _normalizeOcrKeyword(lower);

      if (line.length < 2) continue;

      // =====================================================
      // Summary value split into 2 lines:
      // Sub Totali
      // 442,000
      //
      // Total Bill :
      // 522,685
      // =====================================================
      if (pendingSummaryKey != null && _isOnlyPrice(line)) {
        final value = _parsePrice(line);

        if (pendingSummaryKey == 'subtotal') subtotal = value;

        if (pendingSummaryKey == 'total') {
          // Jangan override total yang sudah benar.
          total ??= value;
        }

        if (pendingSummaryKey == 'paid') paid = value;
        if (pendingSummaryKey == 'change') change = value;
        if (pendingSummaryKey == 'savings') savings = value;

        pendingSummaryKey = null;
        footerStarted = true;
        continue;
      }

      // =====================================================
      // Extra charge value split into 2 lines:
      // Serv. Charge 1.5X
      // 33,150
      //
      // Pajak 10% :
      // 47,515
      // =====================================================
      if (pendingExtraChargeKey != null && _isOnlyPrice(line)) {
        final value = _parsePrice(line);

        if (pendingExtraChargeKey == 'service') {
          serviceCharge = value;
          extraCharges.add({
            'label': 'Service Charge',
            'amount': value,
          });
        }

        if (pendingExtraChargeKey == 'tax') {
          tax = value;
          extraCharges.add({
            'label': 'Tax',
            'amount': value,
          });
        }

        pendingExtraChargeKey = null;
        footerStarted = true;
        continue;
      }

      // =====================================================
      // Summary same line:
      // KEMBALI : 25,140
      // Total Bill : 522,685
      // Grand Total : 822 665
      // =====================================================
      final summary = _parseSummaryLine(line);
      if (summary != null) {
        final key = summary['key'] as String;
        final value = summary['value'] as int;

        if (key == 'subtotal') subtotal = value;

        if (key == 'total') {
          final isGrandTotal = keywordLower.contains('grand total');

          // Kalau grand total muncul setelah Total Bill, jangan override.
          if (!isGrandTotal || total == null) {
            total = value;
          }
        }

        if (key == 'paid') paid = value;
        if (key == 'change') change = value;
        if (key == 'savings') savings = value;

        footerStarted = true;
        pendingName = null;
        pendingCode = null;
        pendingSummaryKey = null;
        pendingExtraChargeKey = null;
        continue;
      }

      // =====================================================
      // Extra charges same line:
      // Service Charge 11,150
      // Tax Resto 10% 23,415
      // =====================================================
      final extraCharge = _parseExtraChargeLine(line);
      if (extraCharge != null) {
        final key = extraCharge['key'] as String;
        final value = extraCharge['value'] as int;

        if (key == 'service') {
          serviceCharge = value;
          extraCharges.add({
            'label': 'Service Charge',
            'amount': value,
          });
        }

        if (key == 'tax') {
          tax = value;
          extraCharges.add({
            'label': 'Tax',
            'amount': value,
          });
        }

        footerStarted = true;
        pendingName = null;
        pendingCode = null;
        continue;
      }

      // =====================================================
      // Summary label only:
      // HARGA JUAL:
      // TOTAL:
      // Tota1
      // Sub Totali
      // =====================================================
      final summaryKeyOnly = _detectSummaryKeyOnly(line);
      if (summaryKeyOnly != null) {
        pendingSummaryKey = summaryKeyOnly;
        footerStarted = true;
        pendingName = null;
        pendingCode = null;
        continue;
      }

      // =====================================================
      // Extra charge label only:
      // Service Charge
      // Serv. Charge 1.5X
      // Tax Resto 10%
      // Pajak 10%
      // =====================================================
      final extraChargeKeyOnly = _detectExtraChargeKeyOnly(line);
      if (extraChargeKeyOnly != null) {
        pendingExtraChargeKey = extraChargeKeyOnly;
        footerStarted = true;
        pendingName = null;
        pendingCode = null;
        continue;
      }

      if (_isHardFooterStarter(keywordLower)) {
        footerStarted = true;
        pendingName = null;
        pendingCode = null;
        continue;
      }

      if (footerStarted) {
        continue;
      }

      // =====================================================
      // Discount / voucher line:
      // VC NUTRIJEL ... :(2,000)
      // Saving : -149,000
      // =====================================================
      if (_isDiscountLine(keywordLower)) {
        final discount = _parseDiscountLine(line);
        if (discount != null) {
          discounts.add(discount);
        }
        continue;
      }

      if (_shouldSkipLine(keywordLower)) {
        continue;
      }

      // =====================================================
      // Pending product + only price:
      // Restaurant:
      // 2 Hot Ocha
      // 58,000
      //
      // Here 58,000 is LINE TOTAL, not unit price.
      // So price = 58,000 / 2 = 29,000.
      // =====================================================
      if (pendingName != null && _isOnlyPrice(line)) {
        final lineTotal = _parsePrice(line);

        if (_isValidItemPrice(lineTotal)) {
          int qty = 1;
          String name = pendingName!;

          final qtyName = _extractLeadingQtyAndName(pendingName!);
          if (qtyName != null) {
            qty = qtyName['quantity'] as int;
            name = qtyName['name'] as String;
          }

          final unitPrice = qty > 1 ? (lineTotal / qty).round() : lineTotal;

          final item = _buildItem(
            name: name,
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
      }

      // =====================================================
      // Pattern A: numbered item
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
      // Pattern B: single line full item
      // NESTLE PURE LIFE 600 2 3600 7,200
      // LE MINERALE 600ML 2 3500 7,000
      // =====================================================
      final singleLine = _parseSingleLineItem(line);
      if (singleLine != null) {
        items.add(singleLine);
        pendingName = null;
        pendingCode = null;
        continue;
      }

      // =====================================================
      // Pattern C: qty + name + line total
      // 4 Nasi Putih 24.000
      // 2 Ayam Goreng 36.000
      // =====================================================
      final qtyNamePrice = _parseQtyNamePrice(line);
      if (qtyNamePrice != null) {
        items.add(qtyNamePrice);
        pendingName = null;
        pendingCode = null;
        continue;
      }

      // =====================================================
      // Pattern D: item name + price
      // POP MIE PD.DWR AYM75 5.400
      // KNZLER SNGL ES KJU 65 8,700
      // =====================================================
      final namePrice = _parseNamePrice(line);
      if (namePrice != null) {
        items.add(namePrice);
        pendingName = null;
        pendingCode = null;
        continue;
      }

      // =====================================================
      // Pattern E: compact detail after pending product
      // POP MIE AYAM 75G
      // 1 4900
      // 4,900
      // =====================================================
      final compactDetail = _parseCompactQtyUnitLine(line);
      if (compactDetail != null && pendingName != null) {
        final qty = compactDetail['quantity'] as int;
        final unitPrice = compactDetail['unit_price'] as int;

        int lineTotal = qty * unitPrice;

        if (i + 1 < lines.length) {
          final nextLine = _normalizeText(lines[i + 1]);
          if (_isOnlyPrice(nextLine)) {
            final nextPrice = _parsePrice(nextLine);
            if (_isValidItemPrice(nextPrice)) {
              lineTotal = nextPrice;
              i++;
            }
          }
        }

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
      // Pattern F: detail line after pending product
      // FINNA ULEG SAMBAL UDANG
      // 1,00 X @14.500 : 14.500
      //
      // MENTOS SAK FRUIT
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
      // Pattern G: product name only, wait for next price/detail.
      // 1 Beef Teriyaki Ramen
      // 1Onsen Egg Broccoli with To...
      // Salmon Sakura
      // 2 Hot Ocha
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

    int finalTotal;
    if (total != null) {
      finalTotal = total;
    } else if (subtotal != null && (serviceCharge != null || tax != null)) {
      finalTotal = subtotal + (serviceCharge ?? 0) + (tax ?? 0);
    } else {
      finalTotal = finalSubtotal;
    }

    return {
      'store_name': storeName,
      'date': date,
      'items': mergedItems,
      'subtotal': finalSubtotal,
      'total': finalTotal,
      'paid': paid,
      'change': change,
      'savings': savings,
      'tax': tax,
      'service_charge': serviceCharge,
      'discounts': discounts,
      'extra_charges': extraCharges,
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

    if (_shouldSkipLine(_normalizeOcrKeyword(clean.toLowerCase()))) return null;
    if (_parseQtyPriceDetail(clean) != null) return null;

    final tokens = clean.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (tokens.length < 4) return null;

    final numericIndexes = <int>[];

    for (int i = 0; i < tokens.length; i++) {
      final token = tokens[i];

      if (_looksLikeStandaloneNumber(token)) {
        numericIndexes.add(i);
      }
    }

    if (numericIndexes.length < 3) return null;

    final totalIndex = numericIndexes[numericIndexes.length - 1];
    final unitPriceIndex = numericIndexes[numericIndexes.length - 2];
    final qtyIndex = numericIndexes[numericIndexes.length - 3];

    if (totalIndex != tokens.length - 1) return null;

    final qty = int.tryParse(tokens[qtyIndex]) ?? 1;
    final unitPrice = _parsePrice(tokens[unitPriceIndex]);
    final lineTotal = _parsePrice(tokens[totalIndex]);

    if (!_isValidQty(qty)) return null;
    if (!_isValidItemPrice(unitPrice)) return null;
    if (!_isValidItemPrice(lineTotal)) return null;

    final expected = qty * unitPrice;
    final diff = (lineTotal - expected).abs();

    if (diff > 1000) return null;

    final nameTokens = tokens.sublist(0, qtyIndex);
    final name = _cleanName(nameTokens.join(' '));

    if (name.isEmpty) return null;
    if (!_looksLikeProductName(name)) return null;

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

    if (_parseQtyPriceDetail(clean) != null) return null;
    if (_parseCompactQtyUnitLine(clean) != null) return null;

    final match = RegExp(
      '^'
      r'(.+?)'
      r'\s+'
      '($pricePattern)'
      r'$',
      caseSensitive: false,
    ).firstMatch(clean);

    if (match == null) return null;

    final rawName = match.group(1)!;
    final price = _parsePrice(match.group(2)!);
    final name = _cleanName(rawName);

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

  static Map<String, dynamic>? _parseCompactQtyUnitLine(String line) {
    final clean = _normalizeText(line);
    final parts = clean.split(' ').where((e) => e.isNotEmpty).toList();

    if (parts.length != 2) return null;

    final qty = int.tryParse(parts[0]);
    final unitPrice = _parsePrice(parts[1]);

    if (qty == null) return null;
    if (!_isValidQty(qty)) return null;
    if (!_isValidItemPrice(unitPrice)) return null;

    return {
      'quantity': qty,
      'unit_price': unitPrice,
    };
  }

  static Map<String, dynamic>? _extractLeadingQtyAndName(String line) {
    final clean = _normalizeText(line);

    // Support:
    // 1 Beef Teriyaki Ramen
    // 2 Hot Ocha
    // 1Onsen Egg Broccoli with To...
    final match = RegExp(r'^(\d{1,3})\s*(.+)$').firstMatch(clean);

    if (match == null) return null;

    final qty = int.tryParse(match.group(1)!) ?? 1;
    final name = _cleanName(match.group(2)!);

    if (!_isValidQty(qty)) return null;
    if (name.isEmpty) return null;
    if (!_looksLikeProductName(name)) return null;

    return {
      'quantity': qty,
      'name': name,
    };
  }

  // =========================================================
  // SUMMARY / FOOTER PARSERS
  // =========================================================

  static Map<String, dynamic>? _parseSummaryLine(String line) {
    final lower = line.toLowerCase();
    final normalizedLower = _normalizeOcrKeyword(lower);
    final compact = normalizedLower.replaceAll(RegExp(r'[^a-z]'), '');

    final price = _lastPriceInLine(line);
    if (price == null || price < 0) return null;

    if (normalizedLower.contains('harga jual') ||
        normalizedLower.contains('subtotal') ||
        compact.contains('subtotal') ||
        compact.contains('subtotali')) {
      return {'key': 'subtotal', 'value': price};
    }

    if (_containsAny(normalizedLower, [
      'total bill',
      'total sales',
      'total sale',
      'total belanja',
      'total tagihan',
      'total bayar',
      'grand total',
    ])) {
      return {'key': 'total', 'value': price};
    }

    if ((compact == 'total' ||
        compact == 'totall' ||
        compact == 'tota' ||
        compact == 'totalbill') &&
        !normalizedLower.contains('saving') &&
        !normalizedLower.contains('hemat') &&
        !normalizedLower.contains('item') &&
        !normalizedLower.contains('qty')) {
      return {'key': 'total', 'value': price};
    }

    if (_isPaidKeywordLine(normalizedLower)) {
      return {'key': 'paid', 'value': price};
    }

    if (_containsAny(normalizedLower, [
      'kembali',
      'kembalian',
      'change',
    ])) {
      return {'key': 'change', 'value': price};
    }

    if (_containsAny(normalizedLower, [
      'anda hemat',
      'total saving',
      'saving',
      'hemat',
    ])) {
      return {'key': 'savings', 'value': price};
    }

    return null;
  }

  static String? _detectSummaryKeyOnly(String line) {
    final lower = line.toLowerCase();
    final normalizedLower = _normalizeOcrKeyword(lower);
    final compact = normalizedLower.replaceAll(RegExp(r'[^a-z]'), '');

    if (_lastPriceInLine(line) != null) return null;

    if (normalizedLower.contains('harga jual') ||
        normalizedLower.contains('subtotal') ||
        compact.contains('subtotal') ||
        compact.contains('subtotali')) {
      return 'subtotal';
    }

    if ((normalizedLower.contains('total bill') ||
        normalizedLower.contains('total bayar') ||
        normalizedLower.contains('total tagihan') ||
        compact == 'total' ||
        compact == 'totall' ||
        compact == 'tota' ||
        compact == 'totalbill') &&
        !normalizedLower.contains('saving') &&
        !normalizedLower.contains('hemat') &&
        !normalizedLower.contains('item') &&
        !normalizedLower.contains('qty')) {
      return 'total';
    }

    if (_isPaidKeywordLine(normalizedLower)) {
      return 'paid';
    }

    if (_containsAny(normalizedLower, [
      'kembali',
      'kembalian',
      'change',
    ])) {
      return 'change';
    }

    if (_containsAny(normalizedLower, [
      'anda hemat',
      'total saving',
      'saving',
      'hemat',
    ])) {
      return 'savings';
    }

    return null;
  }

  static Map<String, dynamic>? _parseExtraChargeLine(String line) {
    final lower = _normalizeOcrKeyword(line.toLowerCase());

    final price = _lastPriceInLine(line);
    if (price == null) return null;

    if (_containsAny(lower, [
      'service charge',
      'serv. charge',
      'serv charge',
      'service',
      'svc',
    ])) {
      return {'key': 'service', 'value': price};
    }

    if (_containsAny(lower, [
      'tax resto',
      'tax',
      'pajak',
      'ppn',
    ])) {
      return {'key': 'tax', 'value': price};
    }

    return null;
  }

  static String? _detectExtraChargeKeyOnly(String line) {
    final lower = _normalizeOcrKeyword(line.toLowerCase());

    if (_lastPriceInLine(line) != null) return null;

    if (_containsAny(lower, [
      'service charge',
      'serv. charge',
      'serv charge',
      'service',
      'svc',
    ])) {
      return 'service';
    }

    if (_containsAny(lower, [
      'tax resto',
      'tax',
      'pajak',
      'ppn',
    ])) {
      return 'tax';
    }

    return null;
  }

  static Map<String, dynamic>? _parseDiscountLine(String line) {
    final lower = _normalizeOcrKeyword(line.toLowerCase());

    if (!_isDiscountLine(lower)) return null;

    final price = _lastPriceInLine(line);
    if (price == null) return null;

    return {
      'label': _cleanName(
        line.replaceAll(RegExp(r'[\d.,()\-]+$'), ''),
      ),
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
    for (final line in lines.take(10)) {
      final lower = _normalizeOcrKeyword(line.toLowerCase());

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
      // 21.01.22-18:27
      // 31.10.24 [19:47]
      // Tanggal :0 14-11-21
      final dmy = RegExp(
        r'(\d{1,2})[./-](\d{1,2})[./-](\d{2,4})(?:\s*[-/]?\s*\[?(\d{1,2}:\d{2}(?::\d{2})?)\]?)?',
      ).firstMatch(line);

      if (dmy != null) {
        final day = dmy.group(1)!.padLeft(2, '0');
        final month = dmy.group(2)!.padLeft(2, '0');
        var year = dmy.group(3)!;
        final time = dmy.group(4);

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

      // Aug 19, 2024 6:32:54 PM
      final englishDate = RegExp(
        r'\b([A-Za-z]{3,9})\s+(\d{1,2}),\s*(\d{4})(?:\s+(\d{1,2}:\d{2}(?::\d{2})?)\s*(AM|PM)?)?',
        caseSensitive: false,
      ).firstMatch(line);

      if (englishDate != null) {
        final monthName = englishDate.group(1)!;
        final day = englishDate.group(2)!.padLeft(2, '0');
        final year = englishDate.group(3)!;
        final time = englishDate.group(4);
        final ampm = englishDate.group(5);

        final month = _monthNameToNumber(monthName);
        if (month == null) continue;

        if (time == null) {
          return '$year-${month.toString().padLeft(2, '0')}-$day';
        }

        final normalizedTime = _normalizeTime(time, ampm);
        return '$year-${month.toString().padLeft(2, '0')}-$day $normalizedTime';
      }
    }

    return null;
  }

  static int? _monthNameToNumber(String monthName) {
    final m = monthName.toLowerCase();

    if (m.startsWith('jan')) return 1;
    if (m.startsWith('feb')) return 2;
    if (m.startsWith('mar')) return 3;
    if (m.startsWith('apr')) return 4;
    if (m.startsWith('may')) return 5;
    if (m.startsWith('jun')) return 6;
    if (m.startsWith('jul')) return 7;
    if (m.startsWith('aug')) return 8;
    if (m.startsWith('sep')) return 9;
    if (m.startsWith('oct')) return 10;
    if (m.startsWith('nov')) return 11;
    if (m.startsWith('dec')) return 12;

    return null;
  }

  static String _normalizeTime(String time, String? ampm) {
    final parts = time.split(':');

    int hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts.length > 1 ? parts[1] : '00';
    final second = parts.length > 2 ? parts[2] : '00';

    final period = ampm?.toLowerCase();

    if (period == 'pm' && hour < 12) {
      hour += 12;
    }

    if (period == 'am' && hour == 12) {
      hour = 0;
    }

    return '${hour.toString().padLeft(2, '0')}:$minute:$second';
  }

  static bool _looksLikeProductName(String line) {
    final clean = _normalizeText(line);
    final lower = _normalizeOcrKeyword(clean.toLowerCase());

    if (clean.length < 3) return false;
    if (_shouldSkipLine(lower)) return false;
    if (_isDiscountLine(lower)) return false;
    if (_isHardFooterStarter(lower)) return false;
    if (_isOnlyPrice(clean)) return false;

    if (!RegExp(r'[a-zA-Z]').hasMatch(clean)) return false;

    final letterCount = RegExp(r'[a-zA-Z]').allMatches(clean).length;
    if (letterCount < 3) return false;

    if (_containsAny(lower, [
      'jl ',
      'jl.',
      'jalan',
      'raya',
      'rt.',
      'rw.',
      'kel ',
      'kec ',
      'kab ',
      'kota',
      'npwp',
      'telp',
      'tlp',
      'phone',
      'kasir',
      'cashier',
      'server',
      'pelayan',
      'trans',
      'receipt',
      'nota',
      'waktu',
      'tanggal',
      'jam :',
      'salinan pelanggan',
      'layanan konsumen',
      'customer service',
      'print cnt',
      'printed',
      'pos:',
      'pax:',
      'tbl ',
      'table',
      'no.meja',
      'jumlah tamu',
      'stru',
      'konm',
    ])) {
      return false;
    }

    return true;
  }

  static Map<String, String?> _extractCodeAndName(String line) {
    final clean = _normalizeText(line);

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

  static bool _isHardFooterStarter(String lower) {
    return _containsAny(lower, [
      'terima kasih',
      'terimakasih',
      'thank you',
      'please come again',
      'thank you for visit',
      'closed bill',
      'layanan konsumen',
      'customer service',
      'printed',
      'print(',
      'hanya untuk penagihan',
      'bukan bukti bayar',
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

  static bool _isPaidKeywordLine(String lower) {
    final text = lower.toLowerCase();

    if (text.contains('cashier')) return false;
    if (text.contains('kasir')) return false;

    return RegExp(r'\btunai\b').hasMatch(text) ||
        RegExp(r'\bcash\b').hasMatch(text) ||
        text.contains('non tunai') ||
        RegExp(r'\bdebit\b').hasMatch(text) ||
        RegExp(r'\bkredit\b').hasMatch(text) ||
        RegExp(r'\bdibayar\b').hasMatch(text) ||
        RegExp(r'\bbayar\b').hasMatch(text) ||
        text.contains('payment') ||
        text.contains('total payment');
  }

  static bool _shouldSkipLine(String lower) {
    return _containsAny(lower, [
      // header / POS
      'npwp',
      'kasir',
      'cashier',
      'server',
      'pelayan',
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
      'jam :',
      'print cnt',
      'printed',
      'closed',
      'salinan pelanggan',
      'pos:',
      'pax:',
      'tbl ',
      'table',
      'no.meja',
      'jumlah tamu',

      // address / store identity
      'jl.',
      'jl ',
      'jalan',
      'raya',
      'rt.',
      'rw.',
      'kel ',
      'kec ',
      'kab ',
      'kota',
      'telp',
      'tlp',
      'hp ',
      'wa ',
      'email',
      'ig :',
      'www',
      'ruko',
      'outlet',

      // summary / non item
      'subtotal',
      'sub total',
      'sub totali',
      'harga jual',
      'total item',
      'total qty',
      'tota1 item',
      'tota1 qty',
      'total bayar',
      'total tagihan',
      'total bill',
      'grand total',
      'tunai',
      'cash ',
      'debit',
      'kredit',
      'kembali',
      'change',
      'ppn',
      'dpp',
      'pajak',
      'tax',
      'service charge',
      'serv. charge',
      'layanan konsumen',
      'customer service',
      'terima kasih',
      'terimakasih',
      'thank you',
      'kunjungan',
      'closed bill',
      'anda hemat',
      'product discount',
      'total saving',
      'points',
      'approval',
      'cardid',
      'holder',
      'hanya untuk penagihan',
      'bukan bukti bayar',
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

      if (diff > 2000) {
        warnings.add(
          'Total receipt and item sum are different. This may be caused by tax, service charge, discount, voucher, or OCR error.',
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
        .replaceAll(']ease', 'lease')
        .replaceAll('Â', 'A')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _normalizeOcrKeyword(String text) {
    return text
        .toLowerCase()
        .replaceAll('0', 'o')
        .replaceAll('1', 'l')
        .replaceAll('i', 'l');
  }

  static String _cleanName(String raw) {
    var name = raw;

    name = name.replaceAll(RegExp(r'\brp\b', caseSensitive: false), '');

    name = name.replaceAll(RegExp(r'^\d+\.\s*'), '');
    name = name.replaceAll(RegExp(r'^\d{5,}\s+'), '');

    name = name.replaceAll(RegExp(r'\/PCS\b', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\/RCG\b', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\/PT\b', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\/PC\b', caseSensitive: false), '');

    name = name.replaceAll('(', ' ');
    name = name.replaceAll(')', ' ');

    name = name.replaceAll(RegExp(r'[^\w\s\-./&]'), ' ');

    name = name.replaceAll(RegExp(r'\bqty\b', caseSensitive: false), '');
    name = name.replaceAll(RegExp(r'\bitem\b', caseSensitive: false), '');

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
    return r'(?:Rp\s*)?[0-9OIlL]{1,3}(?:[.,\s]*[0-9OIlL]{3})+';
  }

  static bool _looksLikeStandaloneNumber(String token) {
    final clean = token
        .replaceAll('.', '')
        .replaceAll(',', '')
        .trim();

    if (!RegExp(r'^\d+$').hasMatch(clean)) return false;

    if (RegExp(r'[a-zA-Z]').hasMatch(token)) return false;

    return true;
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
      'ramen',
      'roll',
      'sushi',
      'salmon',
      'katsu',
      'teriyaki',
      'fried rice',
      'rice',
      'bao',
      'broccoli',
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
      'gery',
      'slai',
      'nabati',
      'finna',
      'o lai',
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
      'beef',
      'chicken',
      'fish',
      'meat',
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
      'black current',
      'blackcurrant',
      'bloody berry',
      'ocha',
      'sapporo',
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