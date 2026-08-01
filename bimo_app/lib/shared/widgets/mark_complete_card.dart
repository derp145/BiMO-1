import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class MarkCompleteCard extends StatelessWidget {
  final bool isCompleted;
  final ValueChanged<bool> onToggle;

  const MarkCompleteCard({
    Key? key,
    required this.isCompleted,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch.adaptive(
            value: isCompleted,
            activeColor: AppColors.emeraldLight,
            onChanged: onToggle,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCompleted ? 'BUILD COMPLETED & ARCHIVED' : 'ACTIVE BUILD IN PROGRESS',
                style: AppTypography.labelUppercase(
                  color: isCompleted ? AppColors.emeraldLight : AppColors.darkTextMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isCompleted ? 'Project marked complete in workspace' : 'Toggle when all parts are acquired & assembled',
                style: AppTypography.bodySmall(isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
