import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../features/projects/data/project_provider.dart';

class AppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  const AppHeader({
    Key? key,
    this.title = 'Build Intelligence Workspace',
    this.showMenuButton = false,
    this.onMenuPressed,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkSurface : AppColors.lightSurface)
            .withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            IconButton(
              tooltip: 'Open Navigation',
              icon: const Icon(Icons.menu_rounded, size: 22),
              onPressed: onMenuPressed,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
            const SizedBox(width: 6),
          ],

          Expanded(
            child: Text(
              title,
              style: AppTypography.headingMedium(isDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          IconButton(
            tooltip: 'Toggle Theme (Light / Dark)',
            icon: Icon(
              isDark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 22,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
            onPressed: () {
              ref.read(themeModeProvider.notifier).state =
                  isDark ? ThemeMode.light : ThemeMode.dark;
            },
          ),
        ],
      ),
    );
  }
}