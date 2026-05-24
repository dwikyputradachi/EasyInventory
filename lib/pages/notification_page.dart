import 'package:flutter/material.dart';
import '../constants/colors.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  static const notifications = [
    {
      'title': 'Rice',
      'message': 'Stock is low, consider restocking',
      'type': 'stock',
      'icon': Icons.inventory_2_outlined,
    },
    {
      'title': 'Milk',
      'message': 'Expires in 2 days',
      'type': 'expired',
      'icon': Icons.timer_outlined,
    },
    {
      'title': 'Toothpaste',
      'message': 'Still not bought from shopping list',
      'type': 'shopping',
      'icon': Icons.shopping_bag_outlined,
    },
    {
      'title': 'Monthly Spending',
      'message': 'Spending is higher than recommended budget',
      'type': 'budget',
      'icon': Icons.insights_outlined,
    },
  ];

  Color _color(String type) {
    if (type == 'expired') return AppColors.danger;
    if (type == 'stock') return AppColors.warning;
    if (type == 'shopping') return AppColors.primary;
    return AppColors.secondary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Need Attention',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Reminders to keep your household organized',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),

          ...notifications.map((item) {
            final color = _color(item['type'] as String);

            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(item['icon'] as IconData, color: color),
                ),
                title: Text(
                  item['title'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  item['message'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: color,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}