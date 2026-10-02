import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class BomoAssistant extends StatelessWidget {
  final String title;
  final String message;

  const BomoAssistant({super.key, this.title = 'BiMO', required this.message});

  @override
  Widget build(BuildContext meContext) {
    final isDark = Theme.of(meContext).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A8A5F) : AppColors.emerald,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.emeraldLight.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BiMO Avatar Icon Container
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: const Center(
              child: Icon(
                Icons.smart_toy_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(width: 14),

          // Speech Bubble
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.labelUppercase(
                          color: isDark
                              ? AppColors.emeraldLight
                              : AppColors.emerald,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message,
                        style: AppTypography.bodyMedium(isDark).copyWith(
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : const Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0);
  }
}
