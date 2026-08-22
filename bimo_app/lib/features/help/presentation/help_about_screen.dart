import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/bomo_assistant.dart';

class HelpAboutScreen extends StatelessWidget {
  const HelpAboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return AppScaffold(
      title: 'Help & About',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BomoAssistant(
                  title: 'BiMO',
                  message:
                      'Need help? Learn how BiMO turns your project idea into a structured build plan and Bill of Materials.',
                ).animate().fadeIn(duration: 250.ms),
                const SizedBox(height: 32),
                Text(
                  'How can we help?',
                  style: AppTypography.displayMedium(
                    isDark,
                  ).copyWith(fontSize: isMobile ? 26 : null),
                ),
                const SizedBox(height: 6),
                Text(
                  'Quick guides and information to help you understand and use BiMO.',
                  style: AppTypography.bodyMedium(isDark),
                ),
                const SizedBox(height: 28),
                Text('GETTING STARTED', style: AppTypography.labelUppercase()),
                const SizedBox(height: 12),
                _WorkflowSection(isDark: isDark),
                const SizedBox(height: 28),
                Text(
                  'UNDERSTANDING BIMO',
                  style: AppTypography.labelUppercase(),
                ),
                const SizedBox(height: 12),
                _UnderstandingSection(isDark: isDark),
                const SizedBox(height: 28),
                Text(
                  'FREQUENTLY ASKED QUESTIONS',
                  style: AppTypography.labelUppercase(),
                ),
                const SizedBox(height: 12),
                _FaqSection(isDark: isDark),
                const SizedBox(height: 28),
                Text('ABOUT', style: AppTypography.labelUppercase()),
                const SizedBox(height: 12),
                _AboutCard(isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkflowSection extends StatelessWidget {
  final bool isDark;

  const _WorkflowSection({required this.isDark});

  static const _steps = [
    _WorkflowStep(
      title: 'Create Project',
      description: 'Start with your project idea.',
      icon: Icons.add_circle_outline_rounded,
    ),
    _WorkflowStep(
      title: 'Review Bill of Materials',
      description: 'Check the parts and materials BiMO generated.',
      icon: Icons.inventory_2_outlined,
    ),
    _WorkflowStep(
      title: 'Find Suppliers',
      description: 'Review supplier options and estimated prices.',
      icon: Icons.location_searching_rounded,
    ),
    _WorkflowStep(
      title: 'Compare Options',
      description:
          'Compare your current selection with optimized alternatives.',
      icon: Icons.compare_arrows_rounded,
    ),
    _WorkflowStep(
      title: 'Track Build',
      description: 'Manage your project and procurement progress.',
      icon: Icons.check_circle_outline_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 760) {
          return _MobileWorkflowTimeline(steps: _steps, isDark: isDark);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var index = 0; index < _steps.length; index++) ...[
              Expanded(
                child: _WorkflowStepCard(step: _steps[index], isDark: isDark),
              ),
              if (index < _steps.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _WorkflowStep {
  final String title;
  final String description;
  final IconData icon;

  const _WorkflowStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class _MobileWorkflowTimeline extends StatelessWidget {
  final List<_WorkflowStep> steps;
  final bool isDark;

  const _MobileWorkflowTimeline({required this.steps, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          for (var index = 0; index < steps.length; index++)
            _MobileWorkflowStepTile(
              number: index + 1,
              step: steps[index],
              isLast: index == steps.length - 1,
              isDark: isDark,
            ),
        ],
      ),
    );
  }
}

class _MobileWorkflowStepTile extends StatelessWidget {
  final int number;
  final _WorkflowStep step;
  final bool isLast;
  final bool isDark;

  const _MobileWorkflowStepTile({
    required this.number,
    required this.step,
    required this.isLast,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.emeraldSoft,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.emeraldSoftBorder),
                  ),
                  child: Text(
                    number.toString().padLeft(2, '0'),
                    style: AppTypography.bodySmall(isDark).copyWith(
                      color: AppColors.emeraldLight,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      color: AppColors.emeraldSoftBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(step.icon, size: 18, color: AppColors.emeraldLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step.title,
                          style: AppTypography.bodyLarge(
                            isDark,
                          ).copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: AppTypography.bodySmall(
                      isDark,
                    ).copyWith(color: mutedColor, height: 1.35),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkflowStepCard extends StatelessWidget {
  final _WorkflowStep step;
  final bool isDark;

  const _WorkflowStepCard({required this.step, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.emeraldSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(step.icon, color: AppColors.emeraldLight, size: 22),
          ),
          const SizedBox(height: 10),
          Text(
            step.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium(isDark).copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _UnderstandingSection extends StatelessWidget {
  final bool isDark;

  const _UnderstandingSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 780;
        final cards = [
          _InfoCard(
            title: 'What is a Bill of Materials (BOM)?',
            description:
                'A Bill of Materials is the complete list of parts and materials needed for your project. BiMO creates this list from your project description so you know what you need before building.',
            icon: Icons.inventory_2_outlined,
            emphasized: true,
            isDark: isDark,
          ),
          _InfoCard(
            title: 'Supplier Search',
            description:
                'Review supplier options, estimated prices, availability, and compatible alternatives for your project components.',
            icon: Icons.location_searching_rounded,
            isDark: isDark,
          ),
          _InfoCard(
            title: 'BiMO Recommendations',
            description:
                'BiMO can suggest compatible alternatives and optimized selections. You remain in control of which components you choose.',
            icon: Icons.tips_and_updates_outlined,
            isDark: isDark,
          ),
        ];

        if (isNarrow) {
          return Column(
            children: [
              for (var index = 0; index < cards.length; index++) ...[
                cards[index],
                if (index < cards.length - 1) const SizedBox(height: 12),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < cards.length; index++) ...[
              Expanded(child: cards[index]),
              if (index < cards.length - 1) const SizedBox(width: 16),
            ],
          ],
        );
      },
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool emphasized;
  final bool isDark;

  const _InfoCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isDark,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = emphasized
        ? AppColors.emeraldLight
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: emphasized ? AppColors.emeraldSoft : AppColors.blueSoft,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Icon(
                icon,
                color: emphasized
                    ? AppColors.emeraldLight
                    : AppColors.blueAccent,
                size: 23,
              ),
            ),
            const SizedBox(height: 16),
            Text(title, style: AppTypography.headingMedium(isDark)),
            const SizedBox(height: 8),
            Text(description, style: AppTypography.bodyMedium(isDark)),
          ],
        ),
      ),
    );
  }
}

class _FaqSection extends StatelessWidget {
  final bool isDark;

  const _FaqSection({required this.isDark});

  @override
  Widget build(BuildContext context) {
    const items = [
      _FaqItem(
        question: 'What does BOM mean?',
        answer:
            'BOM stands for Bill of Materials. It is the list of parts and materials required to complete a project.',
      ),
      _FaqItem(
        question: 'Can I edit a generated project?',
        answer:
            'Yes. Open the Project Planner & Tracker to edit project details, components, quantities, costs, and build information.',
      ),
      _FaqItem(
        question: 'Are supplier prices final?',
        answer:
            'No. Prices shown in BiMO are estimates and may vary depending on the supplier or physical store.',
      ),
      _FaqItem(
        question: 'What happens when I delete a project?',
        answer:
            'The project is moved to the Trash Archive, where it can be restored before permanent deletion after 15 days.',
      ),
    ];

    return Card(
      child: Column(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 20),
              childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              iconColor: AppColors.emeraldLight,
              collapsedIconColor: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
              title: Text(
                items[index].question,
                style: AppTypography.bodyLarge(
                  isDark,
                ).copyWith(fontWeight: FontWeight.w700),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    items[index].answer,
                    style: AppTypography.bodyMedium(isDark),
                  ),
                ),
              ],
            ),
            if (index < items.length - 1)
              Divider(
                height: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
          ],
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}

class _AboutCard extends StatelessWidget {
  final bool isDark;

  const _AboutCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.emeraldSoft,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.emeraldSoftBorder),
                  ),
                  child: const Icon(
                    Icons.build_circle_rounded,
                    color: AppColors.emeraldLight,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'BiMO',
                  textAlign: TextAlign.center,
                  style: AppTypography.headingLarge(
                    isDark,
                  ).copyWith(color: AppColors.emeraldLight),
                ),
                const SizedBox(height: 4),
                Text(
                  'Build Intelligence & Materials Organizer',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyLarge(
                    isDark,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Helping makers organize project plans, materials, supplier options, and build progress in one workspace.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium(isDark),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Text(
                    'Version 1.0.0',
                    style: AppTypography.bodySmall(
                      isDark,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
