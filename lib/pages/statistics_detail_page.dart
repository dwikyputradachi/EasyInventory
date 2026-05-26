import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/statistics_service.dart';
import '../widgets/budget_card.dart';
import '../widgets/bar_chart_widget.dart';

class StatisticsDetailPage extends StatefulWidget {
  final int    month;
  final int    year;
  final String monthName;
  final int    recommendation;

  const StatisticsDetailPage({
    super.key,
    required this.month,
    required this.year,
    required this.monthName,
    required this.recommendation,
  });

  @override
  State<StatisticsDetailPage> createState() => _StatisticsDetailPageState();
}

class _StatisticsDetailPageState extends State<StatisticsDetailPage> {
  bool _isLoading = true;

  int                         _total       = 0;
  Map<String, int>            _perCategory = {};
  Map<String, int>            _perWeek     = {
    'Week 1': 0, 'Week 2': 0, 'Week 3': 0, 'Week 4': 0,
  };

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final res = await StatisticsService.getMonthlySpending(widget.year);
    if (res['status'] != 'success') {
      setState(() => _isLoading = false);
      return;
    }

    final data    = res['data'];
    final monthly = List<Map<String, dynamic>>.from(data['monthly'] ?? []);
    final cats    = List<Map<String, dynamic>>.from(data['per_category'] ?? []);

    // Cari total bulan ini dari response monthly
    final found = monthly.where((e) => e['month_num'] == widget.month).firstOrNull;
    final total = found != null ? double.parse(found['total'].toString()).toInt() : 0;

    // Per category — backend return semua kategori tahun ini, filter tidak perlu
    // karena per_category sudah aggregate per tahun, bukan per bulan
    // Kalau backend nanti support per bulan, ganti di sini
    final Map<String, int> perCat = {};
    for (final c in cats) {
      perCat[c['category']] = double.parse(c['total'].toString()).toInt();
    }

    setState(() {
      _total       = total;
      _perCategory = perCat;
      _isLoading   = false;
    });
  }

  String get _topCategory {
    if (_perCategory.isEmpty) return '-';
    final sorted = _perCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  bool get _overBudget => widget.recommendation > 0 && _total > widget.recommendation;

  String _rupiah(int v) => v.toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface, elevation: 0,
        title: Text('${widget.monthName} ${widget.year}',
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _total == 0
              ? const Center(child: Text('No spending data available',
                  style: TextStyle(color: AppColors.textSecondary)))
              : _content(),
    );
  }

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      children: [

        // Total card
        Card(
          elevation: 0, color: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              const CircleAvatar(radius: 28, backgroundColor: Colors.white24,
                  child: Icon(Icons.payments_outlined, color: Colors.white)),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Spending', style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('Rp ${_rupiah(_total)}', style: const TextStyle(
                  color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700,
                )),
              ]),
            ]),
          ),
        ),

        const SizedBox(height: 12),

        // Insight card
        Card(
          elevation: 0,
          color: (_overBudget ? AppColors.warning : AppColors.primary).withOpacity(0.10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: (_overBudget ? AppColors.warning : AppColors.primary).withOpacity(0.15),
                child: Icon(Icons.lightbulb_outline,
                    color: _overBudget ? AppColors.warning : AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(
                _overBudget
                    ? 'Your spending is above recommendation. Try reducing $_topCategory spending.'
                    : 'Your spending is still under control. Most expense comes from $_topCategory.',
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              )),
            ]),
          ),
        ),

        if (widget.recommendation > 0) ...[
          const SizedBox(height: 12),
          BudgetCard(total: _total, recommended: widget.recommendation),
        ],

        const SizedBox(height: 22),
        const Text('Spending by Category', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        )),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BarChartWidget(data: _perCategory),
          ),
        ),

        const SizedBox(height: 22),
        const Text('Weekly Summary', style: TextStyle(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
        )),
        const SizedBox(height: 10),
        ..._perWeek.entries.map((e) {
          final hasData = e.value > 0;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: hasData
                    ? AppColors.primary.withOpacity(0.12)
                    : AppColors.textSecondary.withOpacity(0.10),
                child: Icon(Icons.calendar_view_week_outlined,
                    color: hasData ? AppColors.primary : AppColors.textSecondary),
              ),
              title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: Text(
                hasData ? 'Rp ${_rupiah(e.value)}' : '-',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: hasData ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}