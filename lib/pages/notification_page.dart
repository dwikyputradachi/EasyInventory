import 'package:flutter/material.dart';
import '../constants/colors.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  static const List<Map<String, dynamic>> _notifications = [
    {'name': 'Fish',    'status': 'Low Stock',        'detail': '1 pack remains',  'icon': Icons.set_meal},
    {'name': 'Meat',    'status': 'Expiring soon of', 'detail': '06 May 2024',     'icon': Icons.lunch_dining},
    {'name': 'Egg',     'status': 'Expiring soon of', 'detail': '06 May 2024',     'icon': Icons.egg_outlined},
    {'name': 'Orange',  'status': 'Low Stock',        'detail': '3 pack remains',  'icon': Icons.energy_savings_leaf_outlined},
    {'name': 'Spinach', 'status': 'Low Stock',        'detail': '3 pack remains',  'icon': Icons.grass},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppColors.textPrimary, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _notifications[index];
          final isLowStock = item['status'] == 'Low Stock';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item['icon'] as IconData,
                      color: AppColors.textPrimary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLowStock
                            ? item['status']
                            : '${item['status']} ${item['detail']}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLowStock)
                  Text(
                    item['detail'],
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}