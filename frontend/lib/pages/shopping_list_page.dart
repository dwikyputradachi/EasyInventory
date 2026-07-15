import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../services/shopping_list_service.dart';
import '../data/app_data.dart';
import 'package:quickalert/quickalert.dart';

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> shoppingLists = [];
  Map<String, dynamic>? selectedList;
  bool isLoading = true;
  int? idShoppingList;

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  Future<void> _loadShoppingList() async {
    try {
      setState(() => isLoading = true);

      final lists = await ShoppingListService.getShoppingLists();

      if (lists.isEmpty) {
        await ShoppingListService.createShoppingList("My Shopping List");

        final reload = await ShoppingListService.getShoppingLists();

        shoppingLists = List<Map<String, dynamic>>.from(reload);

        if (shoppingLists.isNotEmpty) {
          selectedList = shoppingLists.first;
          _loadSelectedList();
        }
      } else {
        shoppingLists = List<Map<String, dynamic>>.from(lists);

        selectedList ??= shoppingLists.first;

        if (!shoppingLists.contains(selectedList)) {
          selectedList = shoppingLists.first;
        }

        _loadSelectedList();
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String _monthName(int month) {
    const months = [
      '',
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    if (month < 1 || month > 12) return '-';
    return months[month];
  }

  void _loadSelectedList() {
    if (selectedList == null) return;

    idShoppingList = int.parse(selectedList!['id_shopping_list'].toString());

    final listItems = selectedList!['items'] ?? [];

    items = List<Map<String, dynamic>>.from(
      listItems.map((item) {
        return {
          'id_shopping_item': int.parse(item['id_shopping_item'].toString()),
          'name': item['name_item'],
          'qty': '${item['quantity']} ${item['unit']}',
          'quantity': int.parse(item['quantity'].toString()),
          'unit': item['unit'],
          'priority': item['priority'],
          'bought': item['is_bought'].toString() == '1',
        };
      }),
    );
  }

  Future<void> _toggleBought(int index) async {
    final oldValue = items[index]['bought'] == true;
    final newValue = !oldValue;

    setState(() {
      items[index]['bought'] = newValue;
    });

    try {
      await ShoppingListService.updateStatus(
        idShoppingItem: items[index]['id_shopping_item'],
        isBought: newValue,
      );
    } catch (e) {
      setState(() {
        items[index]['bought'] = oldValue;
      });

      _showError(e.toString());
    }
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
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const Text(
                    "Add Shopping Item",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
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
                    borderRadius: BorderRadius.circular(16),
                    items: const [
                      DropdownMenuItem(value: 'High', child: Text('High')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'Low', child: Text('Low')),
                    ],
                    onChanged: (value) {
                      setSheetState(() => priority = value!);
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) return;

                        if (idShoppingList == null) {
                          _showError('Shopping list not ready');
                          return;
                        }

                        final qtyText = qtyController.text.trim();

                        final quantity = _parseQuantity(qtyText);
                        final unit = _parseUnit(qtyText);

                        try {
                          await ShoppingListService.addItem(
                            idShoppingList: idShoppingList!,
                            nameItem: nameController.text.trim(),
                            quantity: quantity,
                            unit: unit,
                            priority: priority,
                          );

                          if (!mounted) return;

                          Navigator.pop(context);
                          await _loadShoppingList();
                          if (!mounted) return;
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.success,
                            title: 'Success',
                            text: 'Shopping item added successfully.',
                          );
                        } catch (e) {
                          _showError(e.toString());
                        }
                      },
                      child: const Text(
                        "Save Item",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
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

  int _parseQuantity(String value) {
    if (value.isEmpty) return 1;

    final parts = value.split(' ');
    return int.tryParse(parts.first) ?? 1;
  }

  String _parseUnit(String value) {
    if (value.isEmpty) return 'pcs';

    final parts = value.split(' ');

    if (parts.length >= 2) {
      return parts.sublist(1).join(' ');
    }

    return 'pcs';
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _loadShoppingList,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                children: [
                  const Text(
                    "Shopping List",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Plan what you need before shopping",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _monthDropdown(),

                  const SizedBox(height: 16),

                  _progressCard(boughtItems.length, items.length, progress),

                  const SizedBox(height: 26),

                  _sectionTitle("Need to Buy", needToBuy.length),
                  const SizedBox(height: 12),

                  if (needToBuy.isEmpty)
                    _emptyState(
                      icon: Icons.celebration_outlined,
                      text: "All items are bought 🎉",
                    )
                  else
                    ...needToBuy.map((item) {
                      final realIndex = items.indexOf(item);
                      return _shoppingTile(item, realIndex);
                    }),

                  if (boughtItems.isNotEmpty) ...[
                    const SizedBox(height: 26),
                    _sectionTitle("Purchased", boughtItems.length),
                    const SizedBox(height: 12),
                    ...boughtItems.map((item) {
                      final realIndex = items.indexOf(item);
                      return _shoppingTile(item, realIndex);
                    }),
                  ],

                  const SizedBox(height: 90),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onPressed: isLoading ? null : _showAddItemSheet,
        icon: const Icon(Icons.add),
        label: const Text("Add Item", style: TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  /// Modernized month/year selector for switching between shopping lists.
  Widget _monthDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButtonFormField<Map<String, dynamic>>(
          value: selectedList,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary),
          borderRadius: BorderRadius.circular(16),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
          ),
          items: shoppingLists.map((list) {
            final month = int.parse(list['month'].toString());
            final year = list['year'];

            return DropdownMenuItem(
              value: list,
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(
                    "${_monthName(month)} $year",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedList = value;
              _loadSelectedList();
            });
          },
        ),
      ),
    );
  }

  Widget _progressCard(int bought, int total, double progress) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.82)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Text(
                total == 0 ? '0%' : '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "$bought of $total items bought",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              color: Colors.white,
              backgroundColor: Colors.white.withOpacity(0.25),
              minHeight: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _shoppingTile(Map<String, dynamic> item, int index) {
    final bought = item['bought'] == true;
    final color = _priorityColor(item['priority']);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: bought ? Colors.grey.shade200 : AppColors.primary.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            Checkbox(
              value: bought,
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              onChanged: (_) => _toggleBought(index),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: bought ? AppColors.textSecondary : AppColors.textPrimary,
                        decoration: bought ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['qty'],
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item['priority'],
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: AppColors.primary.withOpacity(0.6)),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    if (priority == 'High') return AppColors.danger;
    if (priority == 'Medium') return AppColors.warning;
    return AppColors.textSecondary;
  }
}