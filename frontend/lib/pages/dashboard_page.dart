import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/api_service.dart';
import '../pages/notification_page.dart';
import '../data/app_data.dart';

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
  Map<String, dynamic>? dashboard;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    final result = await ApiService.getDashboard(AppData().userId);

    if (!mounted) return;

    setState(() {
      dashboard = result;
      isLoading = false;
    });
  }

  Future<void> refreshDashboard() async {
    setState(() {
      isLoading = true;
    });

    await loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final totalItems = dashboard?['total_items'] ?? 0;
    final lowStock = dashboard?['low_stock'] ?? 0;
    final expired = dashboard?['expired'] ?? 0;

    final notifications =
        dashboard?['notifications'] as List<dynamic>? ?? [];

    final previewNotifications =
        notifications.take(3).toList();

    return RefreshIndicator(
      onRefresh: refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(),
            const SizedBox(height: 18),

            _spendingCard(),
            const SizedBox(height: 12),

            _shoppingProgressCard(),
            const SizedBox(height: 16),

            Row(
              children: [
                _miniCard(
                  "Items",
                  "$totalItems",
                  Icons.inventory_2,
                  AppColors.primary,
                ),
                _miniCard(
                  "Low Stock",
                  "$lowStock",
                  Icons.warning_amber_rounded,
                  AppColors.warning,
                ),
                _miniCard(
                  "Expired",
                  "$expired",
                  Icons.timer_outlined,
                  AppColors.danger,
                ),
              ],
            ),

            const SizedBox(height: 22),
            _title("Stock Health"),
            const SizedBox(height: 10),
            _stockHealthCard(),

            const SizedBox(height: 22),
            _title("Need Attention"),
            const SizedBox(height: 10),

            if (previewNotifications.isEmpty)
              _emptyAttentionCard()
            else
              ...previewNotifications.map(
                (n) => _attentionTile(
                  n['title'] ?? '',
                  n['message'] ?? '',
                  n['type'] == 'expired'
                      ? Icons.timer_outlined
                      : Icons.warning_amber_rounded,
                  n['type'] == 'expired'
                      ? AppColors.danger
                      : AppColors.warning,
                ),
              ),

            const SizedBox(height: 8),

Align(
  alignment: Alignment.centerRight,
  child: TextButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const NotificationPage(),
        ),
      );
    },
    child: const Text(
      'View All',
      style: TextStyle(
        fontWeight: FontWeight.w700,
      ),
    ),
  ),
),
            const SizedBox(height: 22),
            _title("Quick Actions"),
            const SizedBox(height: 10),
            Row(
              children: [
                _actionCard(
                  "Scan",
                  Icons.document_scanner_outlined,
                  AppColors.primary,
                  widget.onOpenScan,
                ),
                _actionCard(
                  "Add Item",
                  Icons.add_box_outlined,
                  AppColors.primary,
                  widget.onOpenInventory,
                ),
                _actionCard(
                  "Shopping",
                  Icons.shopping_bag_outlined,
                  AppColors.primary,
                  widget.onOpenShopping,
                ),
              ],
            ),

            const SizedBox(height: 22),
            _title("Categories"),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
             children: const [
  _CategoryChip("Fresh Food", Icons.eco, Color(0xFF22C55E)),
  _CategoryChip("Pantry", Icons.kitchen, Color(0xFFF59E0B)),
  _CategoryChip("Beverages", Icons.local_drink, Color(0xFF38BDF8)),
  _CategoryChip("Toiletries", Icons.spa, Color(0xFF8B5CF6)),
  _CategoryChip("Household Items", Icons.home_outlined, Color(0xFF6366F1)),
  _CategoryChip("Others", Icons.category_outlined, Color(0xFF64748B)),
],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hi, ${AppData().name} 👋",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Let's manage your household smarter",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        CircleAvatar(
          backgroundColor: AppColors.primarySoft,
          child: Icon(Icons.person_2_outlined, color: Colors.white),
        ),
      ],
    );
  }

  Widget _spendingCard() {
    return Card(
      color: AppColors.primary,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Monthly Spending",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Rp 420.000",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "12% higher than last month",
                    style: TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _shoppingProgressCard() {
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
        subtitle: const Text(
          "5 of 8 items purchased",
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Text(
          "62%",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _miniCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 Widget _stockHealthCard() {
  final totalItems = dashboard?['total_items'] ?? 0;
  final lowStock = dashboard?['low_stock'] ?? 0;
  final expired = dashboard?['expired'] ?? 0;

  final healthy = totalItems - lowStock - expired;

  final healthyRatio = totalItems == 0 ? 0.0 : healthy / totalItems;
  final lowStockRatio = totalItems == 0 ? 0.0 : lowStock / totalItems;
  final expiredRatio = totalItems == 0 ? 0.0 : expired / totalItems;

  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Stock Health",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),

          _ProgressRow(
            "Available Stock ($healthy)",
            healthyRatio,
            AppColors.primary,
          ),
          const SizedBox(height: 14),

          _ProgressRow(
            "Low Stock ($lowStock)",
            lowStockRatio,
            AppColors.warning,
          ),
          const SizedBox(height: 14),

          _ProgressRow(
            "Expired ($expired)",
            expiredRatio,
            AppColors.danger,
          ),
        ],
      ),
    ),
  );
}

  Widget _attentionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _emptyAttentionCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No items need attention',
          style: TextStyle(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _actionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
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
            child: Column(
              children: [
                Icon(icon, color: color),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
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

class _ProgressRow extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const _ProgressRow(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title)),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            borderRadius: BorderRadius.circular(20),
            backgroundColor: color.withOpacity(0.15),
            color: color,
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _CategoryChip(this.title, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(title),
      backgroundColor: color.withOpacity(0.10),
      labelStyle: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}