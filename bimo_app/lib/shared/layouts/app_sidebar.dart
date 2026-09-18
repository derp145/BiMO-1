import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../features/projects/data/project_provider.dart';

class AppSidebar extends ConsumerWidget {
  final bool isExpanded;
  final VoidCallback onToggle;

  const AppSidebar({super.key, required this.isExpanded, required this.onToggle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = ref.watch(profileProvider);
    final currentRoute = GoRouterState.of(context).uri.toString();

    final navItems = [
      _NavItem(name: 'Dashboard', route: '/', icon: Icons.grid_view_rounded),
      _NavItem(
        name: 'New Project',
        route: '/wizard',
        icon: Icons.add_circle_outline_rounded,
      ),
      _NavItem(
        name: 'Saved Projects',
        route: '/saved',
        icon: Icons.bookmark_border_rounded,
      ),
      _NavItem(
        name: 'Settings',
        route: '/settings',
        icon: Icons.settings_outlined,
      ),
      _NavItem(
        name: 'Help & About',
        route: '/help',
        icon: Icons.help_outline_rounded,
      ),
    ];

    final sidebarWidth = isExpanded ? 250.0 : 80.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: sidebarWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(
          right: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header / Brand Logo
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.menu_rounded, size: 22),
                  onPressed: onToggle,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                  tooltip: 'Toggle Sidebar',
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSoft,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.emeraldSoftBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.build_circle_rounded,
                          color: AppColors.emeraldLight,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'BiMO',
                          style: AppTypography.headingMedium(isDark).copyWith(
                            color: AppColors.emeraldLight,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Nav Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isActive =
                    currentRoute == item.route ||
                    (item.route != '/' && currentRoute.startsWith(item.route));

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: InkWell(
                    onTap: () => context.go(item.route),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: isExpanded ? 16 : 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppColors.emeraldSoft
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? AppColors.emeraldSoftBorder
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: isExpanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Icon(
                            item.icon,
                            size: 20,
                            color: isActive
                                ? AppColors.emeraldLight
                                : (isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                item.name,
                                style: AppTypography.bodyMedium(isDark)
                                    .copyWith(
                                      fontWeight: isActive
                                          ? FontWeight.bold
                                          : FontWeight.w500,
                                      color: isActive
                                          ? AppColors.emeraldLight
                                          : (isDark
                                                ? AppColors.darkTextPrimary
                                                : AppColors.lightTextPrimary),
                                    ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // User Profile Footer
          InkWell(
            onTap: () => context.go('/settings'),
            child: Container(
              padding: const EdgeInsets.all(16),
              color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
              child: Row(
                mainAxisAlignment: isExpanded
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.emeraldSoft,
                    child: Text(
                      profile.displayName.isNotEmpty
                          ? profile.displayName[0].toUpperCase()
                          : 'B',
                      style: const TextStyle(
                        color: AppColors.emeraldLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isExpanded) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            profile.displayName,
                            style: AppTypography.bodySmall(isDark).copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Build Workspace',
                            style: AppTypography.bodySmall(isDark).copyWith(
                              fontSize: 10,
                              color: AppColors.emeraldLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String name;
  final String route;
  final IconData icon;

  _NavItem({required this.name, required this.route, required this.icon});
}
