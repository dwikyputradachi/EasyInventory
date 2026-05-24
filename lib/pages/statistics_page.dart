import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../data/app_data.dart';
import 'statistics_detail_page.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  final months = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedYear = DateTime.now().year;
  }

  List<int> get years {
    final dataYears = AppData().inventory.map((e) => e.scannedAt.year).toSet().toList();
    if (dataYears.isEmpty) dataYears.add(DateTime.now().year);
    dataYears.sort();
    return dataYears;
  }

  int totalMonth(int month) {
    return AppData().inventory
        .where((e) => e.scannedAt.month == month && e.scannedAt.year == selectedYear)
        .fold(0, (sum, e) => sum + e.price);
  }

  int get totalYear {
    return List.generate(12, (i) => totalMonth(i + 1))
        .fold(0, (sum, total) => sum + total);
  }

  int get activeMonthTotal => totalMonth(DateTime.now().month);

  String rupiah(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      children: [
        const Text(
          "Statistics",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Track your household spending pattern",
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),

        const SizedBox(height: 18),

        _summaryCard(),

        const SizedBox(height: 16),

        _yearChips(),

        const SizedBox(height: 18),

        const Text(
          "Monthly Spending",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        ...List.generate(12, (index) {
          final month = index + 1;
          final total = totalMonth(month);

          return _monthTile(months[index], month, total);
        }),
      ],
    );
  }

  Widget _summaryCard() {
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
              child: Icon(Icons.insights_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "This Month",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    "Rp ${rupiah(activeMonthTotal)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Total $selectedYear: Rp ${rupiah(totalYear)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _yearChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: years.map((year) {
          final selected = year == selectedYear;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('$year'),
              selected: selected,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) => setState(() => selectedYear = year),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _monthTile(String monthName, int month, int total) {
    final hasData = total > 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StatisticsDetailPage(
                month: month,
                year: selectedYear,
                monthName: monthName,
              ),
            ),
          );
        },
        leading: CircleAvatar(
          backgroundColor: hasData
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.textSecondary.withOpacity(0.10),
          child: Icon(
            Icons.calendar_month_outlined,
            color: hasData ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        title: Text(
          "$monthName $selectedYear",
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          hasData ? "Total Spending: Rp ${rupiah(total)}" : "No data available",
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }
}