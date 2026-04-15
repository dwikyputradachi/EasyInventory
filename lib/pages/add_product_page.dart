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
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _barcodeController = TextEditingController();
  String _selectedUnit = 'pcs';
  DateTime? _expiryDate;

  final List<String> _units = ['pcs', 'kg', 'gram', 'liter', 'ml', 'botol', 'bungkus', 'ikat', 'kotak', 'butir', 'batang'];

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _expiryDate = picked);
  }

  void _scanBarcode() {
    // TODO: integrasikan dengan paket mobile_scanner atau flutter_barcode_scanner
    // Untuk sekarang simulasi hasil scan
    setState(() => _barcodeController.text = '8991234567890');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan barcode belum diimplementasi. Silakan isi manual.', style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: AppColors.warning,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih tanggal expired dulu!', style: TextStyle(fontFamily: 'Poppins')),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final product = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      category: widget.categoryName,
      price: int.parse(_priceController.text.trim()) ?? 0,
      expiryDate: _expiryDate!,
      quantity: int.parse(_qtyController.text.trim()) ?? 0,
      unit: _selectedUnit,
      barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
    );

    Navigator.pop(context, product);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _barcodeController.dispose();
    super.dispose();
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
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Tambah Produk',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Scan Barcode Button
              GestureDetector(
                onTap: _scanBarcode,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), style: BorderStyle.solid),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 32),
                      SizedBox(height: 6),
                      Text(
                        'Scan Barcode',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      Text(
                        'atau isi form manual di bawah',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel('Nama Produk *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Contoh: Apel Fuji', Icons.label_outline),
                style: const TextStyle(fontFamily: 'Poppins'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama produk wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Kuantitas *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration('0', Icons.inventory_outlined),
                          style: const TextStyle(fontFamily: 'Poppins'),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                            if (int.tryParse(v) == null) return 'Angka saja';
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Satuan'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          value: _selectedUnit,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: AppColors.primary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          ),
                          style: const TextStyle(fontFamily: 'Poppins', color: AppColors.textPrimary, fontSize: 13),
                          items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                          onChanged: (v) => setState(() => _selectedUnit = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildLabel('Harga *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceController,
                decoration: _inputDecoration('0', Icons.price_change_outlined),
                style:  const TextStyle(fontFamily: 'Poppins'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Harga Wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              _buildLabel('Tanggal Expired *'),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 10),
                      Text(
                        _expiryDate == null
                            ? 'Pilih tanggal expired'
                            : '${_expiryDate!.day} / ${_expiryDate!.month} / ${_expiryDate!.year}',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          color: _expiryDate == null ? AppColors.textSecondary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildLabel('Barcode (Opsional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _barcodeController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Isi manual atau scan di atas', Icons.qr_code_outlined),
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    'Simpan Produk',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Colors.white, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontFamily: 'Poppins', color: AppColors.textSecondary, fontSize: 13),
      prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}