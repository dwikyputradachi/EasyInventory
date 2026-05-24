import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'category_detail_page.dart';

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {
      'title': 'Fresh Food',
      'count': 10,
      'icon': Icons.eco_outlined,
      'color': Color(0xFF22C55E),
    },
    {
      'title': 'Pantry',
      'count': 10,
      'icon': Icons.kitchen_outlined,
      'color': Color(0xFFF59E0B),
    },
    {
      'title': 'Beverages',
      'count': 10,
      'icon': Icons.local_drink_outlined,
      'color': Color(0xFF38BDF8),
    },
    {
      'title': 'Toiletries',
      'count': 10,
      'icon': Icons.spa_outlined,
      'color': Color(0xFF8B5CF6),
    },
    {
      'title': 'Household Items',
      'count': 10,
      'icon': Icons.home_repair_service_outlined,
      'color': Color(0xFF14B8A6),
    },
    {
      'title': 'Others',
      'count': 10,
      'icon': Icons.category_outlined,
      'color': Color(0xFF64748B),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
      children: [
        const Text(
          "Inventory",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          "Organize your household items by category",
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(height: 18),

        TextField(
          decoration: InputDecoration(
            hintText: "Search item or category",
            prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 18),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
          ),
          itemBuilder: (context, index) {
            final category = _categories[index];

            return _CategoryCard(
              title: category['title'],
              count: category['count'],
              icon: category['icon'],
              color: category['color'],
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryDetailPage(
                      categoryName: category['title'],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "$count items",
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}