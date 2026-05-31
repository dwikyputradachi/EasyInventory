import 'package:flutter/material.dart';
import '../constants/colors.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final List<Map<String, dynamic>> items = [
    {'name': 'Odol', 'qty': '1 pcs', 'priority': 'High', 'bought': false},
    {'name': 'Beras', 'qty': '5 kg', 'priority': 'High', 'bought': true},
    {'name': 'Telur', 'qty': '1 kg', 'priority': 'Medium', 'bought': false},
    {'name': 'Sabun Cuci', 'qty': '1 pcs', 'priority': 'Low', 'bought': false},
  ];

  void _toggleBought(int index) {
    setState(() => items[index]['bought'] = !items[index]['bought']);
  }

  void _showAddItemSheet() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    String priority = 'Medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            left: 18,
            right: 18,
            top: 18,
            bottom: MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Add Shopping Item",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: nameController,
                    decoration: _inputDecoration("Item name"),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: qtyController,
                    decoration: _inputDecoration("Quantity, e.g. 1 pcs"),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: priority,
                    decoration: _inputDecoration("Priority"),
                    items: const [
                      DropdownMenuItem(value: 'High', child: Text('High')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                    ],
                    onChanged: (value) {
                      setSheetState(() => priority = value!);
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        if (nameController.text.isEmpty) return;

                        setState(() {
                          items.add({
                            'name': nameController.text,
                            'qty': qtyController.text.isEmpty
                                ? '1 pcs'
                                : qtyController.text,
                            'priority': priority,
                            'bought': false,
                          });
                        });

                        Navigator.pop(context);
                      },
                      child: const Text("Save Item"),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needToBuy = items.where((item) => item['bought'] == false).toList();
    final boughtItems = items.where((item) => item['bought'] == true).toList();
    final progress = items.isEmpty ? 0.0 : boughtItems.length / items.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Shopping List",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Plan what you need before shopping",
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),

          _progressCard(boughtItems.length, items.length, progress),

          const SizedBox(height: 22),
          _sectionTitle("Need to Buy"),
          const SizedBox(height: 10),

          if (needToBuy.isEmpty)
            _emptyState("All items are bought 🎉")
          else
            ...needToBuy.map((item) {
              final realIndex = items.indexOf(item);
              return _shoppingTile(item, realIndex);
            }),

          if (boughtItems.isNotEmpty) ...[
            const SizedBox(height: 22),
            _sectionTitle("Purchased"),
            const SizedBox(height: 10),
            ...boughtItems.map((item) {
              final realIndex = items.indexOf(item);
              return _shoppingTile(item, realIndex);
            }),
          ],

          const SizedBox(height: 90),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: _showAddItemSheet,
        icon: const Icon(Icons.add),
        label: const Text("Add Item"),
      ),
    );
  }

  Widget _progressCard(int bought, int total, double progress) {
    return Card(
      elevation: 0,
      color: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.shopping_cart_outlined, color: Colors.white),
            const SizedBox(height: 12),
            Text(
              "$bought of $total items bought",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: progress,
              color: Colors.white,
              backgroundColor: Colors.white24,
              minHeight: 8,
              borderRadius: BorderRadius.circular(20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shoppingTile(Map<String, dynamic> item, int index) {
    final bought = item['bought'] == true;
    final color = _priorityColor(item['priority']);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Checkbox(
          value: bought,
          activeColor: AppColors.primary,
          onChanged: (_) => _toggleBought(index),
        ),
        title: Text(
          item['name'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: bought ? AppColors.textSecondary : AppColors.textPrimary,
            decoration: bought ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          item['qty'],
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            item['priority'],
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _emptyState(String text) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    if (priority == 'High') return AppColors.danger;
    if (priority == 'Medium') return AppColors.warning;
    return AppColors.textSecondary;
  }
}