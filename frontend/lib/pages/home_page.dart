import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'dashboard_page.dart';
import 'inventory_page.dart';
import 'statistics_page.dart';
import 'profile_page.dart';
import 'scan_page.dart';
import 'notification_page.dart';
import 'shopping_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Tracks which pages sudah pernah dibuka — lazy init
  final Set<int> _visited = {0};

  void _openScan() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanPage()),
    );
    // Refresh dashboard setelah scan
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          "Easy Inventory",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationPage()),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Dashboard selalu ada
          DashboardPage(
            onOpenScan: _openScan,
            onOpenInventory: () => _goTo(1),
            onOpenShopping: () => _goTo(2),
          ),
          // Page lain hanya dibuild saat pertama kali dibuka
          _visited.contains(1) ? const InventoryPage()    : const SizedBox.shrink(),
          _visited.contains(2) ? const ShoppingListPage() : const SizedBox.shrink(),
          _visited.contains(3) ? const StatisticsPage()   : const SizedBox.shrink(),
          _visited.contains(4) ? const ProfilePage()      : const SizedBox.shrink(),
        ],
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              onPressed: _openScan,
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text("Scan"),
            )
          : null,
      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2))],
        ),
        child: Row(
          children: [
            _navItem(0, Icons.dashboard_outlined,    "Dashboard"),
            _navItem(1, Icons.inventory_2_outlined,  "Inventory"),
            _navItem(2, Icons.shopping_bag_outlined,  "List"),
            _navItem(3, Icons.bar_chart_outlined,    "Statistics"),
            _navItem(4, Icons.person_outline,        "Profile"),
          ],
        ),
      ),
    );
  }

  void _goTo(int index) {
    setState(() {
      _visited.add(index);
      _currentIndex = index;
    });
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _goTo(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4, width: active ? 26 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 8),
            Icon(icon, color: active ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.primary : AppColors.textSecondary,
            )),
          ],
        ),
      ),
    );
  }
}