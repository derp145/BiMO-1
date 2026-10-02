import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class AnimatedCheckbox extends StatelessWidget {
  final String label;
  final bool checked;
  final ValueChanged<bool> onChange;

  const AnimatedCheckbox({
    super.key,
    required this.label,
    required this.checked,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => onChange(!checked),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 2.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: checked ? AppColors.emerald : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                  color: checked
                      ? AppColors.emeraldLight
                      : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                  width: 1.5,
                ),
              ),
              child: checked
                  ? const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.black,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                style: AppTypography.bodyMedium(isDark).copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: checked ? TextDecoration.lineThrough : null,
                  color: checked
                      ? (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted)
                      : (isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
