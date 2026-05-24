import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/product_model.dart';

class AddProductPage extends StatefulWidget {
  final String categoryName;

  const AddProductPage({super.key, required this.categoryName});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameC = TextEditingController();
  final _qtyC = TextEditingController();
  final _priceC = TextEditingController();
  final _barcodeC = TextEditingController();

  String _unit = 'pcs';
  DateTime? _expiredDate;

  final units = const ['pcs', 'kg', 'gram', 'liter', 'ml', 'botol', 'bungkus'];

  @override
  void dispose() {
    _nameC.dispose();
    _qtyC.dispose();
    _priceC.dispose();
    _barcodeC.dispose();
    super.dispose();
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );

    if (picked != null) setState(() => _expiredDate = picked);
  }

  void _scanBarcode() {
    setState(() => _barcodeC.text = '8991234567890');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barcode scanner belum diimplementasi'),
        backgroundColor: AppColors.warning,
      ),
    );
  }

  void _saveProduct() {
    if (!_formKey.currentState!.validate()) return;

    if (_expiredDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal expired dulu'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameC.text.trim(),
      category: widget.categoryName,
      price: int.parse(_priceC.text.trim()),
      expiryDate: _expiredDate!,
      quantity: int.parse(_qtyC.text.trim()),
      unit: _unit,
      barcode: _barcodeC.text.trim().isEmpty ? null : _barcodeC.text.trim(),
    );

    Navigator.pop(context, product);
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
          icon: const Icon(Icons.arrow_back_ios_new,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Product',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Input Item',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add item to ${widget.categoryName}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),

          _barcodeBox(),
          const SizedBox(height: 20),

          Form(
            key: _formKey,
            child: Column(
              children: [
                _field(
                  controller: _nameC,
                  label: 'Product Name',
                  hint: 'Example: Fuji Apple',
                  icon: Icons.label_outline,
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _qtyC,
                        label: 'Qty',
                        hint: '0',
                        icon: Icons.inventory_2_outlined,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (int.tryParse(v) == null) return 'Number only';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: _unitDropdown()),
                  ],
                ),

                const SizedBox(height: 14),

                _field(
                  controller: _priceC,
                  label: 'Price',
                  hint: '0',
                  icon: Icons.price_change_outlined,
                  keyboardType: TextInputType.number,
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null,
                ),

                const SizedBox(height: 14),
                _datePicker(),

                const SizedBox(height: 14),

                _field(
                  controller: _barcodeC,
                  label: 'Barcode (Optional)',
                  hint: 'Input manually or scan above',
                  icon: Icons.qr_code_outlined,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saveProduct,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save Product',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _barcodeBox() {
    return InkWell(
      onTap: _scanBarcode,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
        ),
        child: const Column(
          children: [
            Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 34),
            SizedBox(height: 8),
            Text(
              'Scan Barcode',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'optional, you can also input manually',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _unitDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Unit'),
        DropdownButtonFormField<String>(
          value: _unit,
          decoration: _input('', Icons.straighten),
          items: units
              .map((u) => DropdownMenuItem(value: u, child: Text(u)))
              .toList(),
          onChanged: (v) => setState(() => _unit = v!),
        ),
      ],
    );
  }

  Widget _datePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Expired Date'),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  _expiredDate == null
                      ? 'Choose expired date'
                      : '${_expiredDate!.day}/${_expiredDate!.month}/${_expiredDate!.year}',
                  style: TextStyle(
                    color: _expiredDate == null
                        ? AppColors.textSecondary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: _input(hint, icon),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  InputDecoration _input(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    );
  }
}