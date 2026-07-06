import 'package:flutter/material.dart';

import '../constants/colors.dart';
import '../services/api_service.dart';
import 'add_product_page.dart';
import 'category_detail_page.dart';

class InventoryPage extends StatefulWidget {
  final String? initialCategory;
  const InventoryPage({super.key, this.initialCategory});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  List<dynamic> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';
  
  // KUNCI PERBAIKAN: Taruh flag di dalam State utama agar siklus hidupnya aman
  bool _hasAutoNavigated = false; 

  final Map<String, Map<String, dynamic>> _categoryStyle = {
    'Fresh Food':     {'icon': Icons.eco_outlined,              'color': const Color(0xFF22C55E)},
    'Pantry':         {'icon': Icons.kitchen_outlined,           'color': const Color(0xFFF59E0B)},
    'Beverages':      {'icon': Icons.local_drink_outlined,       'color': const Color(0xFF38BDF8)},
    'Toiletries':     {'icon': Icons.spa_outlined,               'color': const Color(0xFF8B5CF6)},
    'Household Items':{'icon': Icons.home_repair_service_outlined,'color': const Color(0xFF14B8A6)},
    'Others':         {'icon': Icons.category_outlined,          'color': const Color(0xFF64748B)},
  };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }
   @override
  void didUpdateWidget(covariant InventoryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialCategory != oldWidget.initialCategory) {
      _applyCategoryFilter(widget.initialCategory); 
    }
  }
  void _applyCategoryFilter(String? category) {
    setState(() {
      _searchQuery = category ?? ''; 
      _hasAutoNavigated = category != null;
    });
    
  }
  
  Future<void> _loadCategories() async {
    final data = await ApiService.getCategories();
    if (!mounted) return;
    setState(() {
      _categories = data;
      _isLoading = false;
    });

    if (!_hasAutoNavigated && widget.initialCategory != null && _categories.isNotEmpty) {
      final target = _categories.firstWhere(
        (c) => _categoryName(c as Map<String, dynamic>) == widget.initialCategory,
        orElse: () => null,
      );
      if (target != null && mounted) {
        _hasAutoNavigated = true; 
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openCategory(target as Map<String, dynamic>);
        });
      }
    }
  }

  String _categoryName(Map<String, dynamic> c) =>
      c['name_category']?.toString() ?? c['title']?.toString() ?? '';

  int _categoryId(Map<String, dynamic> c) =>
      int.tryParse(c['id_category'].toString()) ?? 0;

  int _itemsCount(Map<String, dynamic> c) =>
      int.tryParse(c['items_count'].toString()) ?? 0;

  String _itemsName(Map<String, dynamic> c) =>
      c['items_name']?.toString() ?? '';

  List<dynamic> get _filteredCategories {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _categories;
    return _categories.where((c) {
      final m = c as Map<String, dynamic>;
      return _categoryName(m).toLowerCase().contains(q) ||
          _itemsName(m).toLowerCase().contains(q);
    }).toList();
  }

  IconData _iconFor(String name) =>
      _categoryStyle[name]?['icon'] ?? Icons.category_outlined;

  Color _colorFor(String name) =>
      _categoryStyle[name]?['color'] ?? AppColors.primary;

  Future<void> _openCategory(Map<String, dynamic> category) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryDetailPage(
          categoryId: _categoryId(category),
          categoryName: _categoryName(category),
        ),
      ),
    );
    if (result == true) _loadCategories();
  }

  Future<void> _openAddItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddProductPage()),
    );
    if (result == true) _loadCategories();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _loadCategories,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 110),
            children: [
              const Text('Inventory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              const Text('Organize your household items by category', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 18),
              _searchBox(),
              const SizedBox(height: 18),
              if (_filteredCategories.isEmpty)
                _emptySearchState()
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredCategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 12,
                    crossAxisSpacing: 12, childAspectRatio: 1.15,
                  ),
                  itemBuilder: (context, index) {
                    final cat = _filteredCategories[index] as Map<String, dynamic>;
                    final name = _categoryName(cat);
                    return _CategoryCard(
                      title: name,
                      count: _itemsCount(cat),
                      icon: _iconFor(name),
                      color: _colorFor(name),
                      onTap: () => _openCategory(cat),
                    );
                  },
                ),
            ],
          ),
        ),
        Positioned(
          right: 16, bottom: 20,
          child: FloatingActionButton.extended(
            heroTag: 'inventory_add_item_fab',
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Item', style: TextStyle(color: Colors.white)),
            onPressed: _openAddItem,
          ),
        ),
      ],
    );
  }

  Widget _searchBox() {
    return TextField(
      onChanged: (v) => setState(() => _searchQuery = v),
      decoration: InputDecoration(
        hintText: 'Search item or category',
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: _searchQuery.isEmpty ? null : IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => setState(() => _searchQuery = ''),
        ),
        filled: true, fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _emptySearchState() {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(children: [
        Icon(Icons.search_off, size: 58, color: AppColors.textSecondary.withOpacity(0.45)),
        const SizedBox(height: 10),
        const Text('No item or category found', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CategoryCard({required this.title, required this.count, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0, color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.12), child: Icon(icon, color: color)),
            const Spacer(),
            Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Text('$count items', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
      ),
    );
  }
}