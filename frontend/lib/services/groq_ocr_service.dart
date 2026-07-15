import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/groq_config.dart';

/// Hasil enhancement dari Groq setelah melewati validasi rule-based lokal.
///
/// - [items]: item yang lolos validasi matematis (qty * price ≈ line_total,
///   harga & qty dalam batas wajar, confidence cukup tinggi) sehingga aman
///   ditampilkan sebagai daftar belanja terkonfirmasi.
/// - [ambiguousItems]: item yang gagal salah satu validasi di atas, sehingga
///   perlu dikonfirmasi manual oleh user. Bentuknya mengikuti format yang
///   sama dengan `ambiguous_items` dari OcrService (raw_text,
///   suggested_name, suggested_price, dst) supaya ReviewScanPage bisa
///   menampilkannya tanpa perubahan apapun.
///
/// Setiap item (baik confirmed maupun ambiguous) selalu membawa field
/// `id` — identitas stabil yang sama dengan yang dikirim ke Groq sebelum
/// request. ID inilah satu-satunya identitas item yang sah untuk seluruh
/// proses pencocokan, validasi, fallback, dan duplicate detection. Nama
/// produk BUKAN identitas: nama sengaja boleh diperbaiki oleh Groq
/// (typo, singkatan, dsb) tanpa membuat item tersebut dianggap item baru.
class GroqEnhanceResult {
  final List<Map<String, dynamic>> items;
  final List<Map<String, dynamic>> ambiguousItems;

  const GroqEnhanceResult({required this.items, required this.ambiguousItems});
}

class GroqOcrService {
  // ── Batas nilai wajar, senada dengan OcrService, supaya konsisten. ──
  static const int _minPrice = 100;
  static const int _maxPrice = 2000000;
  static const int _maxQty = 99;

  // Toleransi selisih pembulatan saat memvalidasi qty * price == line_total.
  static const int _mathTolerance = 25;

  // Confidence minimum dari LLM agar item dianggap "confirmed", bukan
  // ambiguous. Ini HANYA sinyal tambahan — keputusan akhir tetap harus lolos
  // validasi matematis deterministik di _resolveQuantityPrice.
  static const double _confidenceThreshold = 0.55;

  // Nama field identitas stabil yang dipakai di payload, prompt, parsing
  // response, dan seluruh proses pencocokan/fallback. Sengaja disentralkan
  // di satu konstanta supaya tidak ada bagian kode lain yang diam-diam
  // kembali memakai nama produk sebagai kunci.
  static const String _idKey = 'id';

  // Aturan #4: kata-kata ini menandakan baris BUKAN item belanja yang sah.
  static const List<String> _cancelKeywords = [
    'cancel', 'void', 'retur', 'refund', 'batal', 'dibatalkan',
  ];

  /// Kirim [rawItems] (hasil parser Dart/OcrService yang sudah tervalidasi
  /// secara matematis) ke Groq untuk dibersihkan namanya (typo dsb), lalu
  /// jalankan validasi rule-based deterministik atas hasilnya. Groq TIDAK
  /// pernah menjadi otoritas akhir soal valid/tidaknya sebuah item, apalagi
  /// otoritas parsing utama — dia hanya memberi sinyal (nama yang
  /// diperbaiki + confidence), keputusan akhir selalu dihitung ulang di
  /// sisi Dart (aturan #11: "Buat parser deterministic. Jangan mengarang.").
  /// OcrService tetap menjadi satu-satunya sumber data item (nilai qty,
  /// price, line_total, code) — Groq hanya boleh menumpangkan koreksi nama
  /// dan sinyal confidence di atasnya.
  ///
  /// Identitas setiap item (`id`) dibuat DI SINI, SEBELUM request ke Groq,
  /// berdasarkan urutan/index item dari OcrService (atau `id` yang sudah
  /// melekat pada item bila sumbernya sudah menyertakan satu). ID inilah
  /// yang wajib dikembalikan Groq apa adanya pada tiap item balasannya, dan
  /// dipakai untuk seluruh pencocokan, validasi, fallback, serta duplicate
  /// detection — BUKAN nama produk.
  static Future<GroqEnhanceResult> enhanceItems(
    List<Map<String, dynamic>> rawItems, {
    int? ocrDetectedTotal,
  }) async {
    if (rawItems.isEmpty) {
      return const GroqEnhanceResult(items: [], ambiguousItems: []);
    }

    final itemsWithId = _assignStableIds(rawItems);

    if (!GroqConfig.isConfigured) {
      // Tanpa Groq, percayakan sepenuhnya pada hasil OcrService, yang sudah
      // divalidasi secara matematis (qty*price==line_total, batas harga,
      // dll) sebelum sampai di sini.
      return GroqEnhanceResult(
        items: List<Map<String, dynamic>>.from(itemsWithId),
        ambiguousItems: const [],
      );
    }

    List<dynamic>? llmItems;
    try {
      llmItems = await _callGroq(itemsWithId);
    } catch (e) {
      print('Groq Error: $e');
      llmItems = null;
    }

    // Jika panggilan Groq gagal total / balasannya tidak bisa diparse,
    // fallback ke hasil parser Dart apa adanya (lebih aman daripada
    // mengembalikan sesuatu yang berpotensi salah).
    if (llmItems == null) {
      return GroqEnhanceResult(
        items: List<Map<String, dynamic>>.from(itemsWithId),
        ambiguousItems: const [],
      );
    }

    return _validateAndSplit(llmItems, itemsWithId);
  }

