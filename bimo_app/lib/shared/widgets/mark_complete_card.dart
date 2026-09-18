import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class MarkCompleteCard extends StatelessWidget {
  final bool isCompleted;
  final ValueChanged<bool> onToggle;

  const MarkCompleteCard({
    super.key,
    required this.isCompleted,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth <= 360;
        final horizontalPadding = isNarrow ? 12.0 : 16.0;
        final gap = isNarrow ? 8.0 : 10.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Switch.adaptive(
                value: isCompleted,
              activeThumbColor: AppColors.emeraldLight,
                onChanged: onToggle,
              ),
              SizedBox(width: gap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCompleted
                          ? 'BUILD COMPLETED & ARCHIVED'
                          : 'ACTIVE BUILD IN PROGRESS',
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                      style: AppTypography.labelUppercase(
                        color: isCompleted
                            ? AppColors.emeraldLight
                            : AppColors.darkTextMuted,
                      ).copyWith(fontSize: isNarrow ? 10.5 : null),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isCompleted
                          ? 'Project marked complete in workspace'
                          : 'Toggle when all parts are acquired & assembled',
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                      softWrap: true,
                      style: AppTypography.bodySmall(isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
