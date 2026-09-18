import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/bomo_assistant.dart';
import '../../projects/data/project_provider.dart';
import '../../projects/domain/models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    final projectsState = ref.watch(projectsProvider);

    final activeProjects = projectsState.projects
        .where((project) => project.deletedAt == null)
        .toList();

    final completedProjects = activeProjects
        .where((project) => project.isCompleted)
        .toList();

    final inProgressProjects = activeProjects
        .where((project) => !project.isCompleted)
        .toList();

    final totalBomItems = activeProjects.fold<int>(
      0,
      (total, project) => total + project.partsCount,
    );

    final recentProjects = activeProjects.take(4).toList();

    final pagePadding = isMobile ? 16.0 : 24.0;

    return AppScaffold(
      title: 'Project Dashboard',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(pagePadding),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // =========================================================
                // BIMO ASSISTANT
                // =========================================================
                BomoAssistant(
                  message: inProgressProjects.isEmpty
                      ? 'Welcome back! Your workspace is ready. Start a new project whenever you have an idea to build.'
                      : 'Welcome back! You have ${inProgressProjects.length} project${inProgressProjects.length == 1 ? '' : 's'} in progress. Keep building!',
                ).animate().fadeIn(duration: 250.ms),

                const SizedBox(height: 32),

                // =========================================================
                // PROJECT OVERVIEW
                // =========================================================
                Text(
                  'Project Overview',
                  style: AppTypography.displayMedium(
                    isDark,
                  ).copyWith(fontSize: isMobile ? 26 : null),
                ),

                const SizedBox(height: 6),

                Text(
                  'A quick summary of your BiMO workspace.',
                  style: AppTypography.bodyMedium(isDark),
                ),

                const SizedBox(height: 20),

                LayoutBuilder(
                  builder: (context, constraints) {
                    if (isMobile) {
                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Active Builds',
                                  value: '${inProgressProjects.length}',
                                  subtitle: 'Projects in progress',
                                  icon: Icons.folder_open_rounded,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Saved Projects',
                                  value: '${activeProjects.length}',
                                  subtitle: 'Total projects',
                                  icon: Icons.bookmark_border_rounded,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  title: 'Completed',
                                  value: '${completedProjects.length}',
                                  subtitle: 'Finished builds',
                                  icon: Icons.check_circle_outline_rounded,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  title: 'Bill of Materials',
                                  value: '$totalBomItems',
                                  subtitle: 'Total components',
                                  icon: Icons.memory_rounded,
                                  isDark: isDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Active Builds',
                            value: '${inProgressProjects.length}',
                            subtitle: 'Projects in progress',
                            icon: Icons.folder_open_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Saved Projects',
                            value: '${activeProjects.length}',
                            subtitle: 'Total saved projects',
                            icon: Icons.bookmark_border_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Completed Builds',
                            value: '${completedProjects.length}',
                            subtitle: 'Finished projects',
                            icon: Icons.check_circle_outline_rounded,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            title: 'Bill of Materials',
                            value: '$totalBomItems',
                            subtitle: 'Total components',
                            icon: Icons.memory_rounded,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // =========================================================
                // RECENT PROJECTS + QUICK ACTIONS
                // =========================================================
                if (isMobile || isTablet)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _RecentProjectsCard(
                        projects: recentProjects,
                        isDark: isDark,
                        onOpenProject: (project) {
                          ref
                              .read(projectsProvider.notifier)
                              .setActiveProject(project);

                          context.go('/planner');
                        },
                        onViewAll: () {
                          context.go('/saved');
                        },
                      ),

                      const SizedBox(height: 16),

                      _QuickActionsCard(
                        isDark: isDark,
                        onNewProject: () {
                          context.go('/wizard');
                        },
                        onSavedProjects: () {
                          context.go('/saved');
                        },
                      ),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 7,
                        child: _RecentProjectsCard(
                          projects: recentProjects,
                          isDark: isDark,
                          onOpenProject: (project) {
                            ref
                                .read(projectsProvider.notifier)
                                .setActiveProject(project);

                            context.go('/planner');
                          },
                          onViewAll: () {
                            context.go('/saved');
                          },
                        ),
                      ),

                      const SizedBox(width: 20),

                      Expanded(
                        flex: 4,
                        child: _QuickActionsCard(
                          isDark: isDark,
                          onNewProject: () {
                            context.go('/wizard');
                          },
                          onSavedProjects: () {
                            context.go('/saved');
                          },
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // =========================================================
                // BIMO FOOTER
                // =========================================================
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(isMobile ? 18 : 22),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.format_quote_rounded,
                        color: AppColors.emeraldLight,
                        size: 30,
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Great projects start with a plan. Let BiMO be your build companion.',
                              style: AppTypography.bodyMedium(isDark),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '— BiMO Assistant',
                              style: AppTypography.bodySmall(isDark).copyWith(
                                color: AppColors.emeraldLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// STAT CARD
// ============================================================================

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool isDark;

  const _StatCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 145),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: AppColors.emeraldLight),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Text(
                  title,
                  style: AppTypography.bodyMedium(
                    isDark,
                  ).copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            value,
            style: AppTypography.displayMedium(isDark).copyWith(fontSize: 30),
          ),

          const SizedBox(height: 4),

          Text(
            subtitle,
            style: AppTypography.bodySmall(isDark),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RECENT PROJECTS
// ============================================================================

class _RecentProjectsCard extends StatelessWidget {
  final List<ProjectModel> projects;
  final bool isDark;
  final ValueChanged<ProjectModel> onOpenProject;
  final VoidCallback onViewAll;

  const _RecentProjectsCard({
    required this.projects,
    required this.isDark,
    required this.onOpenProject,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Projects', style: AppTypography.headingMedium(isDark)),

          const SizedBox(height: 4),

          Text(
            'Your recently accessed projects.',
            style: AppTypography.bodySmall(isDark),
          ),

          const SizedBox(height: 16),

          if (projects.isEmpty)
            _EmptyProjects(isDark: isDark)
          else
            ...projects.map(
              (project) => _RecentProjectRow(
                project: project,
                isDark: isDark,
                onTap: () => onOpenProject(project),
              ),
            ),

          if (projects.isNotEmpty) ...[
            const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onViewAll,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('View All Projects'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentProjectRow extends StatelessWidget {
  final ProjectModel project;
  final bool isDark;
  final VoidCallback onTap;

  const _RecentProjectRow({
    required this.project,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.emeraldLight,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: AppTypography.bodyMedium(
                    isDark,
                  ).copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 3),

                Text(
                  '${project.partsCount} parts • ₱${project.finalCost.toStringAsFixed(0)}',
                  style: AppTypography.bodySmall(isDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          if (isMobile)
            IconButton(
              onPressed: onTap,
              tooltip: 'Open Project',
              icon: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.emeraldLight,
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: onTap,
              iconAlignment: IconAlignment.end,
              icon: const Icon(Icons.chevron_right_rounded, size: 18),
              label: const Text('Open'),
            ),
        ],
      ),
    );
  }
}

class _EmptyProjects extends StatelessWidget {
  final bool isDark;

  const _EmptyProjects({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.folder_open_rounded,
            size: 32,
            color: AppColors.emeraldLight,
          ),

          const SizedBox(height: 10),

          Text(
            'No projects yet',
            style: AppTypography.headingMedium(isDark).copyWith(fontSize: 16),
          ),

          const SizedBox(height: 4),

          Text(
            'Start a new project and it will appear here.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall(isDark),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// QUICK ACTIONS
// ============================================================================

class _QuickActionsCard extends StatelessWidget {
  final bool isDark;
  final VoidCallback onNewProject;
  final VoidCallback onSavedProjects;

  const _QuickActionsCard({
    required this.isDark,
    required this.onNewProject,
    required this.onSavedProjects,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick Actions', style: AppTypography.headingMedium(isDark)),

          const SizedBox(height: 4),

          Text(
            'Shortcuts to get things done.',
            style: AppTypography.bodySmall(isDark),
          ),

          const SizedBox(height: 18),

          InkWell(
            onTap: onNewProject,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.emeraldSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.emeraldSoftBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSoft,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.emeraldSoftBorder),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: AppColors.emeraldLight,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Start a New Project',
                          style: AppTypography.bodyMedium(isDark).copyWith(
                            color: AppColors.emeraldLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Plan, track and build your next idea',
                          style: AppTypography.bodySmall(isDark),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.emeraldLight,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          _QuickActionTile(
            title: 'View Saved Projects',
            icon: Icons.bookmark_border_rounded,
            isDark: isDark,
            onTap: onSavedProjects,
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.emeraldLight, size: 20),

            const SizedBox(width: 12),

            Expanded(
              child: Text(
                title,
                style: AppTypography.bodyMedium(
                  isDark,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),

            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
