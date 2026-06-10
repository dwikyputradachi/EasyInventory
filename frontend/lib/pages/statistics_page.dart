import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/statistics_service.dart';
import 'statistics_detail_page.dart';
import '../data/app_data.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  late int _selectedYear;
  bool _isLoading = true;

  // Data dari API
  List<Map<String, dynamic>> _monthly       = [];
  int                         _recommendation = 0;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (AppData().token.isEmpty) {        
    setState(() => _isLoading = false);
    return;
   }

    setState(() => _isLoading = true);
    final res = await StatisticsService.getMonthlySpending(_selectedYear);
    if (res['status'] == 'success') {
      final data = res['data'];
      setState(() {
        _monthly        = List<Map<String, dynamic>>.from(data['monthly'] ?? []);
        _recommendation = (data['recommendation'] ?? 0).toInt();
        _isLoading      = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // Cari total bulan tertentu dari list _monthly
  int _totalForMonth(int month) {
    final found = _monthly.where((e) => e['month_num'] == month).firstOrNull;
    return found != null ? double.parse(found['total'].toString()).toInt() : 0;
  }

  int get _totalYear => _monthly.fold(0, (sum, e) => sum + double.parse(e['total'].toString()).toInt());
  int get _thisMonthTotal => _totalForMonth(DateTime.now().month);

  String _rupiah(int value) => value.toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      children: [
        const Text("Statistics", style: TextStyle(
          fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        )),
        const SizedBox(height: 4),
        const Text("Track your household spending pattern",
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),

        const SizedBox(height: 18),
        _summaryCard(),
        const SizedBox(height: 16),
        _yearChips(),
        const SizedBox(height: 18),

        const Text("Monthly Spending", style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        )),
        const SizedBox(height: 10),

        if (_isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: AppColors.primary),
          ))
        else
          ...List.generate(12, (i) {
            final month = i + 1;
            final total = _totalForMonth(month);
            return _monthTile(_months[i], month, total);
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
        child: Row(children: [
          const CircleAvatar(
            radius: 28, backgroundColor: Colors.white24,
            child: Icon(Icons.insights_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("This Month", style: TextStyle(color: Colors.white70, fontSize: 12)),
            Text("Rp ${_rupiah(_thisMonthTotal)}", style: const TextStyle(
              color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700,
            )),
            const SizedBox(height: 6),
            Text("Total $_selectedYear: Rp ${_rupiah(_totalYear)}",
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
        ]),
      ),
    );
  }

  Widget _yearChips() {
    // Ambil tahun dari data + tahun sekarang
    final years = _monthly.map((e) {
      final parts = (e['month'] as String).split(' ');
      return int.tryParse(parts.last) ?? DateTime.now().year;
    }).toSet().toList();
    if (!years.contains(DateTime.now().year)) years.add(DateTime.now().year);
    years.sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: years.map((year) {
          final selected = year == _selectedYear;
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
              onSelected: (_) {
                setState(() => _selectedYear = year);
                _fetchData();
              },
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
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StatisticsDetailPage(
            month: month,
            year: _selectedYear,
            monthName: monthName,
            recommendation: _recommendation,
          )),
        ),
        leading: CircleAvatar(
          backgroundColor: hasData
              ? AppColors.primary.withOpacity(0.12)
              : AppColors.textSecondary.withOpacity(0.10),
          child: Icon(Icons.calendar_month_outlined,
              color: hasData ? AppColors.primary : AppColors.textSecondary),
        ),
        title: Text("$monthName $_selectedYear",
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        subtitle: Text(
          hasData ? "Total Spending: Rp ${_rupiah(total)}" : "No data available",
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }
}