import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final ImagePicker _picker = ImagePicker();

  static final TextRecognizer _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  static const String _version = 'STABLE-V12-VALIDATOR-PIPELINE';

  static Future<List<Map<String, dynamic>>?> scanFromCamera() async {
    final receipt = await scanReceiptFromCamera();
    if (receipt == null) return null;
    return List<Map<String, dynamic>>.from(receipt['items'] ?? []);
  }

  static Future<List<Map<String, dynamic>>?> scanFromGallery() async {
    final receipt = await scanReceiptFromGallery();
    if (receipt == null) return null;
    return List<Map<String, dynamic>>.from(receipt['items'] ?? []);
  }

  static Future<Map<String, dynamic>?> scanReceiptFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (picked == null) return null;
    return _processImage(File(picked.path));
  }
  static Future<File?> pickImageFromCamera() async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    return picked != null ? File(picked.path) : null;
  }
  static Future<File?> pickImageFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    return picked != null ? File(picked.path) : null;
  }
  static Future<Map<String, dynamic>?> scanReceiptFromFile(File file) async {
    return _processImage(file);
  }

  static Future<Map<String, dynamic>?> scanReceiptFromGallery() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
      maxHeight: 1600,
    );

    if (picked == null) return null;
    return _processImage(File(picked.path));
  }

  static Future<Map<String, dynamic>?> _processImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _recognizer.processImage(inputImage);

      final rawText = recognizedText.text;
      final ocrLines = _extractLinesByPosition(recognizedText);
      final parseInput = ocrLines.isNotEmpty ? ocrLines.join('\n') : rawText;

      print('========== OCR SERVICE VERSION: $_version ==========');
      print('========== RAW OCR TEXT ==========');
      print(rawText);
      print('========== OCR LINES ==========');
      for (final line in ocrLines) {
        print(line);
      }

      final parsed = parseReceiptText(parseInput);

      print('========== PARSED RECEIPT ==========');
      print('STORE            : ${parsed['store_name']}');
      print('DATE             : ${parsed['date']}');
      print('OCR TOTAL        : ${parsed['ocr_detected_total']}');
      print('CALCULATED TOTAL : ${parsed['calculated_total']}');
      print('DIFFERENCE       : ${parsed['difference']}');

      print('========== PARSED ITEMS ==========');
      for (final item in parsed['items']) {
        print(item);
      }

      print('========== AMBIGUOUS ITEMS ==========');
      for (final item in parsed['ambiguous_items']) {
        print(item);
      }

      print('========== WARNINGS ==========');
      for (final warning in parsed['warnings']) {
        print(warning);
      }

      return parsed;
    } catch (e) {
      print('OCR ERROR: $e');
      return null;
    }
  }

  static Map<String, dynamic> parseReceiptText(String rawText) {
    final lines = _normalizeLines(rawText);

    final storeName = _detectStoreName(lines);
    final date = _detectDate(lines);
    final zone = _detectReceiptZones(lines);

    final summary = _parseSummaryFromBottom(lines);
    final discounts = _parseDiscounts(lines);
    final items = _parseItemsFromZone(lines, zone['itemStart']!, zone['itemEnd']!);
    final mergedItems = _mergeDuplicateItems(items);

    var ambiguousItems = _collectAmbiguousItemsFromZone(
      lines,
      zone['itemStart']!,
      zone['itemEnd']!,
      mergedItems,
    );

    ambiguousItems = _mergeAmbiguousLists(
      ambiguousItems,
      findMissingItems(lines, zone['itemStart']!, zone['itemEnd']!, mergedItems, ambiguousItems),
    );

    final sumItems = _sumItemTotals(mergedItems);
    final savings = summary['savings'] ?? _sumDiscounts(discounts);

    int? subtotal = summary['subtotal'];

    final ocrDetectedTotal = summary['total'];

    int? total = summary['total'];
    subtotal ??= sumItems;
    final computedAfterDiscount = sumItems - (savings ?? 0);
    if (total == null || total <= 0) {
      total = computedAfterDiscount > 0 ? computedAfterDiscount : sumItems;
    } else if (sumItems > 0 && total < (sumItems * 0.5).round()) {
      total = computedAfterDiscount > 0 ? computedAfterDiscount : sumItems;
    }

    final calculatedTotal = sumItems;
    final int? difference = ocrDetectedTotal != null ? (calculatedTotal - ocrDetectedTotal) : null;

    final warnings = _buildWarnings(
      items: mergedItems,
      ambiguousItems: ambiguousItems,
      total: total,
      sumItems: sumItems,
      savings: savings,
    );

    return {
      'store_name': storeName,
      'date': date,
      'items': mergedItems,
      'ambiguous_items': ambiguousItems,
      'subtotal': subtotal,
      'total': total,
      'ocr_detected_total': ocrDetectedTotal,
      'calculated_total': calculatedTotal,
      'difference': difference,
      'paid': summary['paid'],
      'change': summary['change'],
      'savings': savings,
      'tax': summary['tax'],
      'service_charge': summary['service_charge'],
      'discounts': discounts,
      'extra_charges': <Map<String, dynamic>>[],
      'raw_lines': lines,
      'raw_text': rawText,
      'warnings': warnings,
    };
  }

  static List<Map<String, dynamic>> findMissingItems(
      List<String> lines,
      int itemStart,
      int itemEnd,
      List<Map<String, dynamic>> confirmedItems,
      List<Map<String, dynamic>> ambiguousItems,
      ) {
    final missing = <Map<String, dynamic>>[];

    final knownKeys = <String>{
      ...confirmedItems.map((e) => _nameKey(e['name']?.toString() ?? '')),
      ...ambiguousItems.map((e) => _nameKey(
        (e['suggested_name'] ?? '').toString(),
      )),
    };

    for (int i = itemStart; i < itemEnd; i++) {
      final line = _normalizeText(lines[i]);
      if (line.length < 3) continue;

      final lower = _normalizeKeyword(line);
      if (_isDiscountLine(lower)) continue;
      if (_isIgnoredMinimarketCharge(lower)) continue;
      if (_isDefinitelyNotItemLine(line)) continue;
      if (!_looksLikeLooseProductName(line)) continue;

      final cleaned = _cleanName(line);
      final key = _nameKey(cleaned);
      if (key.isEmpty || knownKeys.contains(key)) continue;

      missing.add({
        'raw_text': line,
        'suggested_name': _toTitleCase(_normalizeProductNameSmart(cleaned)),
        'suggested_price': null,
        'suggested_quantity': 1,
        'suggested_line_total': null,
        'suggested_category': null,
        'code': null,
        'reason': 'Baris ini terlihat seperti nama produk tapi harga/qty tidak berhasil terbaca. Mohon lengkapi manual.',
        'confidence': 0.40,
      });

      knownKeys.add(key);
    }

    return missing;
  }

  static List<Map<String, dynamic>> _mergeAmbiguousLists(
      List<Map<String, dynamic>> a,
      List<Map<String, dynamic>> b,
      ) {
    final result = List<Map<String, dynamic>>.from(a);
    final existingKeys = a.map((e) => _nameKey((e['suggested_name'] ?? '').toString())).toSet();

    for (final item in b) {
      final key = _nameKey((item['suggested_name'] ?? '').toString());
      if (existingKeys.contains(key)) continue;
      result.add(item);
      existingKeys.add(key);
    }

    return result;
  }

  static List<String> _extractLinesByPosition(RecognizedText result) {
    final textLines = result.blocks
        .expand((block) => block.lines)
        .where((line) => line.text.trim().isNotEmpty)
        .toList();

    textLines.sort((a, b) {
      final ay = a.boundingBox.top;
      final by = b.boundingBox.top;
      if ((ay - by).abs() < 12) {
        return a.boundingBox.left.compareTo(b.boundingBox.left);
      }
      return ay.compareTo(by);
    });

    final rows = <List<TextLine>>[];

    for (final line in textLines) {
      final centerY = line.boundingBox.center.dy;
      final index = rows.indexWhere((row) {
        final rowCenterY = row.first.boundingBox.center.dy;
        return (rowCenterY - centerY).abs() < 8;
      });

      if (index == -1) {
        rows.add([line]);
      } else {
        rows[index].add(line);
      }
    }

    final resultLines = <String>[];
    for (final row in rows) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      final text = row.map((e) => e.text.trim()).join(' ');
      final normalized = _normalizeText(text);
      if (normalized.isNotEmpty) resultLines.add(normalized);
    }

    return resultLines;
  }

  static List<String> _normalizeLines(String rawText) {
    return rawText
        .split('\n')
        .map(_normalizeText)
        .where((line) => line.trim().isNotEmpty)
        .toList();
  }

  static String _normalizeText(String text) {
    return text
        .replaceAll('\u00a0', ' ')
        .replaceAll('|', 'I')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _normalizeKeyword(String text) {
    var result = text
        .toLowerCase()
        .replaceAll('!', 'i')
        .replaceAll('|', 'i')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    result = _correctCommonTypos(result);
    return result;
  }
  static String _correctCommonTypos(String lower) {
    var text = lower;
    text = text.replaceAll('tota1', 'total');
    text = text.replaceAll('totai', 'total');
    text = text.replaceAll('totol', 'total');
    text = text.replaceAll('tunal', 'tunai');
    text = text.replaceAll('tunar', 'tunai');
    text = text.replaceAll('pajax', 'pajak');
    text = text.replaceAll('kenball', 'kembali');
    return text;
  }

  static String? _detectStoreName(List<String> lines) {
    for (final line in lines.take(14)) {
      final lower = _normalizeKeyword(line);

      if (lower.contains('alfamrt') || lower.contains('alfamart')) {
        if (lower.contains('tiban')) return 'Alfamart Tiban III';
        return 'Alfamart';
      }

      if (lower.contains('super mart tiban')) return 'Super Mart Tiban';
      if (lower.contains('tlogomas')) return _toTitleCase(_removePhoneNumber(line));
      if (lower.contains('breadtalk')) return 'BreadTalk';
      if (lower.contains('karis jaya')) return 'Karis Jaya Shop';
      if (lower.contains('fres gajan mada') || lower.contains('fresh gajah mada')) {
        return 'Fresh Gajah Mada Mas';
      }
      if (lower.contains('indomaret') && !lower.contains('@')) return 'Indomaret';
    }

    for (final line in lines.take(12)) {
      final lower = _normalizeKeyword(line);
      if (_isBadStoreLine(lower)) continue;
      if (!RegExp(r'[a-zA-Z]').hasMatch(line)) continue;
      return _toTitleCase(_removePhoneNumber(_cleanName(line)));
    }

    return 'Unknown Store';
  }

  static bool _isBadStoreLine(String lower) {
    return _containsAny(lower, [
      'jalan', 'jln ', 'jl ', 'rt.', 'rw.', 'blok', 'kec', 'kota',
      'npw', 'npp', 'npwp', 'pt.', 'bon ', 'kasir', 'tgl', 'receipt', 'telp',
    ]);
  }

  static String _removePhoneNumber(String text) {
    return text.replaceAll(RegExp(r'\b0\d{8,}\b'), '').trim();
  }

  static String? _detectDate(List<String> lines) {
    for (final line in lines) {
      final lower = _normalizeKeyword(line);
      if (_containsAny(lower, ['npwp', 'npp', 'npw'])) continue;

      final dmyDash = RegExp(
        r'\b(\d{1,2})[-/](\d{1,2})[-/](\d{2,4})\s+(\d{1,2}:\d{2}(?::\d{2})?)',
      ).firstMatch(line);
      if (dmyDash != null) {
        return _formatDateTime(dmyDash.group(3)!, dmyDash.group(2)!, dmyDash.group(1)!, dmyDash.group(4)!);
      }

      final dmyDot = RegExp(
        r'\b(\d{1,2})[.](\d{1,2})[.](\d{2,4})[-\s]+(\d{1,2}:\d{2}(?::\d{2})?)',
      ).firstMatch(line);
      if (dmyDot != null) {
        return _formatDateTime(dmyDot.group(3)!, dmyDot.group(2)!, dmyDot.group(1)!, dmyDot.group(4)!);
      }

      final dMonY = RegExp(
        r'\b(\d{1,2})[-\s]([A-Za-z]{3,})[-\s](\d{2,4})\s+(\d{1,2}:\d{2}[.:]?\d{0,2})',
        caseSensitive: false,
      ).firstMatch(line);
      if (dMonY != null) {
        final month = _monthToNumber(dMonY.group(2)!);
        if (month != null) {
          return _formatDateTime(dMonY.group(3)!, month.toString(), dMonY.group(1)!, dMonY.group(4)!.replaceAll('.', ':'));
        }
      }

      final ymd = RegExp(
        r'\b(20\d{2})[-/](\d{1,2})[-/](\d{1,2})(?:\s+(\d{1,2}:\d{2}(?::\d{2})?))?',
      ).firstMatch(line);
      if (ymd != null) {
        return _formatDateTime(ymd.group(1)!, ymd.group(2)!, ymd.group(3)!, ymd.group(4) ?? '00:00');
      }
    }

    return null;
  }

  static String _formatDateTime(String yearRaw, String monthRaw, String dayRaw, String timeRaw) {
    var year = int.tryParse(yearRaw) ?? 0;
    final month = int.tryParse(monthRaw) ?? 1;
    final day = int.tryParse(dayRaw) ?? 1;

    if (year < 100) year += 2000;

    var time = timeRaw.trim().replaceAll('.', ':');
    if (RegExp(r'^\d{1,2}:\d{2}$').hasMatch(time)) time = '$time:00';

    final y = year.toString().padLeft(4, '0');
    final m = month.toString().padLeft(2, '0');
    final d = day.toString().padLeft(2, '0');
    return '$y-$m-$d $time';
  }

  static int? _monthToNumber(String raw) {
    final m = raw.toLowerCase();
    const months = {
      'jan': 1, 'january': 1, 'feb': 2, 'february': 2, 'mar': 3, 'march': 3,
      'apr': 4, 'april': 4, 'may': 5, 'mei': 5, 'jun': 6, 'june': 6,
      'jul': 7, 'july': 7, 'aug': 8, 'agu': 8, 'agustus': 8, 'sep': 9,
      'sept': 9, 'oct': 10, 'okt': 10, 'nov': 11, 'dec': 12, 'des': 12,
    };
    return months[m];
  }

  static Map<String, int> _detectReceiptZones(List<String> lines) {
    int itemStart = -1;
    int itemEnd = lines.length;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lower = _normalizeKeyword(line);

      if (itemStart == -1 && _isTransactionStartMarker(line, lower)) {
        itemStart = i + 1;
      }
    }

    if (itemStart == -1 || itemStart >= lines.length) {
      for (int i = 0; i < lines.length; i++) {
        if (_looksLikeItemRow(lines[i]) || _looksLikeLooseProductName(lines[i])) {
          itemStart = i;
          break;
        }
      }
    }

    if (itemStart == -1) itemStart = 0;

    for (int i = itemStart; i < lines.length; i++) {
      final lower = _normalizeKeyword(lines[i]);
      if (_isFooterStart(lower)) {
        itemEnd = i;
        break;
      }
    }

    return {'itemStart': itemStart, 'itemEnd': itemEnd};
  }

  static bool _isTransactionStartMarker(String line, String lower) {
    if (lower.startsWith('bon ') || lower.contains(' bon ')) return true;
    if (lower.startsWith('tgl') || lower.startsWith('igl')) return true;
    if (RegExp(r'\b\d{1,2}[.]\d{1,2}[.]\d{2,4}[-\s]+\d{1,2}:\d{2}').hasMatch(line)) return true;
    if (RegExp(r'\b\d{1,2}[-/]\d{1,2}[-/]\d{2,4}\s+\d{1,2}:\d{2}').hasMatch(line)) return true;
    if (RegExp(r'\b\d{1,2}[-\s][A-Za-z]{3,}[-\s]\d{2,4}\s+\d{1,2}:\d{2}').hasMatch(line)) return true;
    return false;
  }

  static bool _isFooterStart(String lower) {
    if (lower.contains('total iten') || lower.contains('total item')) return true;
    if (lower.contains('total belanja')) return true;
    if (lower.startsWith('total ') || lower == 'total :' || lower == 'total') return true;
    if (lower.contains('harga jual')) return true;
    if (lower.startsWith('tunai') || lower.startsWith('cash')) return true;
    if (lower.startsWith('kembali') || lower.startsWith('kenbal') || lower.startsWith('kembal')) return true;
    if (lower.contains('layanan konsumen')) return true;
    if (lower.contains('kritik') || lower.contains('saran')) return true;
    if (lower.contains('sms') && lower.contains('wa')) return true;
    if (lower.contains('terima kasih')) return true;
    if (lower.contains('thank you')) return true;
    if (RegExp(r'^\d+\s*item\b').hasMatch(lower)) return true;
    if (lower.contains('jumlah')) return true;

    return false;
  }

  static List<Map<String, dynamic>> _parseItemsFromZone(
      List<String> lines,
      int itemStart,
      int itemEnd,
      ) {
    final items = <Map<String, dynamic>>[];
    String? pendingName;
    String? pendingCode;

    for (int i = itemStart; i < itemEnd; i++) {
      final line = _normalizeText(lines[i]);
      final lower = _normalizeKeyword(line);

      if (line.length < 2) continue;

      if (_isDiscountLine(lower)) {
        pendingName = null;
        pendingCode = null;
        continue;
      }

      if (_isIgnoredMinimarketCharge(lower)) {
        pendingName = null;
        pendingCode = null;
        continue;
      }

      if (_isDefinitelyNotItemLine(line) && pendingName == null) {
        pendingName = null;
        pendingCode = null;
        continue;
      }

      final barcodeDetail = _parseBarcodeDetailLine(line);
      if (barcodeDetail != null) {
        if (pendingName != null) {
          final item = _buildItem(
            name: pendingName,
            quantity: barcodeDetail['quantity'] as int,
            unitPrice: barcodeDetail['unit_price'] as int,
            lineTotal: barcodeDetail['line_total'] as int,
            code: barcodeDetail['barcode'] as String?,
          );
          if (item != null) items.add(item);
        }
        pendingName = null;
        pendingCode = null;
        continue;
      }

      if (pendingName != null) {
        final detail = _parsePlainQtyUnitTotalDetailLine(line);
        if (detail != null) {
          final item = _buildItem(
            name: pendingName,
            quantity: detail['quantity'] as int,
            unitPrice: detail['unit_price'] as int,
            lineTotal: detail['line_total'] as int,
            code: pendingCode,
          );
          if (item != null) items.add(item);
          pendingName = null;
          pendingCode = null;
          continue;
        }

        final priceOnly = _parseMoneyFromLine(line);
        if (_isOnlyMoneyLine(line) && priceOnly != null && _isValidItemPrice(priceOnly)) {
          final item = _buildItem(
            name: pendingName,
            quantity: 1,
            unitPrice: priceOnly,
            lineTotal: priceOnly,
            code: pendingCode,
          );
          if (item != null) items.add(item);
          pendingName = null;
          pendingCode = null;
          continue;
        }
      }

      if (_isDefinitelyNotItemLine(line)) {
        pendingName = null;
        pendingCode = null;
        continue;
      }

      final parsedItem = _parseMinimarketItemLine(line);
      if (parsedItem != null) {
        if (pendingName != null && pendingName.isNotEmpty) {
          final mergedName = _toTitleCase(
            _normalizeProductNameSmart(_cleanName("$pendingName ${parsedItem['name']}")),
          );
          parsedItem['name'] = mergedName;
        }

        if (i + 1 < itemEnd && _isOnlyMoneyLine(lines[i + 1])) {
          final nextPrice = _parseMoneyFromLine(lines[i + 1]);
          if (nextPrice != null && (nextPrice - (parsedItem['line_total'] as int)).abs() <= 50) {
            i++;
          }
        }

        if (i + 1 < itemEnd) {
          final nextDetail = _parseBarcodeDetailLine(lines[i + 1]);
          if (nextDetail != null) {
            final detailTotal = nextDetail['line_total'] as int;
            final currentTotal = parsedItem['line_total'] as int;
            if ((detailTotal - currentTotal).abs() <= 1000) {
              parsedItem['code'] = nextDetail['barcode'];
              parsedItem['quantity'] = nextDetail['quantity'];
              parsedItem['price'] = nextDetail['unit_price'];
              parsedItem['line_total'] = detailTotal;
              i++;
            }
          }
        }

        items.add(parsedItem);
        pendingName = null;
        pendingCode = null;
        continue;
      }

      final codeName = _extractCodeAndName(line);
      final candidateName = codeName['name'] ?? '';
      if (_looksLikeLooseProductName(candidateName)) {
        pendingName = candidateName;
        pendingCode = codeName['code'];
      } else {
        pendingName = null;
        pendingCode = null;
      }
    }

    return items;
  }

  static Map<String, dynamic>? _parseMinimarketItemLine(String line) {
    final clean = _normalizeText(line);
    final lower = _normalizeKeyword(clean);

    if (clean.length < 3) return null;
    if (!RegExp(r'[a-zA-Z]').hasMatch(clean)) return null;
    if (_isDefinitelyNotItemLine(clean)) return null;
    if (_isDiscountLine(lower)) return null;
    if (_isIgnoredMinimarketCharge(lower)) return null;
    if (_parseBarcodeDetailLine(clean) != null) return null;

    final tokens = clean.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (tokens.length < 2) return null;

    if (tokens.length >= 4) {
      final qtyToken = tokens[tokens.length - 3];
      final unitToken = tokens[tokens.length - 2];
      final totalToken = tokens[tokens.length - 1];

      final qty = _parsePureInt(qtyToken);
      final unitPrice = _parseMoneyToken(unitToken);
      final lineTotal = _parseMoneyToken(totalToken);

      if (qty != null &&
          _isValidQty(qty) &&
          unitPrice != null &&
          lineTotal != null &&
          _isValidItemPrice(unitPrice) &&
          _isValidItemPrice(lineTotal) &&
          (qty * unitPrice - lineTotal).abs() <= 1000) {
        final rawName = tokens.sublist(0, tokens.length - 3).join(' ');
        return _buildItem(name: rawName, quantity: qty, unitPrice: unitPrice, lineTotal: lineTotal);
      }
    }

    if (tokens.length >= 3) {
      final qtyToken = tokens[tokens.length - 2];
      final totalToken = tokens[tokens.length - 1];

      final qty = _parsePureInt(qtyToken);
      final lineTotal = _parseMoneyToken(totalToken);

      if (qty != null && _isValidQty(qty) && lineTotal != null && _isValidItemPrice(lineTotal)) {
        final rawName = tokens.sublist(0, tokens.length - 2).join(' ');
        final unitPrice = qty > 1 ? (lineTotal / qty).round() : lineTotal;
        return _buildItem(name: rawName, quantity: qty, unitPrice: unitPrice, lineTotal: lineTotal);
      }
    }

    if (tokens.length >= 3) {
      final compactToken = _digitsOnly(tokens[tokens.length - 2]);
      final totalToken = tokens[tokens.length - 1];
      final lineTotal = _parseMoneyToken(totalToken);

      if (compactToken.length >= 5 && compactToken.length <= 6 && lineTotal != null) {
        final qty = int.tryParse(compactToken.substring(0, 1));
        final unitPrice = int.tryParse(compactToken.substring(1));
        if (qty != null &&
            unitPrice != null &&
            _isValidQty(qty) &&
            _isValidItemPrice(unitPrice) &&
            (qty * unitPrice - lineTotal).abs() <= 1000) {
          final rawName = tokens.sublist(0, tokens.length - 2).join(' ');
          return _buildItem(name: rawName, quantity: qty, unitPrice: unitPrice, lineTotal: lineTotal);
        }
      }
    }

    if (tokens.length >= 3) {
      final a = _digitsOnly(tokens[tokens.length - 2]);
      final b = _digitsOnly(tokens[tokens.length - 1]);
      if (_parsePureInt(tokens[tokens.length - 2]) != null &&
          _parsePureInt(tokens[tokens.length - 1]) != null &&
          a.length >= 1 &&
          a.length <= 3 &&
          b.length == 3) {
        final price = int.tryParse('$a$b');
        if (price != null && _isValidItemPrice(price)) {
          final rawName = tokens.sublist(0, tokens.length - 2).join(' ');
          if (_looksLikeLooseProductName(rawName)) {
            return _buildItem(name: rawName, quantity: 1, unitPrice: price, lineTotal: price);
          }
        }
      }
    }

    final lastPrice = _parseMoneyToken(tokens.last);
    if (lastPrice != null && _isValidItemPrice(lastPrice)) {
      final rawName = tokens.sublist(0, tokens.length - 1).join(' ');
      if (_looksLikeLooseProductName(rawName)) {
        return _buildItem(name: rawName, quantity: 1, unitPrice: lastPrice, lineTotal: lastPrice);
      }
    }

    return null;
  }

  static Map<String, dynamic>? _parsePlainQtyUnitTotalDetailLine(String line) {
    final clean = _normalizeText(line);

    // Pattern: "1 X 14.200 14.200" / "1X 9.800 9.800" / "i X 5.000 5.000"
    final qtyXMatch = RegExp(
      r'^([iIlL]|\d{1,2})\s*[xX]\s*([\d.,]+)\s+([\d.,]+)$',
    ).firstMatch(clean);

    if (qtyXMatch != null) {
      final qtyRaw = qtyXMatch.group(1)!;
      final qty = RegExp(r'^[iIlL]$').hasMatch(qtyRaw)
          ? 1
          : (int.tryParse(qtyRaw) ?? 1);
      final unitPrice = _parseMoneyFromLine(qtyXMatch.group(2)!);
      final lineTotal = _parseMoneyFromLine(qtyXMatch.group(3)!);
      if (unitPrice != null &&
          lineTotal != null &&
          _isValidQty(qty) &&
          _isValidItemPrice(unitPrice) &&
          _isValidItemPrice(lineTotal)) {
        return {'quantity': qty, 'unit_price': unitPrice, 'line_total': lineTotal};
      }
    }

    // Pattern tanpa total terpisah: "1 X 14.200" -> total = qty * harga
    final qtyXNoTotal = RegExp(
      r'^([iIlL]|\d{1,2})\s*[xX]\s*([\d.,]+)$',
    ).firstMatch(clean);
    if (qtyXNoTotal != null) {
      final qtyRaw = qtyXNoTotal.group(1)!;
      final qty = RegExp(r'^[iIlL]$').hasMatch(qtyRaw)
          ? 1
          : (int.tryParse(qtyRaw) ?? 1);
      final unitPrice = _parseMoneyFromLine(qtyXNoTotal.group(2)!);
      if (unitPrice != null && _isValidQty(qty) && _isValidItemPrice(unitPrice)) {
        return {'quantity': qty, 'unit_price': unitPrice, 'line_total': qty * unitPrice};
      }
    }

    // --- kode lama tetap dipertahankan sebagai fallback ---
    final tokens = clean.split(' ').where((e) => e.trim().isNotEmpty).toList();

    if (tokens.length == 3) {
      final qty = _parsePureInt(tokens[0]);
      final unitPrice = _parseMoneyToken(tokens[1]);
      final lineTotal = _parseMoneyToken(tokens[2]);
      if (qty != null &&
          unitPrice != null &&
          lineTotal != null &&
          _isValidQty(qty) &&
          _isValidItemPrice(unitPrice) &&
          _isValidItemPrice(lineTotal) &&
          (qty * unitPrice - lineTotal).abs() <= 1000) {
        return {'quantity': qty, 'unit_price': unitPrice, 'line_total': lineTotal};
      }
    }

    if (tokens.length == 2) {
      final qty = _parsePureInt(tokens[0]);
      final unitPrice = _parseMoneyToken(tokens[1]);
      if (qty != null && unitPrice != null && _isValidQty(qty) && _isValidItemPrice(unitPrice)) {
        return {'quantity': qty, 'unit_price': unitPrice, 'line_total': qty * unitPrice};
      }
    }

    return null;
  }

  static Map<String, dynamic>? _parseBarcodeDetailLine(String line) {
    final clean = _normalizeText(line);

    final withBarcode = RegExp(
      r'^(\d{6,})\s+(?:(\d{1,3})\s+)?(?:PCS|PC|BKS|BTL|KG|GR|BOX|PACK|PCK|IKT|KLG)\s*[xX]\s*([\d.,\s]+)$',
      caseSensitive: false,
    ).firstMatch(clean);

    if (withBarcode != null) {
      final barcode = withBarcode.group(1);
      final qty = int.tryParse(withBarcode.group(2) ?? '1') ?? 1;
      final unitPrice = _parseMoneyFromLine(withBarcode.group(3) ?? '');
      if (unitPrice != null && _isValidQty(qty) && _isValidItemPrice(unitPrice)) {
        return {'barcode': barcode, 'quantity': qty, 'unit_price': unitPrice, 'line_total': qty * unitPrice};
      }
    }

    final noBarcode = RegExp(
      r'^(?:(\d{1,3})\s+)?(?:PCS|PC|BKS|BTL|KG|GR|BOX|PACK|PCK|IKT|KLG)\s*[xX]\s*([\d.,\s]+)$',
      caseSensitive: false,
    ).firstMatch(clean);

    if (noBarcode != null) {
      final qty = int.tryParse(noBarcode.group(1) ?? '1') ?? 1;
      final unitPrice = _parseMoneyFromLine(noBarcode.group(2) ?? '');
      if (unitPrice != null && _isValidQty(qty) && _isValidItemPrice(unitPrice)) {
        return {'barcode': null, 'quantity': qty, 'unit_price': unitPrice, 'line_total': qty * unitPrice};
      }
    }

    return null;
  }

  static Map<String, dynamic>? _buildItem({
    required String name,
    required int quantity,
    required int unitPrice,
    required int lineTotal,
    String? code,
  }) {
    var cleanName = _cleanName(name);
    cleanName = _fixEmbeddedDigitTypos(cleanName);
    cleanName = _normalizeProductNameSmart(cleanName);
    cleanName = _toTitleCase(cleanName);

    if (cleanName.isEmpty) return null;
    if (!_looksLikeLooseProductName(cleanName)) return null;
    if (!_isValidQty(quantity)) return null;
    if (!_isValidItemPrice(unitPrice)) return null;
    if (!_isValidItemPrice(lineTotal)) return null;

    return {
      'name': cleanName,
      'price': unitPrice,
      'quantity': quantity,
      'line_total': lineTotal,
      if (code != null && code.trim().isNotEmpty) 'code': code,
    };
  }
  static String _fixEmbeddedDigitTypos(String text) {
    const map = {'0': 'o', '1': 'i', '4': 'a', '3': 'e', '5': 's'};
    final chars = text.split('');

    for (int i = 0; i < chars.length; i++) {
      final c = chars[i];
      if (!map.containsKey(c)) continue;

      final prevIsLetter = i > 0 && RegExp(r'[a-zA-Z]').hasMatch(chars[i - 1]);
      final nextIsLetter = i < chars.length - 1 && RegExp(r'[a-zA-Z]').hasMatch(chars[i + 1]);

      if (prevIsLetter && nextIsLetter) {
        chars[i] = map[c]!;
      }
    }

    return chars.join();
  }

  static Map<String, int?> _parseSummaryFromBottom(List<String> lines) {
    int? subtotal;
    int? total;
    int? paid;
    int? change;
    int? savings;
    int? tax;
    int? serviceCharge;

    for (int i = 0; i < lines.length; i++) {
      final line = _normalizeText(lines[i]);
      final lower = _normalizeKeyword(line);

      if (lower.contains('total disc')) {
        savings ??= _valueOnSameOrNext(lines, i);
        continue;
      }

      if (_isDiscountLine(lower)) {
        final discount = _parseDiscountAmount(line);
        if (discount != null && discount > 0) savings = (savings ?? 0) + discount;
        continue;
      }

      if ((lower.contains('harga jual') || lower.contains('subtotal')) && !lower.contains('item')) {
        subtotal = _valueOnSameOrNext(lines, i) ?? subtotal;
        continue;
      }

      if (_isTotalLabel(lower)) {
        total = _valueOnSameOrNext(lines, i) ?? total;
        continue;
      }

      if (lower.startsWith('tunai') || lower.startsWith('cash')) {
        paid = _valueOnSameOrNext(lines, i) ?? paid;
        continue;
      }

      if (lower.startsWith('kembali') || lower.startsWith('kenbal') || lower.startsWith('kembal')) {
        change = _valueOnSameOrNext(lines, i) ?? change;
        continue;
      }

      if (lower.contains('ppn')) {
        final ppnMatch = RegExp(r'ppn\s*[=:]?\s*([\d.,\s]+)', caseSensitive: false).firstMatch(line);
        final value = ppnMatch != null ? _parseMoneyFromLine(ppnMatch.group(1) ?? '') : null;
        if (value != null) tax = value;
      }
    }

    return {
      'subtotal': subtotal,
      'total': total,
      'paid': paid,
      'change': change,
      'savings': savings,
      'tax': tax,
      'service_charge': serviceCharge,
    };
  }

  static bool _isTotalLabel(String lower) {
    if (lower.contains('total item') || lower.contains('total iten')) return false;
    if (lower.contains('total disc')) return false;
    if (lower.contains('total belanja')) return true;
    if (lower.startsWith('total')) return true;
    return false;
  }

  static int? _valueOnSameOrNext(List<String> lines, int index) {
    final same = _parseMoneyFromLine(lines[index]);
    if (same != null && same > 0) return same;

    for (int j = index + 1; j < lines.length && j <= index + 4; j++) {
      final lower = _normalizeKeyword(lines[j]);
      if (_isHardLabelOnly(lower)) continue;
      final value = _parseMoneyFromLine(lines[j]);
      if (value != null && value > 0) return value;
    }

    return null;
  }

  static bool _isHardLabelOnly(String lower) {
    return lower == 'total belanja' ||
        lower == 'tunai' ||
        lower == 'cash' ||
        lower == 'kembali' ||
        lower == 'kembalian' ||
        lower == 'kenbal ian' ||
        lower == 'total disc.' ||
        lower == 'total disc';
  }

  static List<Map<String, dynamic>> _parseDiscounts(List<String> lines) {
    final discounts = <Map<String, dynamic>>[];
    for (final line in lines) {
      final lower = _normalizeKeyword(line);
      if (_isDiscountLine(lower) || lower.contains('total disc')) {
        final amount = _parseDiscountAmount(line);
        if (amount != null && amount > 0) {
          discounts.add({'label': 'Discount', 'amount': amount});
        }
      }
    }
    return discounts;
  }

  static bool _isDiscountLine(String lower) {
    return lower.contains('disc') ||
        lower.contains('diskon') ||
        lower.contains('voucher') ||
        lower.startsWith('vc ');
  }

  static int? _parseDiscountAmount(String line) {
    final match = RegExp(r'-\s*([\d.,\s]+)').firstMatch(line);
    if (match != null) return _parseMoneyFromLine(match.group(1) ?? '');
    return _parseMoneyFromLine(line);
  }

  static int? _sumDiscounts(List<Map<String, dynamic>> discounts) {
    if (discounts.isEmpty) return null;
    var total = 0;
    for (final discount in discounts) {
      final amount = discount['amount'];
      if (amount is int) total += amount;
    }
    return total > 0 ? total : null;
  }

  static List<Map<String, dynamic>> _collectAmbiguousItemsFromZone(
      List<String> lines,
      int itemStart,
      int itemEnd,
      List<Map<String, dynamic>> detectedItems,
      ) {
    final ambiguous = <Map<String, dynamic>>[];
    String? pendingName;

    for (int i = itemStart; i < itemEnd; i++) {
      final line = _normalizeText(lines[i]);
      final lower = _normalizeKeyword(line);

      if (line.length < 2) continue;
      if (_isDiscountLine(lower)) continue;
      if (_isIgnoredMinimarketCharge(lower)) continue;
      if (_isDefinitelyNotItemLine(line)) continue;

      final parsed = _parseMinimarketItemLine(line);
      if (parsed != null) {
        parsed['raw_text'] = line;
        if (!_alreadyExists(detectedItems, parsed) && !_alreadyExists(ambiguous, parsed)) {
          ambiguous.add(_toAmbiguousItem(
            rawText: line,
            candidate: parsed,
            reason: 'Item-like OCR line found in item zone but not confirmed.',
            confidence: 0.62,
          ));
        }
        pendingName = null;
        continue;
      }

      if (pendingName != null) {
        final detail = _parsePlainQtyUnitTotalDetailLine(line) ?? _parseBarcodeDetailLine(line);
        if (detail != null) pendingName = null;
      }

      if (_looksLikeLooseProductName(line)) {
        pendingName = _cleanName(line);
      } else {
        pendingName = null;
      }
    }

    return ambiguous;
  }

  static Map<String, dynamic> _toAmbiguousItem({
    required String rawText,
    required Map<String, dynamic> candidate,
    required String reason,
    required double confidence,
  }) {
    return {
      'raw_text': rawText,
      'suggested_name': candidate['name'],
      'suggested_price': candidate['price'],
      'suggested_quantity': candidate['quantity'],
      'suggested_line_total': candidate['line_total'],
      'suggested_category': candidate['category'],
      'code': candidate['code'],
      'reason': reason,
      'confidence': confidence,
    };
  }

  static List<Map<String, dynamic>> _mergeDuplicateItems(List<Map<String, dynamic>> items) {
    final result = <Map<String, dynamic>>[];

    for (final item in items) {
      final index = result.indexWhere((existing) => _sameItem(existing, item));
      if (index == -1) {
        result.add(Map<String, dynamic>.from(item));
      } else {
        final existing = result[index];
        final qty = (existing['quantity'] as int) + (item['quantity'] as int);
        final lineTotal = (existing['line_total'] as int) + (item['line_total'] as int);
        existing['quantity'] = qty;
        existing['line_total'] = lineTotal;
        existing['price'] = qty > 0 ? (lineTotal / qty).round() : existing['price'];
      }
    }

    return result;
  }

  static bool _sameItem(Map<String, dynamic> a, Map<String, dynamic> b) {
    final codeA = a['code']?.toString() ?? '';
    final codeB = b['code']?.toString() ?? '';
    if (codeA.isNotEmpty && codeB.isNotEmpty && codeA == codeB) return true;

    final nameA = _nameKey(a['name']?.toString() ?? '');
    final nameB = _nameKey(b['name']?.toString() ?? '');
    final priceA = a['price'];
    final priceB = b['price'];
    return nameA == nameB && priceA == priceB;
  }

  static bool _alreadyExists(List<Map<String, dynamic>> items, Map<String, dynamic> candidate) {
    return items.any((item) => _sameItem(item, candidate));
  }

  static int _sumItemTotals(List<Map<String, dynamic>> items) {
    var total = 0;
    for (final item in items) {
      final value = item['line_total'];
      if (value is int) total += value;
    }
    return total;
  }

  static List<String> _buildWarnings({
    required List<Map<String, dynamic>> items,
    required List<Map<String, dynamic>> ambiguousItems,
    required int? total,
    required int sumItems,
    required int? savings,
  }) {
    final warnings = <String>[];

    if (ambiguousItems.isNotEmpty) {
      warnings.add('${ambiguousItems.length} item perlu konfirmasi sebelum disimpan.');
    }

    if (total != null && total > 0 && items.isNotEmpty) {
      final netItems = sumItems - (savings ?? 0);
      final diff = (total - netItems).abs();
      if (diff > 1000) {
        warnings.add('Total item belum sesuai dengan total struk. Mohon periksa dan koreksi item sebelum menyimpan.');
      }
    }

    if (items.isEmpty) {
      warnings.add('Tidak ada item yang berhasil terbaca. Mohon tambah item secara manual sebelum menyimpan.');
    }

    return warnings;
  }

  static bool _isDefinitelyNotItemLine(String line) {
    final lower = _normalizeKeyword(line);

    if (_isOnlyMoneyLine(line)) return true;
    if (_isFooterStart(lower)) return true;
    if (_isTotalLabel(lower)) return true;
    if (_containsAny(lower, [
      'alamat', 'jalan ', 'jln ', 'jl ', 'rt.', 'rw.', 'blok', 'kec:',
      'kec.', 'kota ', 'batam', 'npwp', 'npw:', 'npp', 'pt.', 'kasir',
      'receipt', 'telp', 'sms', 'wa:', 'kritik', 'saran', 'layanan',
      'konsumen', 'email', '@', 'bon ', 'tgl ', 'igl.',
    ])) {
      return true;
    }

    if (!RegExp(r'[a-zA-Z]').hasMatch(line)) return true;

    return false;
  }

  static bool _isIgnoredMinimarketCharge(String lower) {
    return lower.contains('kp rad') ||
        lower.contains('kp branding') ||
        lower.contains('branding') ||
        lower.contains('rad g') ||
        lower.contains('radig');
  }

  static bool _looksLikeItemRow(String line) {
    if (_isDefinitelyNotItemLine(line)) return false;
    return _parseMinimarketItemLine(line) != null;
  }

  static bool _looksLikeLooseProductName(String line) {
    final clean = _cleanName(line);
    final lower = _normalizeKeyword(clean);

    if (clean.length < 3) return false;
    if (!RegExp(r'[a-zA-Z]').hasMatch(clean)) return false;
    if (_isDefinitelyNotItemLine(clean)) return false;
    if (_isDiscountLine(lower)) return false;
    if (_isIgnoredMinimarketCharge(lower)) return false;

    final letters = RegExp(r'[a-zA-Z]').allMatches(clean).length;
    if (letters < 3) return false;

    return true;
  }

  static int? _parsePureInt(String token) {
    final raw = token.trim();
    if (RegExp(r'[a-zA-Z]').hasMatch(raw)) return null;
    if (raw.contains('-')) return null;
    final digits = _digitsOnly(raw);
    if (digits.isEmpty) return null;
    if (!RegExp(r'^\d+$').hasMatch(digits)) return null;
    return int.tryParse(digits);
  }

  static int? _parseMoneyToken(String token) {
    final raw = token.trim();
    if (raw.isEmpty) return null;
    if (RegExp(r'[a-zA-Z]').hasMatch(raw)) return null;
    if (raw.contains('-')) return null;
    return _parseMoneyFromLine(raw);
  }

  static int? _parseMoneyFromLine(String text) {
    var raw = text.trim();
    if (raw.isEmpty) return null;

    final matches = RegExp(r'(\d{1,3}(?:[.,]\s?\d{2,3})+|\d{3,7}|,\s?\d{3})')
        .allMatches(raw)
        .toList();
    if (matches.isEmpty) return null;

    var candidate = matches.last.group(0) ?? '';
    candidate = candidate.trim();

    final brokenTwoDigits = RegExp(r'^(\d{2})\s*,\s*(\d{2})$').firstMatch(candidate);
    if (brokenTwoDigits != null) {
      return int.tryParse('${brokenTwoDigits.group(1)}${brokenTwoDigits.group(2)}0');
    }

    final digits = _digitsOnly(candidate);
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  static bool _isOnlyMoneyLine(String line) {
    final clean = line.trim();
    if (clean.isEmpty) return false;
    if (RegExp(r'[a-zA-Z]').hasMatch(clean)) return false;
    return _parseMoneyFromLine(clean) != null;
  }

  static String _digitsOnly(String text) {
    return text.replaceAll(RegExp(r'[^0-9]'), '');
  }

  static bool _isValidQty(int qty) {
    return qty > 0 && qty <= 99;
  }

  static bool _isValidItemPrice(int value) {
    return value >= 100 && value <= 2000000;
  }

  static Map<String, String?> _extractCodeAndName(String line) {
    final clean = _normalizeText(line);
    final match = RegExp(r'^(\d{6,})\s+(.+)$').firstMatch(clean);
    if (match != null) {
      return {'code': match.group(1), 'name': _cleanName(match.group(2) ?? '')};
    }
    return {'code': null, 'name': _cleanName(clean)};
  }

  static String _cleanName(String raw) {
    var name = raw.trim();

    name = name.replaceAll(RegExp(r'\bRp\b', caseSensitive: false), ' ');
    name = name.replaceAll(RegExp(r'^\d+\.\s*'), ' ');
    name = name.replaceAll(RegExp(r"[^a-zA-Z0-9\s_./&\-']"), ' ');
    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    name = name.replaceAll(RegExp(r'\s+\d{1,3}([.,]\d{3})+$'), '').trim();

    return name;
  }

  static String _normalizeProductNameSmart(String rawName) {
    var lower = rawName.toLowerCase();

    lower = lower.replaceAll('_', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();

    lower = lower.replaceAll(RegExp(r'\bind0mie\b'), 'indomie');
    lower = lower.replaceAll(RegExp(r'\baqu4\b'), 'aqua');
    lower = lower.replaceAll(RegExp(r'\bmlnute\b'), 'minute');
    lower = lower.replaceAll(RegExp(r'\bmlneral\b'), 'mineral');
    lower = lower.replaceAll(RegExp(r'\bmineoral\b'), 'mineral');

    lower = lower.replaceAll(RegExp(r'\bin\s*dom\s*ie\b'), 'indomie');
    lower = lower.replaceAll(RegExp(r'\bindom\s*ie\b'), 'indomie');
    lower = lower.replaceAll(RegExp(r'\binohie\b'), 'indomie');

    lower = lower.replaceAll(RegExp(r'\bgprkgsg\b'), 'geprek85g');
    lower = lower.replaceAll(RegExp(r'\bgprkosg\b'), 'goreng');
    lower = lower.replaceAll(RegExp(r'\bgr\s*aym[.]?gp\b'), 'goreng ayam gp');
    lower = lower.replaceAll(RegExp(r'\bgr\s*aym\b'), 'goreng ayam');

    lower = lower.replaceAll(RegExp(r'\bgo\s*da\b'), 'golda');
    lower = lower.replaceAll(RegExp(r'\bcoff[.]?dol\s*e\b'), 'coffee dolce');
    lower = lower.replaceAll(RegExp(r'\bcoff[.]?dol\b'), 'coffee dolce');
    lower = lower.replaceAll(RegExp(r'\bcof\b'), 'coffee');
    lower = lower.replaceAll(RegExp(r'\b200m\b'), '200ml');

    lower = lower.replaceAll(RegExp(r'\bbe\s*ng[-\s]*beng\b'), 'beng-beng');
    lower = lower.replaceAll(RegExp(r'\bbeng\s*beng\b'), 'beng-beng');
    lower = lower.replaceAll(RegExp(r'\bhaxx\b'), 'maxx');
    if (lower.contains('beng-beng')) {
      lower = lower.replaceAll(RegExp(r'\b326\b'), '32g');
    }

    if (lower.contains('ktg plstk') ||
        lower.contains('plstk') ||
        lower.contains('kantong') ||
        RegExp(r'\bkp\b').hasMatch(lower) ||
        RegExp(r'\bbrad!n\b').hasMatch(lower) ||
        RegExp(r'\bbranding\b').hasMatch(lower)) {
      return 'Kantong Plastik';
    }

    lower = lower.replaceAll(RegExp(r'\s+'), ' ').trim();
    return lower;
  }

  static String _toTitleCase(String text) {
    return text
        .split(' ')
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
      if (part.length <= 2 && RegExp(r'^[A-Za-z0-9]+$').hasMatch(part)) {
        return part.toUpperCase();
      }
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    }).join(' ');
  }

  static String _nameKey(String text) {
    return _normalizeKeyword(text).replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  static bool _containsAny(String text, List<String> keywords) {
    for (final keyword in keywords) {
      if (text.contains(keyword)) return true;
    }
    return false;
  }

  static void dispose() {
    _recognizer.close();
  }
}