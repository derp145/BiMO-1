import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';

class StoreMapVisual extends StatelessWidget {
  final String locationQuery;

  const StoreMapVisual({
    Key? key,
    this.locationQuery = 'Metro Manila, Philippines',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1218) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Grid & Map Vector Background Simulation
            Positioned.fill(
              child: CustomPaint(
                painter: MapGridPainter(isDark: isDark),
              ),
            ),

            // Store Pin 1: DigiSupply Warehouse
            Positioned(
              top: 60,
              left: 80,
              child: _buildPin(
                context,
                title: 'DigiSupply Warehouse',
                subtitle: 'Quezon City • In Stock',
                isHighlighted: true,
              ),
            ),

            // Store Pin 2: MakerStore PH
            Positioned(
              top: 140,
              right: 70,
              child: _buildPin(
                context,
                title: 'MakerStore PH Depot',
                subtitle: 'Manila • Next-Day Delivery',
                isHighlighted: false,
              ),
            ),

            // Store Pin 3: eGizmo Electronics
            Positioned(
              bottom: 40,
              left: 120,
              child: _buildPin(
                context,
                title: 'eGizmo Tech Hub',
                subtitle: 'Pasig City • 95% Match',
                isHighlighted: false,
              ),
            ),

            // Location Badge Header
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurface.withOpacity(0.9)
                      : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.emeraldLight,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      locationQuery,
                      style: AppTypography.bodySmall(isDark).copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPin(BuildContext context,
      {required String title,
      required String subtitle,
      required bool isHighlighted}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (isDark ? AppColors.darkSurface : Colors.white)
            : (isDark ? AppColors.darkPanel.withOpacity(0.95) : Colors.white.withOpacity(0.95)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isHighlighted ? AppColors.emeraldLight : AppColors.darkBorder,
          width: isHighlighted ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isHighlighted
                ? AppColors.emeraldLight.withOpacity(0.2)
                : Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isHighlighted ? AppColors.emeraldLight : AppColors.blueAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall(isDark).copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall(isDark).copyWith(
                  fontSize: 9,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MapGridPainter extends CustomPainter {
  final bool isDark;

  MapGridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.04)
          : Colors.black.withOpacity(0.04)
      ..strokeWidth = 1;

    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
