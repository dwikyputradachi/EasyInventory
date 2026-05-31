import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BarChartWidget extends StatelessWidget {
  final Map<String, int> data;

  const BarChartWidget({super.key, required this.data});

  String _fmt(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.entries.map((entry) {
          final ratio = maxValue == 0 ? 0.0 : entry.value / maxValue;
          final height = 90 * ratio;

          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Rp${_fmt(entry.value)}',
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Container(
                  width: 28,
                  height: height < 8 ? 8 : height,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}