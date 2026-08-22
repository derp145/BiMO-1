import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/bimo_back_button.dart';

class ProjectWizardScreen extends ConsumerStatefulWidget {
  const ProjectWizardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProjectWizardScreen> createState() =>
      _ProjectWizardScreenState();
}

class _ProjectWizardScreenState extends ConsumerState<ProjectWizardScreen>
    with SingleTickerProviderStateMixin {
  int _step = 1;
  String? _toolType; // 'url', 'text'
  final TextEditingController _nameController = TextEditingController();

  late AnimationController _orbController;

  @override
  void initState() {
    super.initState();
    _orbController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_step < 2) {
      setState(() {
        _step++;
      });
    }
  }

  void _prevStep() {
    if (_step > 1) {
      setState(() {
        _step--;
      });
    }
  }

  void _handleFinish() {
    final projectName = _nameController.text.trim();
    if (projectName.isEmpty) return;

    // Navigate to Maker Portal with wizard state
    context.go(
      '/maker',
      extra: {
        'toolType': _toolType ?? 'text',
        'projectName': projectName,
        'category': 'engineering', // default unified category
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Create New Project',
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title
                Text(
                  'What are we building today?',
                  style: AppTypography.displayMedium(isDark),
                ),
                const SizedBox(height: 8),
                Text(
                  'Follow the guided steps below to set up your project workspace.',
                  style: AppTypography.bodyMedium(isDark),
                ),
                const SizedBox(height: 36),

                // 3-Column Layout: Selectors | Glowing Orb | Dynamic Copy
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;

                    if (!isWide) {
                      return Column(
                        children: [
                          _buildLeftColumn(isDark),
                          const SizedBox(height: 32),
                          _buildCenterOrb(isDark),
                          const SizedBox(height: 32),
                          _buildRightColumn(isDark),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(flex: 4, child: _buildLeftColumn(isDark)),
                        Expanded(flex: 4, child: _buildCenterOrb(isDark)),
                        Expanded(flex: 4, child: _buildRightColumn(isDark)),
                      ],
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

  Widget _buildLeftColumn(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_step == 1) ...[
          Text('STEP 1: INPUT SOURCE', style: AppTypography.labelUppercase()),
          const SizedBox(height: 16),
          _SelectionCard(
            title: 'IMPORT REFERENCES',
            subtitle:
                'Import build specs from YouTube, GitHub, or documentation links to extract a complete Bill of Materials (BOM).',
            icon: Icons.link_rounded,
            selected: _toolType == 'url',
            onTap: () {
              setState(() {
                _toolType = 'url';
              });
              _nextStep();
            },
          ),
          const SizedBox(height: 14),
          _SelectionCard(
            title: 'START FROM AN IDEA',
            subtitle:
                'Describe your hardware concept in plain text and let BiMO generate the architecture and Bill of Materials (BOM).',
            icon: Icons.edit_note_rounded,
            selected: _toolType == 'text',
            onTap: () {
              setState(() {
                _toolType = 'text';
              });
              _nextStep();
            },
          ),
        ] else if (_step == 2) ...[
          Text('STEP 2: PROJECT NAME', style: AppTypography.labelUppercase()),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            style: AppTypography.headingMedium(isDark),
            decoration: InputDecoration(
              hintText: 'What should we call this project?',
              prefixIcon: const Icon(Icons.drive_file_rename_outline_rounded),
            ),
            onChanged: (val) => setState(() {}),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _nameController.text.trim().isNotEmpty
                    ? AppColors.emerald
                    : (isDark ? AppColors.darkPanel : AppColors.lightPanel),
                foregroundColor: _nameController.text.trim().isNotEmpty
                    ? Colors.black
                    : (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _nameController.text.trim().isNotEmpty
                  ? _handleFinish
                  : null,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Review & Build Bill of Materials',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(duration: 250.ms);
  }

  Widget _buildCenterOrb(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (_step > 1)
          Align(
            alignment: Alignment.centerLeft,
            child: BiMOBackButton(onPressed: _prevStep, label: 'Back'),
          ),
        const SizedBox(height: 12),

        // Glowing Orb Visual
        AnimatedBuilder(
          animation: _orbController,
          builder: (context, child) {
            return Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.emeraldLight.withOpacity(0.8),
                    AppColors.emerald.withOpacity(0.4),
                    AppColors.blueAccent.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.2, 0.5, 0.8, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emeraldLight.withOpacity(
                      0.3 + 0.1 * _orbController.value,
                    ),
                    blurRadius: 40 + 20 * _orbController.value,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.emeraldLight.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.developer_board_rounded,
                    color: AppColors.emeraldLight,
                    size: 44,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRightColumn(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('BiMO INTELLIGENCE', style: AppTypography.labelUppercase()),
          const SizedBox(height: 12),
          if (_step == 1) ...[
            Text(
              'Choose Input Source',
              style: AppTypography.headingLarge(isDark),
            ),
            const SizedBox(height: 8),
            Text(
              'BiMO can extract technical component lists from YouTube video transcripts, GitHub README files, or your custom natural language build descriptions.',
              style: AppTypography.bodyMedium(isDark),
            ),
          ] else if (_step == 2) ...[
            Text('Name Your Build', style: AppTypography.headingLarge(isDark)),
            const SizedBox(height: 8),
            Text(
              'Give your build a unique name. Once confirmed, BiMO will open the 5-step build portal where you can edit parts, search suppliers, and track procurement.',
              style: AppTypography.bodyMedium(isDark),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 250.ms);
  }
}

class _SelectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.emeraldSoft
              : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.emeraldLight
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.emeraldLight.withOpacity(0.2)
                    : (isDark ? AppColors.darkPanel : AppColors.lightPanel),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: selected
                    ? AppColors.emeraldLight
                    : (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.headingMedium(isDark).copyWith(
                      fontSize: 16,
                      color: selected
                          ? AppColors.emeraldLight
                          : (isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTypography.bodySmall(isDark)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
