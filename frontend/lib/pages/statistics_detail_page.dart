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
  String _sortBy = 'spending'; // unchanged state, unchanged meaning

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

    final items = await StatisticsService.getItemHistory(
      year: widget.year,
      month: widget.month,
    );

    if (res['status'] != 'success') {
      setState(() => _isLoading = false);
      return;
    }

    final data = res['data'];

    final total = double.parse((data['month_total'] ?? 0).toString()).toInt();

    final cats = List<Map<String, dynamic>>.from(data['per_category'] ?? []);

    final Map<String, int> perCat = {};
    for (final c in cats) {
      perCat[c['category']] = double.parse(c['total'].toString()).toInt();
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

  // Sorting logic tidak diubah sama sekali.
  void _sortItems() {
    switch (_sortBy) {
      case 'qty':
        _items.sort(
          (a, b) => int.parse(b['total_qty'].toString())
              .compareTo(int.parse(a['total_qty'].toString())),
        );
        break;
      case 'name':
        _items.sort(
          (a, b) => a['item_name'].toString().compareTo(b['item_name'].toString()),
        );
        break;
      default:
        _items.sort(
          (a, b) => double.parse(b['total_spending'].toString())
              .compareTo(double.parse(a['total_spending'].toString())),
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
          BudgetCard(total: _total, recommended: widget.recommendation),
        ],

        const SizedBox(height: 24),
        const Text(
          'Spending by Category',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDecoration(),
          child: BarChartWidget(data: _perCategory),
        ),

        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Item History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (_items.isNotEmpty)
              Text(
                '${_items.length} items',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        if (_items.isNotEmpty) _sortChips(),
        const SizedBox(height: 12),

        if (_items.isEmpty)
          _emptyItemsState()
        else
          ..._items.asMap().entries.map(
                (entry) => _itemHistoryCard(entry.key + 1, entry.value),
              ),
      ],
    );
  }

  // Filter chips menggantikan DropdownButton kecil.
  // Hanya ganti tampilan — set _sortBy & panggil _sortItems() persis sama.
  Widget _sortChips() {
    final options = const [
      {'value': 'spending', 'label': 'Highest Spending'},
      {'value': 'qty', 'label': 'Highest Quantity'},
      {'value': 'name', 'label': 'A-Z'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((o) {
          final selected = _sortBy == o['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(o['label']!),
              selected: selected,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: selected
                    ? Colors.transparent
                    : AppColors.textSecondary.withOpacity(0.2),
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textSecondary,
              ),
              onSelected: (_) {
                setState(() {
                  _sortBy = o['value']!;
                  _sortItems();
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _itemHistoryCard(int rank, Map<String, dynamic> item) {
    final qty = item['total_qty'];
    final unitPrice = double.parse(item['unit_price'].toString()).toInt();
    final totalSpending =
        double.parse(item['total_spending'].toString()).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ranking badge
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? AppColors.primary.withOpacity(0.12)
                  : AppColors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '#$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: rank <= 3 ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Product icon
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Name + qty + unit price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['item_name'].toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Qty $qty • Rp ${_rupiah(unitPrice)}/unit',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Total spending — paling menonjol
          Text(
            'Rp ${_rupiah(totalSpending)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyItemsState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.textSecondary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No purchase history',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No items were purchased in ${widget.monthName} ${widget.year}.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _totalCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
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
    );
  }

  Widget _insightCard() {
    final color = _overBudget ? AppColors.warning : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(Icons.lightbulb_outline, color: color),
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
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}