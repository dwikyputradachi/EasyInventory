import 'package:flutter/material.dart';
import '../constants/colors.dart';

class BudgetCard extends StatelessWidget {
  final int total;
  final int recommended;

  const BudgetCard({
    super.key,
    required this.total,
    required this.recommended,
  });

  bool get isOver => total > recommended;
  int get difference => (total - recommended).abs();

  double get progress {
    if (recommended == 0) return 0;
    return (total / recommended).clamp(0.0, 1.0);
  }

  String _fmt(int value) {
    return value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = isOver ? AppColors.danger : AppColors.primary;

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.savings_outlined, color: color),
                const SizedBox(width: 8),
                Text(
                  'Budget Recommendation',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              'Rp ${_fmt(recommended)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 4),

            const Text(
              'Based on previous monthly average',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 14),

            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(20),
              color: color,
              backgroundColor: color.withOpacity(0.12),
            ),

            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isOver
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline,
                    color: color,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isOver
                          ? 'Over recommendation by Rp ${_fmt(difference)}'
                          : 'Saved Rp ${_fmt(difference)} from recommendation',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}