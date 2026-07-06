import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/statistics_service.dart';
import '../widgets/budget_card.dart';
import '../widgets/bar_chart_widget.dart';
import '../data/app_data.dart';

class StatisticsDetailPage extends StatefulWidget {
  final int month;
  final int year;
  final String monthName;
  final int recommendation;
  

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

  int _total = 0;
  Map<String, int> _perCategory = {};

  List<Map<String, dynamic>> _items = [];
  String _sortBy = 'spending';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final res = await StatisticsService.getMonthlySpending(
      widget.year,
      month: widget.month,
    );

    final items =
    await StatisticsService.getItemHistory(
      year: widget.year,
      month: widget.month,
    );
    if (res['status'] != 'success') {
      setState(() => _isLoading = false);
      return;
    }

    final data = res['data'];

    final total = double.parse(
      (data['month_total'] ?? 0).toString(),
    ).toInt();

    final cats = List<Map<String, dynamic>>.from(
      data['per_category'] ?? [],
    );

    final Map<String, int> perCat = {};
    for (final c in cats) {
      perCat[c['category']] = double.parse(
        c['total'].toString(),
      ).toInt();
    }

    setState(() {
      _total = total;
      _perCategory = perCat;
      _isLoading = false;
      _items = items;
      _sortItems();
    });
  }

  String get _topCategory {
    if (_perCategory.isEmpty) return '-';

    final sorted = _perCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }

  bool get _overBudget {
    return widget.recommendation > 0 && _total > widget.recommendation;
  }

  String _rupiah(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
          (match) => '${match[1]}.',
    );
  }
  void _sortItems() {
    switch (_sortBy) {
      case 'qty':
        _items.sort(
          (a, b) => int.parse(
            b['total_qty'].toString(),
          ).compareTo(
            int.parse(a['total_qty'].toString()),
          ),
        );
        break;

      case 'name':
        _items.sort(
          (a, b) => a['item_name']
              .toString()
              .compareTo(
                b['item_name'].toString(),
              ),
        );
        break;

      default:
        _items.sort(
          (a, b) => double.parse(
            b['total_spending'].toString(),
          ).compareTo(
            double.parse(
              a['total_spending'].toString(),
            ),
          ),
        );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '${widget.monthName} ${widget.year}',
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
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      )
          : _total == 0
          ? const Center(
        child: Text(
          'No spending data available',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      )
          : _content(),
    );
  }

  Widget _content() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      children: [
        _totalCard(),
        const SizedBox(height: 12),
        _insightCard(),

        if (widget.recommendation > 0 && AppData().budgetRecommendationEnabled) ...[
          const SizedBox(height: 12),
          BudgetCard(
            total: _total,
            recommended: widget.recommendation,
          ),
        ],

        const SizedBox(height: 22),
        const Text(
          'Spending by Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BarChartWidget(data: _perCategory),
          ),
        ),

        const SizedBox(height: 22),
        const Text(
          'Item History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            DropdownButton<String>(
              value: _sortBy,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(
                  value: 'spending',
                  child: Text('Highest Spending'),
                ),
                DropdownMenuItem(
                  value: 'qty',
                  child: Text('Highest Quantity'),
                ),
                DropdownMenuItem(
                  value: 'name',
                  child: Text('A-Z'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                  _sortItems();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_items.isEmpty)
          const Text(
            'No purchase history available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          )
        else
          ..._items.map(
          (item) => Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    AppColors.primary.withOpacity(0.12),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                ),
              ),
              title: Text(
                item['item_name'],
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                "Qty ${item['total_qty']} • Rp ${_rupiah(double.parse(item['unit_price'].toString()).toInt())}",
              ),
              trailing: Text(
                "Rp ${_rupiah(double.parse(item['total_spending'].toString()).toInt())}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _totalCard() {
    return Card(
      elevation: 0,
      color: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white24,
              child: Icon(
                Icons.payments_outlined,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Spending',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Rp ${_rupiah(_total)}',
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
    final color = _overBudget ? AppColors.warning : AppColors.primary;

    return Card(
      elevation: 0,
      color: color.withOpacity(0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(
                Icons.lightbulb_outline,
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _overBudget
                    ? 'Your spending is above recommendation. Try reducing $_topCategory spending.'
                    : 'Your spending is still under control. Most expense comes from $_topCategory.',
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
}