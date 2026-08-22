import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class BiMOBackButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;

  const BiMOBackButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEnabled = onPressed != null;
    final iconColor = isEnabled
        ? AppColors.emeraldLight
        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);
    final textColor = isEnabled
        ? (isDark ? const Color(0xFFD6D8DE) : AppColors.lightTextPrimary)
        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);

    Color backgroundFor(Set<WidgetState> states) {
      if (states.contains(WidgetState.disabled)) {
        return isDark ? AppColors.darkSurface : AppColors.lightPanel;
      }
      if (states.contains(WidgetState.pressed)) {
        return isDark ? const Color(0xFF232733) : AppColors.lightPanelStrong;
      }
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return isDark ? const Color(0xFF20242D) : AppColors.lightPanel;
      }
      return isDark ? const Color(0xFF1A1D22) : AppColors.lightSurface;
    }

    BorderSide borderFor(Set<WidgetState> states) {
      final color = states.contains(WidgetState.disabled)
          ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
          : states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)
          ? (isDark ? const Color(0xFF424957) : AppColors.lightTextMuted)
          : (isDark ? const Color(0xFF343842) : AppColors.lightBorder);

      return BorderSide(color: color);
    }

    return TextButton.icon(
      onPressed: onPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(backgroundFor),
        side: WidgetStateProperty.resolveWith(borderFor),
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        minimumSize: WidgetStateProperty.all(const Size(0, 42)),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      icon: Icon(Icons.arrow_back_rounded, size: 20, color: iconColor),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodyMedium(
          isDark,
        ).copyWith(color: textColor, fontWeight: FontWeight.w600),
      ),
    );
  }
}
