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
  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  List<int> get _years {
    final years = AppData().inventory.map((e) => e.scannedAt.year).toSet().toList();
    if (years.isEmpty) years.add(DateTime.now().year);
    years.sort();
    return years;
  }

  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  int _totalForMonth(int month, int year) {
    return AppData().inventory
        .where((e) => e.scannedAt.month == month && e.scannedAt.year == year)
        .fold(0, (sum, e) => sum + e.price);
  }

  String _formatRupiah(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        // Tab tahun — langsung Row tanpa Container wrapper
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _years.map((year) {
                final selected = year == _selectedYear;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      '$year',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: selected ? AppColors.surface : AppColors.textSecondary,
                      ),
                    ),
                    selected: selected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.textSecondary.withOpacity(0.3),
                    ),
                    onSelected: (_) => setState(() => _selectedYear = year),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // List bulan
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: _months.length,
            itemBuilder: (context, i) {
              final month = i + 1;
              final total = _totalForMonth(month, _selectedYear);
              return _monthTile(_months[i], month, total);
            },
          ),
        ),
      ],
    );
  }

  Widget _monthTile(String monthName, int month, int total) {
    final hasData = total > 0;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StatisticsDetailPage(
            month: month,
            year: _selectedYear,
            monthName: monthName,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasData ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$monthName $_selectedYear',
              style: const TextStyle(
                fontFamily: 'Poppins', fontWeight: FontWeight.w700,
                fontSize: 15, color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasData ? 'Total Spending : Rp${_formatRupiah(total)}' : 'Tidak ada data',
              style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 13, color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}