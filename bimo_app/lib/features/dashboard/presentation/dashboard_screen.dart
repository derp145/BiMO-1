import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/bomo_assistant.dart';
import '../../../shared/widgets/generate_button.dart';
import '../../projects/data/project_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final TextEditingController _inputController = TextEditingController();
  String _inputMode = 'text'; // 'text' or 'url'

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleStartBuild() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    context.go('/maker', extra: {
      'toolType': _inputMode,
      'projectName': _inputMode == 'url' ? 'Extracted Build Specs' : text,
      'prompt': text,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsState = ref.watch(projectsProvider);
    final activeProjects = projectsState.projects.where((p) => p.deletedAt == null).toList();

    return AppScaffold(
      title: 'Project Dashboard',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BomoAssistant(
                  message:
                      'Welcome back! Type what you want to build or paste a video/tutorial link below. BiMO will structure your project, extract the BOM, and check component compatibility.',
                ),

                // Main Heading
                Text('What do you want to build?', style: AppTypography.displayMedium(isDark)),
                const SizedBox(height: 6),
                Text(
                  'Describe your idea or paste a YouTube / GitHub link to generate a complete project plan, BOM & tracker.',
                  style: AppTypography.bodyMedium(isDark),
                ),
                const SizedBox(height: 24),

                // Unified Input Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          ChoiceChip(
                            label: const Text('Describe Concept'),
                            selected: _inputMode == 'text',
                            onSelected: (val) => setState(() => _inputMode = 'text'),
                            selectedColor: AppColors.emeraldSoft,
                            labelStyle: TextStyle(
                              color: _inputMode == 'text'
                                  ? AppColors.emeraldLight
                                  : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ChoiceChip(
                            label: const Text('Tutorial / Video Link'),
                            selected: _inputMode == 'url',
                            onSelected: (val) => setState(() => _inputMode = 'url'),
                            selectedColor: AppColors.emeraldSoft,
                            labelStyle: TextStyle(
                              color: _inputMode == 'url'
                                  ? AppColors.emeraldLight
                                  : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (_inputMode == 'url')
                        TextField(
                          controller: _inputController,
                          style: AppTypography.bodyLarge(isDark),
                          decoration: const InputDecoration(
                            hintText: 'https://youtube.com/watch?v=... or GitHub repo link',
                            prefixIcon: Icon(Icons.link_rounded),
                          ),
                        )
                      else
                        TextField(
                          controller: _inputController,
                          maxLines: 4,
                          style: AppTypography.bodyMedium(isDark),
                          decoration: const InputDecoration(
                            hintText: 'e.g. "I want to build an automated greenhouse using ESP32 to monitor soil moisture, temperature and control 12V water pumps..."',
                          ),
                        ),

                      const SizedBox(height: 20),
                      GenerateButton(
                        onPressed: _handleStartBuild,
                        label: 'Start Building & Generate BOM',
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 250.ms),

                const SizedBox(height: 36),

                // Projects Summary Stats Bar
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => context.go('/saved'),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.emeraldSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.folder_open_rounded, color: AppColors.emeraldLight, size: 24),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('ACTIVE PROJECTS', style: AppTypography.labelUppercase()),
                                  Text(
                                    '${activeProjects.length} Builds',
                                    style: AppTypography.headingLarge(isDark),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // Recent Projects List
                Text('RECENT PROJECTS', style: AppTypography.labelUppercase()),
                const SizedBox(height: 14),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeProjects.take(4).length,
                  itemBuilder: (context, index) {
                    final proj = activeProjects[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.emeraldSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.developer_board_rounded,
                            color: AppColors.emeraldLight,
                          ),
                        ),
                        title: Text(
                          proj.title,
                          style: AppTypography.headingMedium(isDark).copyWith(fontSize: 16),
                        ),
                        subtitle: Text(
                          '${proj.partsCount} parts • ₱${proj.finalCost.toStringAsFixed(0)}',
                          style: AppTypography.bodySmall(isDark),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Open Plan & Tracker',
                              style: AppTypography.bodySmall(isDark).copyWith(
                                color: AppColors.emeraldLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right_rounded, color: AppColors.emeraldLight),
                          ],
                        ),
                        onTap: () {
                          ref.read(projectsProvider.notifier).setActiveProject(proj);
                          context.go('/planner');
                        },
                      ),
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
