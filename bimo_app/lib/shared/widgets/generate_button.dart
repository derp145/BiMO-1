import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';

class GenerateButton extends StatelessWidget {
  final bool disabled;
  final VoidCallback onPressed;
  final String label;

  const GenerateButton({
    super.key,
    this.disabled = false,
    required this.onPressed,
    this.label = 'Generate Bill of Materials & Architecture',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: disabled ? AppColors.darkPanel : AppColors.emerald,
          foregroundColor: disabled ? AppColors.darkTextMuted : Colors.black,
          elevation: disabled ? 0 : 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          shadowColor: AppColors.emeraldLight.withValues(alpha: 0.4),
        ),
        onPressed: disabled ? null : onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bolt_rounded, size: 20),
            const SizedBox(width: 8),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
