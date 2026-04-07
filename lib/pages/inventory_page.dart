import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'category_detail_page.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {'title': 'Fresh Food', 'count': 10, 'icon': Icons.kitchen},
    {'title': 'Pantry', 'count': 10, 'icon': Icons.shelves},
    {'title': 'Beverages', 'count': 10, 'icon': Icons.local_drink},
    {'title': 'Toiletries', 'count': 10, 'icon': Icons.soap},
    {'title': 'Households Items', 'count': 10, 'icon': Icons.home_repair_service},
    {'title': 'Others', 'count': 10, 'icon': Icons.category},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _CategoryCard(
          title: category['title'] as String,
          count: category['count'] as int,
          icon: category['icon'] as IconData,
          onTap: () {Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CategoryDetailPage(categoryName: category['title'] as String),
    ),
  );},
        );
      },
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              child: Icon(icon, color: AppColors.textPrimary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count items available in this category',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}