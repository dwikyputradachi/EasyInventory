import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BudgetCard extends StatelessWidget {
  final int total;
  final int recommended;

  const BudgetCard({super.key, required this.total, required this.recommended});

  String _fmt(int v) => v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  bool get _isOver => total > recommended;
  int get _selisih => (total - recommended).abs();
  double get _ratio => (recommended > 0 ? total / recommended : 0.0).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final color = _isOver ? AppColors.danger : AppColors.primary;
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.savings_outlined, color: color, size: 18),
          const SizedBox(width: 6),
          Text('Rekomendasi Budget', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13, color: color)),
        ]),
        const SizedBox(height: 10),
        Text('Rp${_fmt(recommended)}', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 20, color: _isOver ? AppColors.danger : AppColors.textPrimary)),
        const SizedBox(height: 4),
        const Text('Berdasarkan rata-rata bulan sebelumnya', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary)),
        const SizedBox(height: 12),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(children: [
            Container(height: 8, color: AppColors.background),
            FractionallySizedBox(
              widthFactor: _ratio,
              child: Container(height: 8, color: _isOver ? AppColors.danger : AppColors.primary),
            ),
          ]),
        ),
        const SizedBox(height: 6),

        // Warning / hemat
        if (_isOver)
          _banner('Pengeluaran melebihi rekomendasi Rp${_fmt(_selisih)}. Coba lebih hemat!', AppColors.danger)
        else
          Text('Hemat Rp${_fmt(_selisih)} dari rekomendasi', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.primary)),
      ]),
    );
  }

  Widget _banner(String msg, Color color) => Container(
    margin: const EdgeInsets.only(top: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Icon(Icons.warning_amber_rounded, color: color, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: color))),
    ]),
  );
}