import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  static final _picker = ImagePicker();

  static final _recognizer = TextRecognizer(
    script: TextRecognitionScript.latin,
  );

  static const _skipKeywords = [
    // total / pembayaran
    'total',
    'subtotal',
    'total tagihan',
    'total bayar',
    'payment',
    'pembayaran',
    'bayar',
    'tunai',
    'cash',
    'debit',
    'kredit',
    'kembali',
    'kembalian',
    'terbayar',

    // pajak / diskon / service
    'diskon',
    'discount',
    'ppn',
    'pajak',
    'tax',
    'dpp',
    'charge',
    'charges',
    'service',
    'layanan',

    // footer
    'thank',
    'terima kasih',
    'terimakasih',
    'ter imakasih',
    'kunjungannya',
    'please come again',

    // header / identitas nota
    'struk',
    'nota',
    'invoice',
    'receipt',
    'check no',
    'rech.nr',
    'no nota',
    'no.',
    'telp',
    'tel.',
    'fax',
    'email',
    'e-mail',
    'www',
    'jl.',
    'ji.',
    'jalan',
    'ruko',
    'npwp',
    'pos',
    'closed',
    'tanggal',
    'tangal',
    'date',
    'time',
    'waktu',
    'order',
    'or der',
    'kasir',
    'cashier',
    'mak banu',
  ];

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

    final items = _parseReceiptLines(lines);

    print('========== PARSED ITEMS ==========');
    for (final item in items) {
      print(item);
    }

    return items;
  }

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

        // Semakin kecil, semakin tidak gampang menggabungkan baris.
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
      resultLines.add(_normalizeText(text));
    }

    return resultLines;
  }

  static List<Map<String, dynamic>> _parseReceiptLines(List<String> lines) {
    final items = <Map<String, dynamic>>[];
    final usedPriceIndexes = <int>{};

    for (int i = 0; i < lines.length; i++) {
      final line = _normalizeText(lines[i]);
      final lower = line.toLowerCase();

      if (line.length < 2) continue;

      // Kalau sudah masuk area total/footer, stop parsing.
      if (_isReceiptFooter(lower)) {
        break;
      }

      if (_shouldSkip(lower)) continue;

      // 1. Parse format produk + harga sebaris.
      final directParsed = _parseItemLine(line);

      if (directParsed != null) {
        items.add(directParsed);
        continue;
      }

      // 2. Parse format produk dan harga beda baris.
      if (!_looksLikeItemName(line)) continue;

      final itemInfo = _extractQtyAndName(line);
      if (itemInfo == null) continue;

      final qty = itemInfo['qty'] as int;
      final name = itemInfo['name'] as String;

      if (name.length < 2) continue;

      final priceResult = _findNearestPrice(lines, i, usedPriceIndexes);

      if (priceResult == null) continue;

      final price = priceResult['price'] as int;
      final priceIndex = priceResult['index'] as int;

      usedPriceIndexes.add(priceIndex);

      final item = _buildItem(
        name,
        qty,
        price,
        priceIsLineTotal: true,
      );

      if (item != null) {
        items.add(item);
      }
    }

    return _mergeDuplicateItems(items);
  }

  static Map<String, dynamic>? _parseItemLine(String line) {
    final clean = _normalizeText(line);
    final priceLike = _priceLikePattern();

    // Format:
    // Telur 2 500 1000
    // Artinya: nama=Telur, qty=2, harga satuan=500, total=1000
    final nameQtyUnitTotal = RegExp(
      r'^(.+?)\s+(\d{1,3})\s+([0-9]{3,})\s+([0-9]{3,})$',
      caseSensitive: false,
    ).firstMatch(clean);

    if (nameQtyUnitTotal != null) {
      final name = _cleanName(nameQtyUnitTotal.group(1)!);
      final qty = int.tryParse(nameQtyUnitTotal.group(2)!) ?? 1;
      final unitPrice = _parsePrice(nameQtyUnitTotal.group(3)!);
      final totalPrice = _parsePrice(nameQtyUnitTotal.group(4)!);

      if (qty > 1 && unitPrice * qty == totalPrice) {
        return _buildItem(
          name,
          qty,
          unitPrice,
          priceIsLineTotal: false,
        );
      }

      return _buildItem(
        name,
        qty,
        totalPrice,
        priceIsLineTotal: true,
      );
    }

    // Format:
    // 4 Nasi Putih 24.000
    // 1 Jengkol Goreng Satuan 3.000
    final qtyNamePrice = RegExp(
      '^'
      r'(\d{1,3})'
      r'\s+'
      r'(.+?)'
      r'\s+'
      '($priceLike)'
      r'$',
      caseSensitive: false,
    ).firstMatch(clean);

    if (qtyNamePrice != null) {
      final qty = int.tryParse(qtyNamePrice.group(1)!) ?? 1;
      final name = _cleanName(qtyNamePrice.group(2)!);
      final price = _parsePrice(qtyNamePrice.group(3)!);

      return _buildItem(
        name,
        qty,
        price,
        priceIsLineTotal: true,
      );
    }

    // Format:
    // Beras (5 kg) Rp 60,000
    // Susu Cair (5000 gr) Rp 30,000
    // Gula Pasir (2 kotak) 15,000
    //
    // Catatan:
    // Angka di tengah nama tidak dianggap qty.
    // Jadi "5 kg" tetap bagian dari nama produk.
    final namePrice = RegExp(
      '^'
      r'(.+?)'
      r'\s+'
      '($priceLike)'
      r'$',
      caseSensitive: false,
    ).firstMatch(clean);

    if (namePrice != null) {
      final name = _cleanName(namePrice.group(1)!);
      final price = _parsePrice(namePrice.group(2)!);

      return _buildItem(
        name,
        1,
        price,
        priceIsLineTotal: true,
      );
    }

    return null;
  }

  static String _priceLikePattern() {
    // Support:
    // Rp 60,000
    // 60,000
    // 60.000
    // 60 000
    // 24. 000
    // 36, 000
    // 6,. 000
    // L 000 / I 000 karena OCR kadang salah baca 1 jadi L/I.
    return r'(?:Rp\s*)?[0-9OIlL]{1,3}(?:[.,\s]*[0-9OIlL]{3})+';
  }

  static bool _looksLikeItemName(String line) {
    final lower = line.toLowerCase();

    if (_shouldSkip(lower)) return false;
    if (_isOnlyPrice(line)) return false;

    // Jangan ambil tanggal/jam.
    if (RegExp(r'\d{1,2}/\d{1,2}/\d{2,4}').hasMatch(lower)) return false;
    if (RegExp(r'\d{1,2}\s+\w+\s+\d{2,4}').hasMatch(lower)) return false;
    if (RegExp(r'\d{1,2}:\d{2}').hasMatch(lower)) return false;

    // Harus punya huruf.
    if (!RegExp(r'[a-zA-Z]').hasMatch(line)) return false;

    final letters = RegExp(r'[a-zA-Z]').allMatches(line).length;
    if (letters < 3) return false;

    // Jangan ambil header toko/alamat.
    if (lower.contains('toko')) return false;
    if (lower.contains('kampus')) return false;
    if (lower.contains('pendidikan')) return false;
    if (lower.contains('pendicakan')) return false;

    return true;
  }

  static Map<String, dynamic>? _extractQtyAndName(String line) {
    final clean = _normalizeText(line);

    // Qty cuma dianggap kalau angka ada di awal baris.
    // Contoh:
    // 4 Nasi Putih
    // 2 Ayam Goreng
    // 3 Es Teh Manis
    final qtyName = RegExp(r'^(\d{1,3})\s+(.+)$').firstMatch(clean);

    if (qtyName != null) {
      final qty = int.tryParse(qtyName.group(1)!) ?? 1;
      final name = _cleanName(qtyName.group(2)!);

      if (name.length < 2) return null;

      return {
        'qty': qty,
        'name': name,
      };
    }

    // Kalau angka ada di tengah nama, tetap dianggap nama produk.
    // Contoh:
    // Beras (5 kg)
    // Susu Cair (5000 gr)
    // Gula Pasir (2 kotak)
    final name = _cleanName(clean);

    if (name.length < 2) return null;

    return {
      'qty': 1,
      'name': name,
    };
  }

  static Map<String, dynamic>? _findNearestPrice(
      List<String> lines,
      int itemIndex,
      Set<int> usedPriceIndexes,
      ) {
    // Cari harga terdekat dari baris produk.
    // Dicek atas dan bawah secara bergantian.
    for (int offset = 1; offset <= 4; offset++) {
      final prevIndex = itemIndex - offset;
      final nextIndex = itemIndex + offset;

      // Cek harga sebelum item.
      // Contoh:
      // 24.000
      // 4 Nasi Putih
      if (prevIndex >= 0 && !usedPriceIndexes.contains(prevIndex)) {
        final prevLine = _normalizeText(lines[prevIndex]);
        final prevLower = prevLine.toLowerCase();

        if (!_shouldSkip(prevLower) && _isOnlyPrice(prevLine)) {
          final price = _parsePrice(prevLine);

          if (_isValidItemPrice(price)) {
            return {
              'index': prevIndex,
              'price': price,
            };
          }
        }
      }

      // Cek harga setelah item.
      // Contoh:
      // Beras (5 kg)
      // Rp 60,000
      if (nextIndex < lines.length && !usedPriceIndexes.contains(nextIndex)) {
        final nextLine = _normalizeText(lines[nextIndex]);
        final nextLower = nextLine.toLowerCase();

        // Kalau sudah masuk footer, jangan ambil harga setelah itu.
        if (_isReceiptFooter(nextLower)) {
          break;
        }

        if (!_shouldSkip(nextLower) && _isOnlyPrice(nextLine)) {
          final price = _parsePrice(nextLine);

          if (_isValidItemPrice(price)) {
            return {
              'index': nextIndex,
              'price': price,
            };
          }
        }
      }
    }

    return null;
  }

  static Map<String, dynamic>? _buildItem(
      String name,
      int qty,
      int price, {
        required bool priceIsLineTotal,
      }) {
    name = _cleanName(name);

    if (name.length < 2) return null;
    if (!_isValidItemPrice(price)) return null;

    if (qty <= 0 || qty > 999) {
      qty = 1;
    }

    // Karena ScanPage menghitung total = price * quantity,
    // price harus disimpan sebagai harga satuan.
    //
    // Contoh:
    // OCR: 4 Nasi Putih 24.000
    // Simpan: price=6000, quantity=4
    final unitPrice =
    priceIsLineTotal && qty > 1 ? (price / qty).round() : price;

    if (!_isValidItemPrice(unitPrice)) return null;

    return {
      'name': _toTitleCase(name),
      'price': unitPrice,
      'quantity': qty,
      'category': _guessCategory(name),
    };
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

  static bool _isReceiptFooter(String lower) {
    return lower.contains('subtotal') ||
        lower.contains('total belanja') ||
        lower.contains('total tagihan') ||
        lower.contains('total bayar') ||
        lower.contains('total bay ar') ||
        lower.contains('pembayaran') ||
        lower.contains('tunai') ||
        lower.contains('payment') ||
        lower.contains('debit') ||
        lower.contains('kredit') ||
        lower.contains('kembali') ||
        lower.contains('terbayar') ||
        lower.contains('terima kasih') ||
        lower.contains('terimakasih') ||
        lower.contains('ter imakasih') ||
        lower.contains('kunjungannya');
  }

  static bool _shouldSkip(String lower) {
    return _skipKeywords.any((kw) => lower.contains(kw));
  }

  static String _normalizeText(String text) {
    return text
        .replaceAll('|', ' ')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _cleanName(String raw) {
    var name = raw;

    // Buang kata Rp yang sering ikut kebaca sebagai nama item.
    name = name.replaceAll(
      RegExp(r'\brp\b', caseSensitive: false),
      '',
    );

    // Ubah kurung jadi spasi, tapi isi dalamnya tetap dipertahankan.
    // Contoh: Beras (5 kg) -> Beras 5 kg
    name = name.replaceAll('(', ' ');
    name = name.replaceAll(')', ' ');

    // Buang simbol aneh, tapi tetap simpan angka seperti 5 kg, 5000 gr, 2 pcs.
    name = name.replaceAll(RegExp(r'[^\w\s\-./]'), ' ');

    // Buang kata yang tidak perlu.
    name = name.replaceAll(
      RegExp(r'\bqty\b', caseSensitive: false),
      '',
    );

    // Buang pcs, tapi angkanya tetap boleh tinggal.
    // Contoh: Sabun Mandi 2 pcs -> Sabun Mandi 2
    name = name.replaceAll(
      RegExp(r'\bpcs\b', caseSensitive: false),
      '',
    );

    // Bersihkan harga yang kadang nyangkut di nama.
    // Contoh: Sate Ati Ampela L 000 -> Sate Ati Ampela
    name = name.replaceAll(
      RegExp(r'\b[OIlL]?\s*000\b$', caseSensitive: false),
      '',
    );

    name = name.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Kalau nama cuma angka, jangan anggap item.
    if (RegExp(r'^[0-9\s.,]+$').hasMatch(name)) {
      return '';
    }

    return name;
  }

  static String _toTitleCase(String text) {
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;

      // Biar ukuran seperti 75G / 5000GR tetap terlihat oke.
      if (RegExp(r'\d').hasMatch(word)) {
        return word.toUpperCase();
      }

      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  static String _guessCategory(String name) {
    final lower = name.toLowerCase();

    if (_containsAny(lower, [
      'beras',
      'nasi',
      'mie',
      'mi ',
      'tepung',
      'gula',
      'garam',
      'minyak',
      'minak',
      'roti',
      'bread',
      'pudding',
      'croissant',
      'choco',
      'chocolat',
      'coklat',
      'biskuit',
      'telur',
      'cream',
      'tempe',
      'lalapan',
      'jengkol',
    ])) {
      return 'Pantry';
    }

    if (_containsAny(lower, [
      'ayam',
      'ikan',
      'daging',
      'sayur',
      'buah',
      'sosis',
      'bakso',
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
      'juice',
      'latte',
      'minuman',
      'es teh',
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
    ])) {
      return 'Cleaning Supplies';
    }

    return 'Others';
  }

  static bool _containsAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
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
        merged[key]!['quantity'] =
            (merged[key]!['quantity'] as int) + (item['quantity'] as int);
      }
    }

    return merged.values.toList();
  }

  static void dispose() {
    _recognizer.close();
  }
}