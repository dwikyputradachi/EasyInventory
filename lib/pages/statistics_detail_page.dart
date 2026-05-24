import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../data/app_data.dart';
import '../widgets/budget_card.dart';
import '../widgets/bar_chart_widget.dart';

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

  List<InventoryItem> get items => AppData().inventory
      .where((e) => e.scannedAt.month == month && e.scannedAt.year == year)
      .toList();

  int get total => items.fold(0, (sum, e) => sum + e.price);

  Map<String, int> get perCategory {
    final data = <String, int>{};
    for (final item in items) {
      data[item.category] = (data[item.category] ?? 0) + item.price;
    }
    return data;
  }

  Map<String, int> get perWeek {
    final data = {'Week 1': 0, 'Week 2': 0, 'Week 3': 0, 'Week 4': 0};

    for (final item in items) {
      final week = 'Week ${((item.scannedAt.day - 1) ~/ 7).clamp(0, 3) + 1}';
      data[week] = data[week]! + item.price;
    }

    return data;
  }

  int get recommendedBudget {
    final data = <String, int>{};

    for (final item in AppData().inventory) {
      if (item.scannedAt.month == month && item.scannedAt.year == year) continue;

      final key = '${item.scannedAt.year}-${item.scannedAt.month}';
      data[key] = (data[key] ?? 0) + item.price;
    }

    if (data.isEmpty) return 0;

    final avg = data.values.fold(0, (a, b) => a + b) ~/ data.length;
    return (avg * 0.92).round();
  }

  String get topCategory {
    if (perCategory.isEmpty) return '-';
    final sorted = perCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  String rupiah(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '$monthName $year',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: items.isEmpty ? _emptyState() : _content(),
    );
  }

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      children: [
        _totalCard(),

        const SizedBox(height: 12),
        _insightCard(),

        if (recommendedBudget > 0) ...[
          const SizedBox(height: 12),
          BudgetCard(total: total, recommended: recommendedBudget),
        ],

        const SizedBox(height: 22),
        _title('Spending by Category'),
        const SizedBox(height: 10),
        _chartCard(),

        const SizedBox(height: 22),
        _title('Weekly Summary'),
        const SizedBox(height: 10),
        ...perWeek.entries.map((e) => _weekTile(e.key, e.value)),
      ],
    );
  }

  Widget _totalCard() {
    return Card(
      elevation: 0,
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white24,
              child: Icon(Icons.payments_outlined, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Spending',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  'Rp ${rupiah(total)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightCard() {
    final overBudget = recommendedBudget > 0 && total > recommendedBudget;
    final color = overBudget ? AppColors.warning : AppColors.primary;

    return Card(
      elevation: 0,
      color: color.withOpacity(0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(Icons.lightbulb_outline, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                overBudget
                    ? 'Your spending is above recommendation. Try reducing $topCategory spending.'
                    : 'Your spending is still under control. Most expense comes from $topCategory.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chartCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: BarChartWidget(data: perCategory),
      ),
    );
  }

  Widget _weekTile(String title, int value) {
    final hasData = value > 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: hasData
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.textSecondary.withOpacity(0.10),
          child: Icon(
            Icons.calendar_view_week_outlined,
            color: hasData ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: Text(
          hasData ? 'Rp ${rupiah(value)}' : '-',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: hasData ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Text(
        'No spending data available',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _title(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}