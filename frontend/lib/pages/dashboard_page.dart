import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../data/app_data.dart';
import '../services/statistics_service.dart';
import '../services/shopping_list_service.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onOpenScan;
  final VoidCallback? onOpenInventory;
  final VoidCallback? onOpenShopping;

  const DashboardPage({
    super.key,
    this.onOpenScan,
    this.onOpenInventory,
    this.onOpenShopping,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int  _thisMonth = 0;
  int  _lastMonth = 0;
  bool _isLoading = true;

  int _shoppingTotal = 0;
  int _shoppingBought = 0;
  bool _isShoppingLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSpending();
    _fetchShoppingProgress();
  }

  Future<void> _fetchSpending() async {
    if (AppData().token.isEmpty) {         // ← tambah ini
      setState(() => _isLoading = false);
      return;
    }
    final res = await StatisticsService.getMonthlySpending(DateTime.now().year);
    if (res['status'] == 'success') {
      final monthly = List<Map<String, dynamic>>.from(res['data']['monthly'] ?? []);
      final now     = DateTime.now();

      int thisMonth = 0, lastMonth = 0;
      for (final e in monthly) {
        final num = e['month_num'] as int;
        final val = double.parse(e['total'].toString()).toInt();
        if (num == now.month)     thisMonth = val;
        if (num == now.month - 1) lastMonth = val;
      }

      setState(() {
        _thisMonth = thisMonth;
        _lastMonth = lastMonth;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }
  Future<void> _fetchShoppingProgress() async {
    try {
      if (AppData().token.isEmpty) {
        setState(() => _isShoppingLoading = false);
        return;
      }

      final lists = await ShoppingListService.getShoppingLists();

      int total = 0, bought = 0;
      for (final list in lists) {
        final items = List<Map<String, dynamic>>.from(list['items'] ?? []);
        for (final item in items) {
          total++;
          if (item['is_bought'].toString() == '1') bought++;
        }
      }

      setState(() {
        _shoppingTotal  = total;
        _shoppingBought = bought;
        _isShoppingLoading = false;
      });
    } catch (e) {
      setState(() => _isShoppingLoading = false);
    }
  }

  // Hitung persentase perubahan vs bulan lalu
  String get _spendingComparison {
    if (_lastMonth == 0) return 'No data last month';
    final diff    = _thisMonth - _lastMonth;
    final percent = ((diff / _lastMonth) * 100).abs().toStringAsFixed(0);
    return diff >= 0
        ? '$percent% higher than last month'
        : '$percent% lower than last month';
  }

  String _rupiah(int v) => v.toString()
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    final name = AppData().name.isNotEmpty ? AppData().name : 'there';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(name),
          const SizedBox(height: 18),
          _spendingCard(),
          const SizedBox(height: 12),
          _shoppingProgressCard(),
          const SizedBox(height: 16),
          Row(children: [
            _miniCard("Items",     "–",  Icons.inventory_2,          AppColors.primary),
            _miniCard("Low Stock", "–",  Icons.warning_amber_rounded, AppColors.warning),
            _miniCard("Expired",   "–",  Icons.timer_outlined,        AppColors.danger),
          ]),
          const SizedBox(height: 22),
          _title("Stock Health"),
          const SizedBox(height: 10),
          _stockHealthCard(),
          const SizedBox(height: 22),
          _title("Need Attention"),
          const SizedBox(height: 10),
          _attentionTile("Santan",    "Low stock, consider restocking",       Icons.inventory_2,    AppColors.warning),
          _attentionTile("Rice",      "Expired in 3 days",                    Icons.warning_amber,  AppColors.danger),
          _attentionTile("Toothpaste","Shopping list item not bought yet",     Icons.shopping_bag,   AppColors.primary),
          const SizedBox(height: 22),
          _title("Quick Actions"),
          const SizedBox(height: 10),
          Row(children: [
            _actionCard("Scan",     Icons.document_scanner_outlined, AppColors.primary, widget.onOpenScan),
            _actionCard("Add Item", Icons.add_box_outlined,          AppColors.primary, widget.onOpenInventory),
            _actionCard("Shopping", Icons.shopping_bag_outlined,     AppColors.primary, widget.onOpenShopping),
          ]),
          const SizedBox(height: 22),
          _title("Categories"),
          const SizedBox(height: 10),
          const Wrap(
            spacing: 10, runSpacing: 10,
            children: [
              _CategoryChip("Pantry",     Icons.kitchen,      Color(0xFFF59E0B)),
              _CategoryChip("Fresh Food", Icons.eco,          Color(0xFF22C55E)),
              _CategoryChip("Beverages",  Icons.local_drink,  Color(0xFF38BDF8)),
              _CategoryChip("Toiletries", Icons.spa,          Color(0xFF8B5CF6)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _header(String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Hi, $name 👋", style: const TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
          )),
          const SizedBox(height: 4),
          const Text("Let's manage your household smarter",
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ]),
        const CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: Icon(Icons.person_2_outlined, color: Colors.white),
        ),
      ],
    );
  }

  Widget _spendingCard() {
    return Card(
      color: AppColors.primary, elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(children: [
          const CircleAvatar(
            radius: 28, backgroundColor: Colors.white24,
            child: Icon(Icons.insights_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("Monthly Spending", style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            _isLoading
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text("Rp ${_rupiah(_thisMonth)}", style: const TextStyle(
                    color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700,
                  )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(_isLoading ? '...' : _spendingComparison,
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          ]),
        ]),
      ),
    );
  }

Widget _shoppingProgressCard() {
    final percent = _shoppingTotal == 0
        ? 0
        : ((_shoppingBought / _shoppingTotal) * 100).round();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: const Icon(
            Icons.shopping_bag_outlined,
            color: AppColors.primary,
          ),
        ),
        title: const Text(
          "Shopping Progress",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          _isShoppingLoading
              ? "Loading shopping progress..."
              : "$_shoppingBought of $_shoppingTotal items purchased",
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Text(
          _isShoppingLoading ? "..." : "$percent%",
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _miniCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ]),
        ),
      ),
    );
  }

  Widget _stockHealthCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: [
          _ProgressRow("Available Stock", 0.75, AppColors.primary),
          SizedBox(height: 14),
          _ProgressRow("Low Stock",       0.35, AppColors.warning),
          SizedBox(height: 14),
          _ProgressRow("Expired Soon",    0.25, AppColors.danger),
        ]),
      ),
    );
  }

  Widget _attentionTile(String title, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _actionCard(String title, IconData icon, Color color, VoidCallback? onTap) {
    return Expanded(
      child: Card(
        elevation: 0,
        color: color.withOpacity(0.10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(title, textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: color)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _title(String text) => Text(text, style: const TextStyle(
    fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
  ));
}

class _ProgressRow extends StatelessWidget {
  final String title;
  final double value;
  final Color  color;

  const _ProgressRow(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Text(title)),
      SizedBox(
        width: 120,
        child: LinearProgressIndicator(
          value: value, minHeight: 8,
          borderRadius: BorderRadius.circular(20),
          backgroundColor: color.withOpacity(0.15),
          color: color,
        ),
      ),
    ]);
  }
}

class _CategoryChip extends StatelessWidget {
  final String  title;
  final IconData icon;
  final Color   color;

  const _CategoryChip(this.title, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(title),
      backgroundColor: color.withOpacity(0.10),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
    );
  }
}