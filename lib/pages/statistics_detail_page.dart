import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../data/app_data.dart';
import '../widgets/budget_card.dart';
import '../widgets/bar_chart_widget.dart';

class StatisticsDetailPage extends StatelessWidget {
  final int month;
  final int year;
  final String monthName;

  const StatisticsDetailPage({super.key, required this.month, required this.year, required this.monthName});

  List<InventoryItem> get _items => AppData().inventory
      .where((e) => e.scannedAt.month == month && e.scannedAt.year == year)
      .toList();

  int get _total => _items.fold(0, (s, e) => s + e.price);

  int get _recommendedBudget {
    final Map<String, int> perMonth = {};
    for (final item in AppData().inventory) {
      if (item.scannedAt.month == month && item.scannedAt.year == year) continue;
      final key = '${item.scannedAt.year}-${item.scannedAt.month}';
      perMonth[key] = (perMonth[key] ?? 0) + item.price;
    }
    if (perMonth.isEmpty) return 0;
    final avg = perMonth.values.fold(0, (a, b) => a + b) ~/ perMonth.length;
    return (avg * 0.92).round();
  }

  Map<String, int> get _perCategory {
    final Map<String, int> r = {};
    for (final i in _items) r[i.category] = (r[i.category] ?? 0) + i.price;
    return r;
  }

  Map<String, int> get _perWeek {
    final r = {'Week 1': 0, 'Week 2': 0, 'Week 3': 0, 'Week 4': 0};
    for (final i in _items) {
      final w = 'Week ${((i.scannedAt.day - 1) ~/ 7).clamp(0, 3) + 1}';
      r[w] = r[w]! + i.price;
    }
    return r;
  }

  String _fmt(int v) => v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: AppColors.surface, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('$monthName $year', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: const Center(child: Text('Tidak ada data', style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary))),
    );

    final rec = _recommendedBudget;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Text('$monthName $year', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Total spending
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Spending', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white70)),
              const SizedBox(height: 4),
              Text('Rp${_fmt(_total)}', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 22, color: Colors.white)),
            ]),
          ),

          if (rec > 0) ...[
            const SizedBox(height: 12),
            BudgetCard(total: _total, recommended: rec),
          ],

          const SizedBox(height: 20),

          const Text('Spending per Kategori', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
            child: BarChartWidget(data: _perCategory),
          ),

          const SizedBox(height: 20),
          const Text('Ringkasan per Minggu', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
          const SizedBox(height: 12),
          ..._perWeek.entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(e.key, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              Text(e.value > 0 ? 'Rp${_fmt(e.value)}' : '-',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: e.value > 0 ? AppColors.primary : AppColors.textSecondary)),
            ]),
          )),
          const SizedBox(height: 80),
        ]),
      ),
    );
  }
}