import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../projects/domain/models.dart';
import '../../projects/data/project_provider.dart';

class SavedProjectsScreen extends ConsumerStatefulWidget {
  const SavedProjectsScreen({super.key});

  @override
  ConsumerState<SavedProjectsScreen> createState() =>
      _SavedProjectsScreenState();
}

class _SavedProjectsScreenState extends ConsumerState<SavedProjectsScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(projectsProvider.notifier).cleanupExpiredTrash();
  }

  int _trashDaysRemaining(ProjectModel project) {
    final deletedAt = project.deletedAt;
    if (deletedAt == null) return trashRetentionDays;

    final expiresAt = deletedAt.add(trashRetentionDuration);
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.inMicroseconds <= 0) return 0;

    final fullDays = remaining.inDays;
    final hasPartialDay =
        remaining.inMicroseconds % Duration.microsecondsPerDay != 0;
    final days = fullDays + (hasPartialDay ? 1 : 0);
    return days.clamp(1, trashRetentionDays).toInt();
  }

  Widget _buildTrashRetentionNotice(ProjectModel project, bool isDark) {
    final daysRemaining = _trashDaysRemaining(project);
    final dayLabel = daysRemaining == 1 ? 'day' : 'days';
    final isNearDeletion = daysRemaining <= 3;
    final textColor = isNearDeletion
        ? AppColors.orangeWarning
        : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.orangeSoft,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: 16,
            color: isNearDeletion ? AppColors.orangeWarning : textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Permanently deletes in $daysRemaining $dayLabel',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodySmall(isDark).copyWith(color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(ProjectModel project, bool isHard) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHard ? 'Permanently Delete?' : 'Move to Trash Archive?'),
        content: Text(
          isHard
              ? 'Are you sure you want to permanently delete "${project.title}"? This cannot be undone.'
              : 'Are you sure you want to move "${project.title}" to the Trash Archive? It can be restored for 15 days.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: isHard
                ? ElevatedButton.styleFrom(
                    backgroundColor: AppColors.redAlert,
                    foregroundColor: Colors.white,
                  )
                : ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldSoft,
                    foregroundColor: AppColors.emeraldLight,
                  ),
            onPressed: () {
              if (isHard) {
                ref
                    .read(projectsProvider.notifier)
                    .hardDeleteProject(project.id);
              } else {
                ref
                    .read(projectsProvider.notifier)
                    .softDeleteProject(project.id);
              }
              Navigator.of(context).pop();
            },
            child: Text(isHard ? 'Permanently Delete' : 'Move to Trash'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsState = ref.watch(projectsProvider);
    final activeTab = projectsState.activeTab;

    // Filter into Active Projects vs Trash
    final activeProjects = projectsState.projects
        .where((p) => p.deletedAt == null)
        .toList();
    final trashProjects = projectsState.projects
        .where((p) => p.deletedAt != null)
        .toList();
    final displayProjects = activeTab == 'trash'
        ? trashProjects
        : activeProjects;

    return AppScaffold(
      title: 'Saved Projects & Builds',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Projects',
                  style: AppTypography.displayMedium(isDark),
                ),
                const SizedBox(height: 6),
                Text(
                  'Click any project below to open its editable project planner & procurement tracker.',
                  style: AppTypography.bodyMedium(isDark),
                ),
                const SizedBox(height: 24),

                // Navigation Tabs ("Projects", "Trash Archive")
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _TabButton(
                        label: 'Projects (${activeProjects.length})',
                        icon: Icons.folder_open_rounded,
                        selected: activeTab != 'trash',
                        activeColor: AppColors.emeraldLight,
                        onTap: () => ref
                            .read(projectsProvider.notifier)
                            .setActiveTab('engineering'),
                      ),
                      const SizedBox(width: 4),
                      _TabButton(
                        label: 'Trash (${trashProjects.length})',
                        icon: Icons.delete_outline_rounded,
                        selected: activeTab == 'trash',
                        activeColor: AppColors.redAlert,
                        onTap: () => ref
                            .read(projectsProvider.notifier)
                            .setActiveTab('trash'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Projects List / Empty State
                if (displayProjects.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(48),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          activeTab == 'trash'
                              ? Icons.delete_outline_rounded
                              : Icons.folder_open_rounded,
                          size: 48,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          activeTab == 'trash'
                              ? 'Trash Archive is Empty'
                              : 'No Saved Projects Yet',
                          style: AppTypography.headingLarge(isDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          activeTab == 'trash'
                              ? 'Deleted projects will stay here for 15 days before being permanently deleted.'
                              : 'Create a new build to save your project planner and Bill of Materials (BOM) tracker.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium(isDark),
                        ),
                        const SizedBox(height: 24),
                        if (activeTab != 'trash')
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emerald,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () => context.go('/wizard'),
                            child: const Text(
                              'Start a Project',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 700;

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isWide ? 3 : 1,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.9,
                        ),
                        itemCount: displayProjects.length,
                        itemBuilder: (context, idx) {
                          final proj = displayProjects[idx];
                          final isTrash = activeTab == 'trash';

                          return Card(
                            child: InkWell(
                              onTap: isTrash
                                  ? null
                                  : () {
                                      ref
                                          .read(projectsProvider.notifier)
                                          .setActiveProject(proj);
                                      context.go('/planner');
                                    },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.emeraldSoft,
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.developer_board_rounded,
                                            color: AppColors.emeraldLight,
                                            size: 22,
                                          ),
                                        ),
                                        if (proj.isOptimized)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.emeraldSoft,
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'AI OPTIMIZED',
                                              style:
                                                  AppTypography.labelUppercase(),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      proj.title,
                                      style: AppTypography.headingMedium(
                                        isDark,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Created ${proj.createdAt.day}/${proj.createdAt.month}/${proj.createdAt.year}',
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                    if (isTrash) ...[
                                      const SizedBox(height: 12),
                                      _buildTrashRetentionNotice(proj, isDark),
                                    ],
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'ESTIMATED COST',
                                              style:
                                                  AppTypography.labelUppercase(),
                                            ),
                                            Text(
                                              '₱${proj.finalCost.toStringAsFixed(0)}',
                                              style:
                                                  AppTypography.headingMedium(
                                                    isDark,
                                                  ).copyWith(
                                                    color:
                                                        AppColors.emeraldLight,
                                                  ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              'BILL OF MATERIALS',
                                              style:
                                                  AppTypography.labelUppercase(),
                                            ),
                                            Text(
                                              '${proj.partsCount}',
                                              style:
                                                  AppTypography.headingMedium(
                                                    isDark,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    if (isTrash) ...[
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              AppColors.emeraldSoft,
                                          foregroundColor:
                                              AppColors.emeraldLight,
                                          minimumSize: const Size.fromHeight(
                                            40,
                                          ),
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(projectsProvider.notifier)
                                              .restoreProject(proj.id);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Project Restored!',
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.restore_rounded,
                                          size: 16,
                                        ),
                                        label: const Text('Restore'),
                                      ),
                                      const SizedBox(height: 6),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: AppColors.redAlert,
                                          minimumSize: const Size.fromHeight(
                                            36,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _showDeleteDialog(proj, true),
                                        child: const Text('Permanently Delete'),
                                      ),
                                    ] else ...[
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.emerald,
                                          foregroundColor: Colors.black,
                                          minimumSize: const Size.fromHeight(
                                            40,
                                          ),
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(projectsProvider.notifier)
                                              .setActiveProject(proj);
                                          context.go('/planner');
                                        },
                                        icon: const Icon(
                                          Icons.architecture_rounded,
                                          size: 18,
                                        ),
                                        label: const Text(
                                          'Open Plan & Tracker',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextButton(
                                        style: TextButton.styleFrom(
                                          foregroundColor: isDark
                                              ? AppColors.darkTextMuted
                                              : AppColors.lightTextMuted,
                                          minimumSize: const Size.fromHeight(
                                            36,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _showDeleteDialog(proj, false),
                                        child: const Text(
                                          'Move to Trash Archive',
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(
                            duration: 250.ms,
                            delay: (idx * 50).ms,
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.darkSurface : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: selected
                  ? activeColor
                  : (isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodySmall(isDark).copyWith(
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected
                    ? (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary)
                    : (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
