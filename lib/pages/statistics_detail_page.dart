import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../data/app_data.dart';

class StatisticsDetailPage extends StatelessWidget {
  final int month;
  final int year;
  final String monthName;

  const StatisticsDetailPage({
    super.key,
    required this.month,
    required this.year,
    required this.monthName,
  });

  List<InventoryItem> get _items => AppData().inventory
      .where((e) => e.scannedAt.month == month && e.scannedAt.year == year)
      .toList();

  Map<String, int> get _spendingPerCategory {
    final Map<String, int> result = {};
    for (final item in _items) {
      result[item.category] = (result[item.category] ?? 0) + item.price;
    }
    return result;
  }

  // Spending per minggu (week 1–4)
  Map<String, int> get _spendingPerWeek {
    final Map<String, int> result = {'Week 1': 0, 'Week 2': 0, 'Week 3': 0, 'Week 4': 0};
    for (final item in _items) {
      final week = ((item.scannedAt.day - 1) ~/ 7).clamp(0, 3);
      final key = 'Week ${week + 1}';
      result[key] = result[key]! + item.price;
    }
    return result;
  }

  int get _total => _items.fold(0, (s, e) => s + e.price);

  String _formatRupiah(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final categories = _spendingPerCategory;
    final weeks = _spendingPerWeek;
    final hasData = _items.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('$monthName $year', style: const TextStyle(
          fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        )),
      ),
      body: hasData ? SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Total spending card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Spending', style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 13, color: Colors.white70,
                )),
                const SizedBox(height: 4),
                Text('Rp${_formatRupiah(_total)}', style: const TextStyle(
                  fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                  fontSize: 22, color: Colors.white,
                )),
              ]),
            ),

            const SizedBox(height: 20),

            // Bar chart per kategori
            if (categories.isNotEmpty) ...[
              const Text('Spending per Kategori', style: TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w600,
                fontSize: 14, color: AppColors.textPrimary,
              )),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface, borderRadius: BorderRadius.circular(12),
                ),
                child: _buildBarChart(categories),
              ),
              const SizedBox(height: 20),
            ],

            // Ringkasan per minggu
            const Text('Ringkasan per Minggu', style: TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w600,
              fontSize: 14, color: AppColors.textPrimary,
            )),
            const SizedBox(height: 12),
            ...weeks.entries.map((e) => _weekTile(e.key, e.value)),
          ],
        ),
      ) : const Center(
        child: Text('Tidak ada data di bulan ini',
            style: TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary)),
      ),
    );
  }

  Widget _buildBarChart(Map<String, int> data) {
    final maxVal = data.values.reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: data.entries.map((e) {
        final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
        return Column(children: [
          Text('Rp${_formatRupiah(e.value)}', style: const TextStyle(
              fontFamily: 'Poppins', fontSize: 9, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(
            width: 36,
            height: (80 * ratio).toDouble(),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 6),
          Text(e.key, style: const TextStyle(fontFamily: 'Poppins',
              fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ]);
      }).toList(),
    );
  }

  Widget _weekTile(String week, int total) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(week, style: const TextStyle(fontFamily: 'Poppins',
              fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text(
            total > 0 ? 'Rp${_formatRupiah(total)}' : '-',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                color: total > 0 ? AppColors.primary : AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}