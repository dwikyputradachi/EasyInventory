import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BarChartWidget extends StatelessWidget {
  final Map<String, int> data;
  const BarChartWidget({super.key, required this.data});

  String _fmt(int v) => v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVal = data.values.reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: data.entries.map((e) {
        final ratio = maxVal > 0 ? e.value / maxVal : 0.0;
        return Column(children: [
          Text('Rp${_fmt(e.value)}', style: const TextStyle(fontFamily: 'Poppins', fontSize: 9, color: AppColors.textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Container(width: 36, height: (80 * ratio).toDouble(), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Text(e.key, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ]);
      }).toList(),
    );
  }
}