  // ── Identitas item (ID stabil) ──

  /// Memberi tiap item ID stabil berbasis index kemunculannya pada hasil
  /// OcrService, kecuali item tersebut sudah membawa `id` sebelumnya (mis.
  /// dari pemanggil lain di masa depan) — dalam hal ini id yang sudah ada
  /// dipertahankan apa adanya. ID ini murni identitas teknis (tidak pernah
  /// ditampilkan ke user) dan tidak pernah berubah walaupun nama produknya
  /// berubah karena dikoreksi Groq.
  static List<Map<String, dynamic>> _assignStableIds(
    List<Map<String, dynamic>> rawItems,
  ) {
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < rawItems.length; i++) {
      final item = Map<String, dynamic>.from(rawItems[i]);
      final existingId = item[_idKey];
      item[_idKey] = (existingId == null || existingId.toString().isEmpty)
          ? i.toString()
          : existingId.toString();
      result.add(item);
    }
    return result;
  }

  // ── Pemanggilan Groq ──

  static Future<List<dynamic>?> _callGroq(
    List<Map<String, dynamic>> itemsWithId,
  ) async {
    final payload = itemsWithId
        .map((e) => {
              _idKey: e[_idKey],
              'name': e['name'],
              'quantity': e['quantity'],
              'price': e['price'],
              'line_total': e['line_total'] ?? e['total'],
            })
        .toList();

    final response = await http
        .post(
          Uri.parse(GroqConfig.endpoint),
          headers: {
            'Authorization': 'Bearer ${GroqConfig.token}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'model': GroqConfig.model,
            'temperature': 0,
            'max_tokens': 1500,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {'role': 'user', 'content': _buildUserPrompt(payload)},
            ],
          }),
        )
        .timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      print(response.body);
      return null;
    }

    final json = jsonDecode(response.body);
    final content = json['choices']?[0]?['message']?['content'];
    if (content is! String) return null;

    final text = _stripToJsonArray(content);
    final decoded = jsonDecode(text);

    if (decoded is List) return decoded;
    if (decoded is Map && decoded['items'] is List) return decoded['items'] as List;
    return null;
  }

  static String _stripToJsonArray(String raw) {
    var text = raw.replaceAll('```json', '').replaceAll('```', '').trim();

    // Jaga-jaga bila model tetap menyisipkan teks di luar JSON (preamble,
    // penjelasan, dll): ambil substring dari '[' pertama sampai ']' terakhir.
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      text = text.substring(start, end + 1);
    }
    return text;
  }

  static const String _systemPrompt =
      'Kamu adalah mesin validasi OCR struk belanja Indonesia. Kamu HANYA '
      'membalas dengan JSON array yang valid, tanpa markdown, tanpa ```json, '
      'tanpa penjelasan apapun di luar JSON. Kamu tidak pernah mengarang '
      'angka yang tidak ada dasarnya di data input. Setiap item input '
      'membawa field "id" yang WAJIB kamu kembalikan persis sama (tidak '
      'boleh diubah, dihilangkan, ditukar dengan item lain, atau dibuat '
      'baru) pada item yang berkorespon di output, karena "id" adalah '
      'satu-satunya identitas item yang sah — bukan nama produk.';

  static String _buildUserPrompt(List<Map<String, dynamic>> items) {
    return '''
- Setiap item punya field "id". Kembalikan "id" itu apa adanya untuk setiap item yang kamu pertahankan di output.
- Jangan pernah menukar "id" antar item, dan jangan membuat "id" baru yang tidak ada di input.
- Perbaiki hanya nama produk.
- Jangan mengubah arti nama.
- Angka seperti 525ML, 300G, 48G, 20X20, 2X137 tetap bagian nama produk.
- Jangan mengubah quantity, price, atau line_total kecuali jelas salah.
- Jangan mengarang angka.
- Hapus dari output item CANCEL, VOID, RETUR, REFUND, dan BATAL (jangan disertakan sama sekali).
- Sertakan confidence (0.0–1.0).

Balas HANYA JSON array:

[
{"id":"","name":"","quantity":1,"price":0,"line_total":0,"confidence":1.0}
]

Input:
${jsonEncode(items)}
''';
  }

  // ── Validasi rule-based (postprocessing) ──
  //
  // Ini adalah lapisan otoritatif. LLM hanya dipakai untuk membersihkan nama
  // & memberi sinyal confidence; keputusan "item ini valid atau harus masuk
  // ambiguous_items" SELALU ditentukan lewat pengecekan matematis
  // deterministik di sini (aturan #6, #9, #11 dari spesifikasi).
  //
  // Seluruh pencocokan item LLM <-> item asli dari OcrService memakai
  // `id`, bukan nama. Ini penting: kalau Groq memperbaiki nama produk yang
  // tadinya typo, item itu tetap dianggap SAMA (bukan item baru) selama
  // id-nya sama, dan tidak akan pernah muncul dua kali di hasil akhir.
  static GroqEnhanceResult _validateAndSplit(
    List<dynamic> llmItems,
    List<Map<String, dynamic>> originalItemsWithId,
  ) {
    final items = <Map<String, dynamic>>[];
    final ambiguous = <Map<String, dynamic>>[];
    final matchedOriginalIds = <String>{};

    final originalById = <String, Map<String, dynamic>>{
      for (final o in originalItemsWithId) o[_idKey].toString(): o,
    };

    for (final raw in llmItems) {
      if (raw is! Map) continue;

      final id = raw[_idKey]?.toString();
      // Tanpa id yang valid, item ini tidak bisa dipercaya sebagai koreksi
      // dari item mana pun — Groq bukan otoritas identitas. Item asli
      // (kalau memang ada) tetap diselamatkan lewat jaring pengaman di
      // bawah, berdasarkan id aslinya sendiri.
      if (id == null || id.isEmpty) continue;

      final original = originalById[id];
      // Groq mengembalikan id yang tidak dikenal (halusinasi) -- abaikan,
      // karena tidak bisa diverifikasi item ini koreksi dari item yang mana.
      if (original == null) continue;

      // Id ini sudah berkorespondensi dengan sebuah item asli yang valid,
      // jadi tandai sebagai "sudah ditangani" apa pun hasil akhirnya
      // (valid/ambiguous/cancelled) supaya jaring pengaman di bawah tidak
      // menduplikasikannya.
      matchedOriginalIds.add(id);

      final name = (raw['name'] ?? original['name'] ?? '').toString().trim();
      if (name.isEmpty || _looksCancelled(name)) continue;

      final qty = _asIntOrNull(raw['quantity']);
      final price = _asIntOrNull(raw['price']);
      final lineTotal = _asIntOrNull(raw['line_total'] ?? raw['total']);
      final llmConfidence = _asDoubleOrNull(raw['confidence']) ?? 0.5;

      final resolved = _resolveQuantityPrice(qty: qty, price: price, lineTotal: lineTotal);

      final candidate = {
        'name': name,
        'price': resolved.price ?? price ?? 0,
        'quantity': resolved.quantity ?? qty ?? 1,
        'line_total': resolved.lineTotal ?? lineTotal ?? 0,
      };

      final guardIssue = _nameEmbeddedNumberGuard(
        name: name,
        original: original,
        candidatePrice: candidate['price'] as int,
      );

      final priceOk = _isValidPrice(candidate['price'] as int);
      final qtyOk = _isValidQty(candidate['quantity'] as int);
      final confidenceOk = llmConfidence >= _confidenceThreshold;
      final isValid = resolved.mathOk && priceOk && qtyOk && confidenceOk && guardIssue == null;

      if (isValid) {
        items.add({
          _idKey: id,
          'name': name,
          'price': candidate['price'],
          'quantity': candidate['quantity'],
          'line_total': candidate['line_total'],
          if (original['code'] != null) 'code': original['code'],
        });
      } else {
        ambiguous.add({
          _idKey: id,
          'raw_text': (original['name'] ?? name).toString(),
          'suggested_name': name,
          'suggested_price': candidate['price'],
          'suggested_quantity': candidate['quantity'],
          'suggested_line_total': candidate['line_total'],
          'suggested_category': null,
          'code': original['code'],
          'reason': guardIssue ?? _reasonFor(resolved.mathOk, priceOk, qtyOk),
          'confidence': resolved.mathOk ? llmConfidence : llmConfidence * 0.5,
        });
      }
    }

    // Jaring pengaman: jika Groq diam-diam menghilangkan sebuah item asli
    // (bukan karena kata CANCEL/VOID/dsb) tanpa alasan, atau balasannya
    // gagal diparse untuk item tersebut, jangan sampai item yang sudah
    // tervalidasi matematis oleh parser Dart hilang begitu saja.
    //
    // Pencocokan di sini SELALU berbasis id, bukan nama, sehingga tetap
    // benar walaupun nama asli item tersebut typo/berbeda dari yang
    // seharusnya dikembalikan Groq, dan tidak akan pernah menghasilkan
    // item duplikat karena setiap id hanya diproses tepat satu kali baik
    // lewat hasil Groq (loop di atas) maupun lewat jaring pengaman ini.
    for (final o in originalItemsWithId) {
      final id = o[_idKey].toString();
      if (matchedOriginalIds.contains(id)) continue;
      if (_looksCancelled((o['name'] ?? '').toString())) continue;
      items.add(Map<String, dynamic>.from(o));
    }

    return GroqEnhanceResult(items: items, ambiguousItems: ambiguous);
  }

  static String _reasonFor(bool mathOk, bool priceOk, bool qtyOk) {
    if (!mathOk) return 'Perhitungan qty x harga tidak sesuai dengan total. Mohon periksa manual.';
    if (!priceOk) return 'Harga di luar batas wajar. Mohon periksa manual.';
    if (!qtyOk) return 'Jumlah (quantity) tidak wajar. Mohon periksa manual.';
    return 'Hasil pembacaan kurang yakin. Mohon konfirmasi manual.';
  }

  static bool _looksCancelled(String name) {
    final lower = name.toLowerCase();
    return _cancelKeywords.any((k) => lower.contains(k));
  }

  static int? _asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.round();
    if (v is String) {
      final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
      return digits.isEmpty ? null : int.tryParse(digits);
    }
    return null;
  }

  static double? _asDoubleOrNull(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static bool _isValidPrice(int v) => v >= _minPrice && v <= _maxPrice;
  static bool _isValidQty(int v) => v > 0 && v <= _maxQty;

  /// Merekonsiliasi quantity/price/line_total memakai hubungan matematis
  /// qty * price = line_total (aturan #6). Jika qty hilang, hitung dari
  /// line_total / price (aturan #3 & #10). Tidak pernah mengarang angka
  /// baru yang tidak bisa diturunkan dari data yang ada — bila tidak bisa
  /// direkonsiliasi, mathOk diset false sehingga item jatuh ke
  /// ambiguous_items (aturan #11).
  static _ResolvedQty _resolveQuantityPrice({int? qty, int? price, int? lineTotal}) {
    if (qty != null && price != null && lineTotal != null) {
      final expected = qty * price;
      if ((expected - lineTotal).abs() <= _mathTolerance) {
        return _ResolvedQty(quantity: qty, price: price, lineTotal: lineTotal, mathOk: true);
      }
      if (price > 0 && lineTotal % price == 0) {
        final derivedQty = lineTotal ~/ price;
        if (derivedQty > 0 && derivedQty <= _maxQty) {
          return _ResolvedQty(quantity: derivedQty, price: price, lineTotal: lineTotal, mathOk: true);
        }
      }
      return _ResolvedQty(quantity: qty, price: price, lineTotal: lineTotal, mathOk: false);
    }

    // qty hilang, price & line_total ada -> qty = line_total / price.
    if (qty == null && price != null && price > 0 && lineTotal != null) {
      if (lineTotal % price == 0) {
        final derivedQty = lineTotal ~/ price;
        if (derivedQty > 0 && derivedQty <= _maxQty) {
          return _ResolvedQty(quantity: derivedQty, price: price, lineTotal: lineTotal, mathOk: true);
        }
      }
      return _ResolvedQty(quantity: 1, price: price, lineTotal: lineTotal, mathOk: false);
    }

    // line_total hilang, qty & price ada -> hitung line_total.
    if (lineTotal == null && qty != null && price != null) {
      return _ResolvedQty(quantity: qty, price: price, lineTotal: qty * price, mathOk: true);
    }

    // price hilang, qty & line_total ada -> hitung price.
    if (price == null && qty != null && qty > 0 && lineTotal != null) {
      if (lineTotal % qty == 0) {
        return _ResolvedQty(quantity: qty, price: lineTotal ~/ qty, lineTotal: lineTotal, mathOk: true);
      }
      return _ResolvedQty(quantity: qty, price: lineTotal, lineTotal: lineTotal, mathOk: false);
    }

    // Data terlalu minim untuk direkonsiliasi secara matematis -> ambiguous.
    return _ResolvedQty(
      quantity: qty ?? 1,
      price: price ?? lineTotal,
      lineTotal: lineTotal ?? price,
      mathOk: false,
    );
  }

  /// Guard terhadap kasus di mana angka yang menempel pada nama produk
  /// (ukuran/berat seperti 525ML, 300G, 2X137) ikut "tertangkap" sebagai
  /// price oleh LLM (aturan #1 & #8), dan guard terhadap perubahan harga
  /// drastis tanpa dasar dibanding hasil parser Dart sebelumnya.
  static String? _nameEmbeddedNumberGuard({
    required String name,
    required Map<String, dynamic>? original,
    required int candidatePrice,
  }) {
    final embeddedNumbers = <int>{};

    for (final m in RegExp(r'(\d{2,4})\s*(ML|ml|G|g|GR|gr|KG|kg|L|l)\b').allMatches(name)) {
      final n = int.tryParse(m.group(1) ?? '');
      if (n != null) embeddedNumbers.add(n);
    }

    final multiplyMatch = RegExp(r'(\d{1,3})\s*[xX]\s*(\d{2,4})').firstMatch(name);
    if (multiplyMatch != null) {
      final n = int.tryParse(multiplyMatch.group(2) ?? '');
      if (n != null) embeddedNumbers.add(n);
    }

    if (embeddedNumbers.contains(candidatePrice)) {
      return 'Angka pada nama produk (ukuran/berat) kemungkinan tertukar dengan harga. Mohon periksa manual.';
    }

    // Bandingkan dengan harga asli dari parser Dart (sebelum Groq) sebagai
    // jangkar: jika Groq mengubah harga secara drastis (lebih dari 5x lipat
    // naik/turun), curigai salah baca daripada langsung dipercaya.
    final originalPrice = _asIntOrNull(original?['price']);
    if (originalPrice != null && originalPrice > 0) {
      final ratio = candidatePrice / originalPrice;
      if (ratio > 5 || ratio < 0.2) {
        return 'Harga berubah drastis dari hasil OCR awal. Mohon periksa manual.';
      }
    }

    return null;
  }
}

class _ResolvedQty {
  final int? quantity;
  final int? price;
  final int? lineTotal;
  final bool mathOk;

  const _ResolvedQty({
    required this.quantity,
    required this.price,
    required this.lineTotal,
    required this.mathOk,
  });
}