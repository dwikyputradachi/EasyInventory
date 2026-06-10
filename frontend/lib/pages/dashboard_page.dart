import 'package:flutter/material.dart';
import 'dart:io';

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
  bool _isSpendingLoading = true;

  int _thisMonth = 0;
  String _spendingComparison = 'No spending data yet';

  @override
  void initState() {
    super.initState();
    loadDashboard();
    loadMonthlySpending();
  }

  Future<void> loadDashboard() async {
    final result = await ApiService.getDashboard(AppData().userId);

    if (!mounted) return;

    setState(() {
      dashboard = result;
      isLoading = false;
    });
  }

  Future<void> loadMonthlySpending() async {
    try {
      setState(() {
        _isSpendingLoading = true;
      });

      final result = await ApiService.get(
        'statistics/monthly_spending.php?id_user=${AppData().userId}',
      );

      final data = result['data'];

      int thisMonth = 0;
      int lastMonth = 0;

      if (data is Map<String, dynamic>) {
        thisMonth = _toInt(
          data['this_month'] ??
              data['current_month'] ??
              data['total_this_month'] ??
              data['monthly_spending'] ??
              data['total'],
        );

        lastMonth = _toInt(
          data['last_month'] ??
              data['previous_month'] ??
              data['total_last_month'],
        );
      } else {
        thisMonth = _toInt(result['total']);
      }

      String comparison = 'No spending data last month';

      if (lastMonth > 0) {
        final diff = thisMonth - lastMonth;
        final percent = ((diff.abs() / lastMonth) * 100).round();

        if (diff > 0) {
          comparison = '$percent% higher than last month';
        } else if (diff < 0) {
          comparison = '$percent% lower than last month';
        } else {
          comparison = 'Same as last month';
        }
      } else if (thisMonth > 0) {
        comparison = 'Spending recorded this month';
      }

      if (!mounted) return;

      setState(() {
        _thisMonth = thisMonth;
        _spendingComparison = comparison;
        _isSpendingLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _thisMonth = 0;
        _spendingComparison = 'Failed to load spending';
        _isSpendingLoading = false;
      });
    }
  }

  Future<void> refreshDashboard() async {
    setState(() {
      isLoading = true;
      _isSpendingLoading = true;
    });

    await Future.wait([
      loadDashboard(),
      loadMonthlySpending(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final totalItems = _toInt(dashboard?['total_items']);
    final lowStock = _toInt(dashboard?['low_stock']);
    final expired = _toInt(dashboard?['expired']);

    final notifications = dashboard?['notifications'] as List<dynamic>? ?? [];
    final previewNotifications = notifications.take(3).toList();

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
                _CategoryChip(
                  "Household Items",
                  Icons.home_outlined,
                  Color(0xFF6366F1),
                ),
                _CategoryChip("Others", Icons.category_outlined, Color(0xFF64748B)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    final name = AppData().name.isNotEmpty ? AppData().name : 'User';
    final profileImagePath = AppData().profileImagePath;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hi, $name 👋",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Let's manage your household smarter",
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: AppColors.primarySoft,
          backgroundImage: profileImagePath.isNotEmpty
              ? FileImage(File(profileImagePath))
              : null,
          child: profileImagePath.isEmpty
              ? const Icon(
                  Icons.person_2_outlined,
                  color: Colors.white,
                )
              : null,
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Monthly Spending",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),

                  if (_isSpendingLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  else
                    Text(
                      "Rp ${_rupiah(_thisMonth)}",
                      style: const TextStyle(
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
                    child: Text(
                      _isSpendingLoading ? 'Loading...' : _spendingComparison,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shoppingProgressCard() {
    final progressData = dashboard?['shopping_progress'];

    int purchased = 0;
    int total = 0;

    if (progressData is Map<String, dynamic>) {
      purchased = _toInt(
        progressData['purchased'] ??
            progressData['completed'] ??
            progressData['checked'],
      );
      total = _toInt(
        progressData['total'] ??
            progressData['total_items'] ??
            progressData['all'],
      );
    } else {
      purchased = _toInt(dashboard?['shopping_purchased']);
      total = _toInt(dashboard?['shopping_total']);
    }

    final percent = total == 0 ? 0 : ((purchased / total) * 100).round();
    final subtitle = total == 0
        ? "No active shopping list"
        : "$purchased of $total items purchased";

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
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Text(
          "$percent%",
          style: const TextStyle(
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
    final totalItems = _toInt(dashboard?['total_items']);
    final lowStock = _toInt(dashboard?['low_stock']);
    final expired = _toInt(dashboard?['expired']);

    final healthy = (totalItems - lowStock - expired).clamp(0, totalItems);
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

  int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  String _rupiah(int value) {
    final text = value.toString();
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      final reverseIndex = text.length - i;

      buffer.write(text[i]);

      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}

class _ProgressRow extends StatelessWidget {
  final String title;
  final double value;
  final Color color;

  const _ProgressRow(this.title, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    final safeValue = value.clamp(0.0, 1.0).toDouble();

    return Row(
      children: [
        Expanded(child: Text(title)),
        SizedBox(
          width: 120,
          child: LinearProgressIndicator(
            value: safeValue,
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