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

  final pages = const [
    DashboardPage(),
    InventoryPage(),
    ShoppingListPage(),
    StatisticsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          "Easy Inventory",
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationPage(),
                ),
              );
            },
          ),
        ],
      ),

      body: pages[_currentIndex],

      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const ScanPage(),
            ),
          );
        },
        icon: const Icon(Icons.receipt_long_outlined),
        label: const Text("Scan"),
      )
          : null,

      bottomNavigationBar: Container(
        height: 70,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            _navItem(0, Icons.dashboard_outlined, "Dashboard"),
            _navItem(1, Icons.inventory_2_outlined, "Inventory"),
            _navItem(2, Icons.shopping_cart_outlined, "List"),
            _navItem(3, Icons.bar_chart_outlined, "Statistics"),
            _navItem(4, Icons.person_outline, "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final active = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 4,
              width: active ? 26 : 0,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 8),
            Icon(
              icon,
              color: active
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                active ? FontWeight.w600 : FontWeight.w400,
                color: active
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}