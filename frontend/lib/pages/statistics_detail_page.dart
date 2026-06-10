import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/statistics_service.dart';
import '../widgets/budget_card.dart';
import '../widgets/bar_chart_widget.dart';
import '../services/receipt_history_service.dart  ';
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

  List<Map<String, dynamic>> _purchaseHistory = [];

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

    final history = await ReceiptHistoryService.getByMonth(
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
      _purchaseHistory = history;
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
          'Purchase History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        if (_purchaseHistory.isEmpty)
          const Text(
            'No purchase history available',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          )
        else
          ..._purchaseHistory.map((receipt) => _receiptCard(receipt)),
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

  Widget _receiptCard(Map<String, dynamic> receipt) {
    final items = List<Map<String, dynamic>>.from(receipt['items'] ?? []);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showReceiptDetail(receipt),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt['title'] ?? 'Receipt',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      receipt['date'] ?? '-',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      items.map((e) => e['name']).join(', '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Rp ${_rupiah(double.parse(receipt['total'].toString()).toInt())}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showReceiptDetail(Map<String, dynamic> receipt) {
    final items = List<Map<String, dynamic>>.from(receipt['items'] ?? []);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                receipt['title'] ?? 'Receipt',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                receipt['date'] ?? '-',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              ...items.map((item) {
                final qty = int.tryParse(item['quantity'].toString()) ?? 1;
                final price = double.parse(item['price'].toString()).toInt();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${item['name']} x$qty',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        'Rp ${_rupiah(price)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const Divider(height: 24),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total Spending',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    'Rp ${_rupiah(double.parse(receipt['total'].toString()).toInt())}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}