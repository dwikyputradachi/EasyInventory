import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../data/app_data.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  static const List<Map<String, dynamic>> _expiringItems = [
    {'name': 'Rice',       'expiry': 'Expired in 3 days'},
    {'name': 'Santan',     'expiry': 'Expired in 5 days'},
    {'name': 'Toothpaste', 'expiry': 'Expired in 7 days'},
  ];

  static const List<String> _categories = ['All Items', 'Pantry', 'Beverages', 'Toiletries'];

  @override
  Widget build(BuildContext context) {
    final data = AppData();
    final totalItems = data.inventory.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(children: [
            _statCard('Total\nItems', '$totalItems', AppColors.primary),
            const SizedBox(width: 12),
            _statCard('Low\nStock', '5', AppColors.warning),
            const SizedBox(width: 12),
            _statCard('Total\nItems', '$totalItems', AppColors.secondary),
          ]),

          const SizedBox(height: 20),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((label) {
                final selected = label == 'All Items';
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label, style: TextStyle(
                      fontFamily: 'Poppins', fontSize: 12,
                      color: selected ? AppColors.surface : AppColors.textSecondary,
                    )),
                    selected: selected,
                    onSelected: (_) {},
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 20),

          const Text("Item expiring soon!", style: TextStyle(
            fontFamily: 'Poppins', fontWeight: FontWeight.w600,
            fontSize: 15, color: AppColors.textPrimary,
          )),

          const SizedBox(height: 10),

          ..._expiringItems.map((item) => _expiringTile(item)),

          if (data.inventory.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text("Recently Added", style: TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.w600,
              fontSize: 15, color: AppColors.textPrimary,
            )),
            const SizedBox(height: 10),
            ...data.inventory.reversed.take(5).map((item) => _inventoryTile(item)),
          ],

          const SizedBox(height: 80), // padding FAB
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
        child: Column(children: [
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
              fontFamily: 'Poppins', color: color)),
          Text(label, style: const TextStyle(fontSize: 11, fontFamily: 'Poppins',
              color: AppColors.textSecondary), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _expiringTile(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item['name'], style: const TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            Text(item['expiry'], style: const TextStyle(fontFamily: 'Poppins',
                fontSize: 11, color: AppColors.textSecondary)),
          ]),
          const Icon(Icons.warning_amber_outlined, color: AppColors.warning),
        ],
      ),
    );
  }

  Widget _inventoryTile(InventoryItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(item.category, style: const TextStyle(fontFamily: 'Poppins',
                  fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(width: 10),
            Text(item.name, style: const TextStyle(fontFamily: 'Poppins',
                fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          ]),
          Text("Rp ${item.price}", style: const TextStyle(fontFamily: 'Poppins',
              fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}