import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/bomo_assistant.dart';
import '../../../shared/widgets/bimo_back_button.dart';
import '../../../shared/widgets/terminal_loader.dart';
import '../../../shared/widgets/compatibility_alert.dart';
import '../../../shared/widgets/store_map_visual.dart';
import '../../../shared/widgets/generate_button.dart';
import '../../../shared/widgets/mark_complete_card.dart';
import '../../projects/domain/models.dart';
import '../../projects/data/project_provider.dart';

class MakerPortalScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? wizardData;

  const MakerPortalScreen({Key? key, this.wizardData}) : super(key: key);

  @override
  ConsumerState<MakerPortalScreen> createState() => _MakerPortalScreenState();
}

class _MakerPortalScreenState extends ConsumerState<MakerPortalScreen> {
  int _step =
      0; // 0 = Setup, 1 = Checklist, 2 = Sourced Parts, 3 = Smart Deals, 4 = Tracker Summary
  String _inputMode = 'text'; // 'url' or 'text'
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customSpecController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  bool _isExtracting = false;
  bool _extractionComplete = false;
  bool? _useOptimizedSelection;
  ProjectModel? _currentProject;

  @override
  void initState() {
    super.initState();
    if (widget.wizardData != null) {
      _inputMode = widget.wizardData!['toolType'] ?? 'text';
      if (widget.wizardData!['projectName'] != null) {
        _titleController.text = widget.wizardData!['projectName'];
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _promptController.dispose();
    _customNameController.dispose();
    _customSpecController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _refreshCurrentProject() {
    if (_currentProject == null) return;

    final state = ref.read(projectsProvider);
    final index = state.projects.indexWhere(
      (project) => project.id == _currentProject!.id,
    );

    if (index == -1 || !mounted) return;

    setState(() {
      _currentProject = state.projects[index];
    });
  }

  void _handleStartExtraction() {
    setState(() {
      _isExtracting = true;
      _extractionComplete = false;
      _useOptimizedSelection = null;
    });

    // Simulate extraction delay
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) {
        setState(() {
          _extractionComplete = true;
        });
      }
    });
  }

  void _handleExtractionFinished() {
    final title = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : 'Smart Automated Greenhouse';

    final newProj = ProjectModel(
      id: 'proj-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      category: 'engineering',
      createdAt: DateTime.now(),
      isOptimized: true,
      buildInstructions: [
        'Step 1: Connect the main controller to a stable power source (3.3V or 5V depending on board specs).',
        'Step 2: Wire the sensor modules to the analog/digital input pins.',
        'Step 3: Connect actuators/relays to the digital output pins, ensuring logic level compatibility.',
        'Step 4: Flash the firmware and monitor serial output for initial diagnostics.',
      ],
      components: [
        BOMComponent(
          orig: 'Main Microcontroller Board',
          local: 'Generic Development Board',
          notes: 'Based on project requirements',
          qty: 1,
          category: 'Microcontrollers',
          selectedOptionIndex: 0,
          options: [
            ComponentOption(
              type: 'Standard',
              seller: 'Local Tech Shop',
              stock: 50,
              price: 500.0,
              match: '95%',
            ),
          ],
        ),
        BOMComponent(
          orig: 'Sensor Module',
          local: 'Compatible Sensor Unit',
          notes: 'Required for environment reading',
          qty: 2,
          category: 'Sensors',
          selectedOptionIndex: 0,
          options: [
            ComponentOption(
              type: 'Standard',
              seller: 'Sensor Depot',
              stock: 100,
              price: 150.0,
              match: '98%',
            ),
          ],
        ),
        BOMComponent(
          orig: 'Power Supply Unit',
          local: '12V/5V Dual Power Supply',
          notes: 'Sufficient wattage for all modules',
          qty: 1,
          category: 'Power',
          selectedOptionIndex: 0,
          options: [
            ComponentOption(
              type: 'Standard',
              seller: 'PowerHaus',
              stock: 30,
              price: 350.0,
              match: '99%',
            ),
          ],
        ),
      ],
      auditLog: [
        AuditLogEntry(
          action: 'Extracted components from prompt',
          timestamp: 'Just now',
        ),
      ],
    );

    ref.read(projectsProvider.notifier).addProject(newProj);

    setState(() {
      _currentProject = newProj;
      _isExtracting = false;
      _step = 1;
      _useOptimizedSelection = null;
    });
  }

  double _currentSelectionTotal(ProjectModel project) {
    return project.copyWith(isOptimized: false).finalCost;
  }

  double _optimizedSelectionTotal(ProjectModel project) {
    return project.copyWith(isOptimized: true).finalCost;
  }

  String _formatCurrency(double amount) {
    return '\u20B1${amount.toStringAsFixed(0)}';
  }

  String _formatOptimizedSavings(ProjectModel project) {
    final currentTotal = _currentSelectionTotal(project);
    final optimizedTotal = _optimizedSelectionTotal(project);
    final savings = currentTotal - optimizedTotal;
    final percent = currentTotal > 0 ? (savings / currentTotal) * 100 : 0.0;

    return 'Save ${_formatCurrency(savings)} (${percent.toStringAsFixed(0)}%)';
  }

  void _handleSmartDealSelection(bool useOptimized) {
    if (_currentProject == null) return;

    ref
        .read(projectsProvider.notifier)
        .toggleOptimization(_currentProject!.id, useOptimized);

    final state = ref.read(projectsProvider);
    final index = state.projects.indexWhere(
      (project) => project.id == _currentProject!.id,
    );

    if (index == -1 || !mounted) return;

    setState(() {
      _currentProject = state.projects[index];
      _useOptimizedSelection = useOptimized;
    });
  }

  String _getAssistantMessage() {
    switch (_step) {
      case 0:
        return _isExtracting
            ? 'Processing your input... I am running Natural Language Processing to extract technical specifications and cross-reference them with live Agora nodes.'
            : 'Hi there! I am BiMO. Describe your hardware setup or paste a reference link, and I will generate your Bill of Materials and search local suppliers!';
      case 1:
        return 'Extraction complete! I found your parts from local suppliers. I also flagged potential logic level mismatches (ESP32 3.3V vs 5V Relays), see warning indicator below.';
      case 2:
        return 'I found active component options in supplier warehouse stocks. Pick the specific edition, price, and condition you want for your build!';
      case 3:
        return 'I found compatible alternatives that could reduce your estimated cost by 25%. Compare the options below and choose which setup you prefer.';
      case 4:
      default:
        return 'Your Bill of Materials is ready! You can now download the PDF, export to Sheets, or mark the build as completed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isVeryNarrow = screenWidth <= 360;
    final pagePadding = isMobile ? 16.0 : 24.0;
    final cardPadding = isVeryNarrow ? 12.0 : (isMobile ? 16.0 : 24.0);
    final chipLabelFontSize = isVeryNarrow ? 11.0 : (isMobile ? 12.0 : null);
    final projectsState = ref.watch(projectsProvider);

    return AppScaffold(
      title: isMobile
          ? 'Build Center'
          : 'Build Center & Bill of Materials (BOM) Management',
      body: SingleChildScrollView(
        padding: EdgeInsets.all(pagePadding),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1000),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BomoAssistant(message: _getAssistantMessage()),

                // Step 0: Input Setup
                if (_step == 0) ...[
                  Text(
                    _titleController.text.isNotEmpty
                        ? _titleController.text
                        : 'Ready to build something?',
                    style: AppTypography.displayMedium(
                      isDark,
                    ).copyWith(fontSize: isVeryNarrow ? 28 : null),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _inputMode == 'url'
                        ? 'Paste a YouTube or GitHub tutorial link to generate a localized \u20B1 parts list & budget tracker.'
                        : 'Describe your engineering idea to generate a complete architecture and parts list.',
                    style: AppTypography.bodyMedium(isDark),
                  ),
                  const SizedBox(height: 24),

                  if (_isExtracting)
                    TerminalLoader(
                      isComplete: _extractionComplete,
                      onFinished: _handleExtractionFinished,
                    )
                  else ...[
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(cardPadding),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPanel
                            : AppColors.lightPanel,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ChoiceChip(
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Text Prompt'),
                                    ),
                                    selected: _inputMode == 'text',
                                    onSelected: (val) =>
                                        setState(() => _inputMode = 'text'),
                                    selectedColor: AppColors.emeraldSoft,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: isMobile
                                        ? VisualDensity.compact
                                        : VisualDensity.standard,
                                    labelPadding: EdgeInsets.symmetric(
                                      horizontal: isVeryNarrow ? 4 : 8,
                                    ),
                                    labelStyle: TextStyle(
                                      color: _inputMode == 'text'
                                          ? AppColors.emeraldLight
                                          : (isDark
                                                ? AppColors.darkTextMuted
                                                : AppColors.lightTextMuted),
                                      fontWeight: FontWeight.bold,
                                      fontSize: chipLabelFontSize,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ChoiceChip(
                                    label: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text('Reference URL'),
                                    ),
                                    selected: _inputMode == 'url',
                                    onSelected: (val) =>
                                        setState(() => _inputMode = 'url'),
                                    selectedColor: AppColors.emeraldSoft,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: isMobile
                                        ? VisualDensity.compact
                                        : VisualDensity.standard,
                                    labelPadding: EdgeInsets.symmetric(
                                      horizontal: isVeryNarrow ? 4 : 8,
                                    ),
                                    labelStyle: TextStyle(
                                      color: _inputMode == 'url'
                                          ? AppColors.emeraldLight
                                          : (isDark
                                                ? AppColors.darkTextMuted
                                                : AppColors.lightTextMuted),
                                      fontWeight: FontWeight.bold,
                                      fontSize: chipLabelFontSize,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_inputMode == 'url')
                            TextField(
                              controller: _urlController,
                              style: AppTypography.bodyLarge(isDark),
                              decoration: const InputDecoration(
                                hintText:
                                    'https://youtube.com/watch?v=... or GitHub repo URL',
                                prefixIcon: Icon(Icons.link_rounded),
                              ),
                            )
                          else
                            TextField(
                              controller: _promptController,
                              maxLines: 5,
                              style: AppTypography.bodyMedium(isDark),
                              decoration: const InputDecoration(
                                hintText:
                                    'Describe your project in more detail, including the features, components, and how you want it to work...',
                              ),
                            ),

                          const SizedBox(height: 20),
                          GenerateButton(
                            onPressed: _handleStartExtraction,
                            label: isMobile
                                ? 'Generate Project'
                                : 'Generate Bill of Materials & Architecture',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),
                    Text(
                      'RECENT PROJECTS',
                      style: AppTypography.labelUppercase(),
                    ),
                    const SizedBox(height: 14),

                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: projectsState.projects.take(3).length,
                      itemBuilder: (context, index) {
                        final proj = projectsState.projects[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: 8,
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.emeraldSoft,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.developer_board_rounded,
                                color: AppColors.emeraldLight,
                              ),
                            ),
                            title: Text(
                              proj.title,
                              style: AppTypography.headingMedium(
                                isDark,
                              ).copyWith(fontSize: 15),
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${proj.partsCount} parts \u2022 \u20B1${proj.finalCost.toStringAsFixed(0)}',
                              style: AppTypography.bodySmall(isDark),
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              setState(() {
                                _currentProject = proj;
                                _titleController.text = proj.title;
                                _step = 1;
                                _useOptimizedSelection = null;
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ]
                // Step 1: Shopping Checklist
                else if (_step == 1 && _currentProject != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Bill of Materials (BOM)',
                        style: AppTypography.headingLarge(isDark),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Review the recommended parts and materials, adjust quantities, or add custom items before searching suppliers.',
                        style: AppTypography.bodySmall(isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Mismatch warning alert banner if ESP32 and Relays present
                  InkWell(
                    onTap: () => CompatibilityAlertModal.show(context),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.redSoft,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.redAlert.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.redAlert,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Logic Mismatch Detected: ESP32 (3.3V) & 5V Relay Module. Tap to view compatibility recommendation.',
                              style: AppTypography.bodySmall(isDark).copyWith(
                                color: AppColors.redAlert,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Components Table
                  Container(
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
                    child: Column(
                      children: [
                        if (!isMobile) ...[
                          // Table Header
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    'COMPONENT',
                                    style: AppTypography.labelUppercase(),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'DESIRED SPEC',
                                    style: AppTypography.labelUppercase(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'QTY',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.labelUppercase(),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    'ACTION',
                                    textAlign: TextAlign.end,
                                    style: AppTypography.labelUppercase(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                        ],

                        // Component Rows
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _currentProject!.components.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final comp = _currentProject!.components[idx];

                            if (isMobile) {
                              return Padding(
                                padding: EdgeInsets.all(cardPadding),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      comp.local,
                                      style: AppTypography.headingMedium(
                                        isDark,
                                      ).copyWith(fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      comp.notes,
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Text(
                                          'QTY',
                                          style: AppTypography.labelUppercase(),
                                        ),
                                        const Spacer(),
                                        IconButton(
                                          constraints:
                                              const BoxConstraints.tightFor(
                                                width: 36,
                                                height: 36,
                                              ),
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.remove_circle_outline_rounded,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(projectsProvider.notifier)
                                                .updateComponentQty(
                                                  _currentProject!.id,
                                                  idx,
                                                  -1,
                                                );
                                            _refreshCurrentProject();
                                          },
                                        ),
                                        SizedBox(
                                          width: 28,
                                          child: Text(
                                            '${comp.qty}',
                                            textAlign: TextAlign.center,
                                            style: AppTypography.headingMedium(
                                              isDark,
                                            ).copyWith(fontSize: 16),
                                          ),
                                        ),
                                        IconButton(
                                          constraints:
                                              const BoxConstraints.tightFor(
                                                width: 36,
                                                height: 36,
                                              ),
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.add_circle_outline_rounded,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(projectsProvider.notifier)
                                                .updateComponentQty(
                                                  _currentProject!.id,
                                                  idx,
                                                  1,
                                                );
                                            _refreshCurrentProject();
                                          },
                                        ),
                                        IconButton(
                                          constraints:
                                              const BoxConstraints.tightFor(
                                                width: 36,
                                                height: 36,
                                              ),
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: AppColors.redAlert,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(projectsProvider.notifier)
                                                .deleteComponent(
                                                  _currentProject!.id,
                                                  idx,
                                                );
                                            _refreshCurrentProject();
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      comp.local,
                                      style: AppTypography.bodyMedium(
                                        isDark,
                                      ).copyWith(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      comp.notes,
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline_rounded,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(projectsProvider.notifier)
                                                .updateComponentQty(
                                                  _currentProject!.id,
                                                  idx,
                                                  -1,
                                                );
                                            _refreshCurrentProject();
                                          },
                                        ),
                                        Text(
                                          '${comp.qty}',
                                          style: AppTypography.headingMedium(
                                            isDark,
                                          ).copyWith(fontSize: 16),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline_rounded,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            ref
                                                .read(projectsProvider.notifier)
                                                .updateComponentQty(
                                                  _currentProject!.id,
                                                  idx,
                                                  1,
                                                );
                                            _refreshCurrentProject();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          color: AppColors.redAlert,
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          ref
                                              .read(projectsProvider.notifier)
                                              .deleteComponent(
                                                _currentProject!.id,
                                                idx,
                                              );
                                          _refreshCurrentProject();
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Add Custom Item Controls
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _customNameController,
                          decoration: const InputDecoration(
                            hintText: 'Custom item name...',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customSpecController,
                          decoration: const InputDecoration(
                            hintText: 'Custom specs...',
                          ),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (_customNameController.text.trim().isNotEmpty) {
                              ref
                                  .read(projectsProvider.notifier)
                                  .addCustomComponent(
                                    _currentProject!.id,
                                    _customNameController.text.trim(),
                                    _customSpecController.text.trim(),
                                  );
                              _customNameController.clear();
                              _customSpecController.clear();
                              _refreshCurrentProject();
                            }
                          },
                          child: const Text('+ Add Item'),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customNameController,
                            decoration: const InputDecoration(
                              hintText: 'Custom item name...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _customSpecController,
                            decoration: const InputDecoration(
                              hintText: 'Custom specs...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (_customNameController.text.trim().isNotEmpty) {
                              ref
                                  .read(projectsProvider.notifier)
                                  .addCustomComponent(
                                    _currentProject!.id,
                                    _customNameController.text.trim(),
                                    _customSpecController.text.trim(),
                                  );

                              _refreshCurrentProject();

                              _customNameController.clear();
                              _customSpecController.clear();
                            }
                          },
                          child: const Text('+ Add Item'),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPanel
                          : AppColors.lightPanel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.emerald.withValues(alpha: 0.35),
                      ),
                    ),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NEXT STEP',
                                style: AppTypography.labelUppercase().copyWith(
                                  color: AppColors.emeraldLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ready to find your parts?',
                                style: AppTypography.headingMedium(isDark),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Search local suppliers for matching components, prices, and available options.',
                                style: AppTypography.bodySmall(isDark),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.emerald,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                  onPressed: () => setState(() => _step = 2),
                                  icon: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'SEARCH SUPPLIERS',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NEXT STEP',
                                      style: AppTypography.labelUppercase()
                                          .copyWith(
                                            color: AppColors.emeraldLight,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ready to find your parts?',
                                      style: AppTypography.headingMedium(
                                        isDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Search local suppliers for matching components, prices, and available options.',
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.emerald,
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(190, 48),
                                ),
                                onPressed: () => setState(() => _step = 2),
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'SEARCH SUPPLIERS',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 24),
                  BiMOBackButton(
                    onPressed: () => setState(() => _step = 0),
                    label: 'Back to Setup',
                  ),
                ]
                // Step 2: Sourced Parts Selection
                else if (_step == 2 && _currentProject != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sourced Parts Selection',
                        style: AppTypography.headingLarge(isDark),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Review the supplier matches for each component and choose the option you prefer.',
                        style: AppTypography.bodySmall(isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentProject!.components.length,
                    itemBuilder: (context, idx) {
                      final comp = _currentProject!.components[idx];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comp.local,
                                style: AppTypography.headingMedium(isDark),
                              ),
                              Text(
                                comp.notes,
                                style: AppTypography.bodySmall(isDark),
                              ),
                              const SizedBox(height: 12),
                              Column(
                                children: List.generate(comp.options.length, (
                                  optIdx,
                                ) {
                                  final opt = comp.options[optIdx];
                                  final isSelected =
                                      comp.selectedOptionIndex == optIdx;

                                  return InkWell(
                                    onTap: () {
                                      ref
                                          .read(projectsProvider.notifier)
                                          .selectComponentOption(
                                            _currentProject!.id,
                                            idx,
                                            optIdx,
                                          );
                                      _refreshCurrentProject();
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.emeraldSoft
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.emeraldLight
                                              : AppColors.darkBorder,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected
                                                ? Icons.radio_button_checked
                                                : Icons.radio_button_off,
                                            color: isSelected
                                                ? AppColors.emeraldLight
                                                : AppColors.darkTextMuted,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${comp.local} (${opt.type})',
                                                  style:
                                                      AppTypography.bodyMedium(
                                                        isDark,
                                                      ),
                                                ),
                                                if (isMobile)
                                                  Text(
                                                    '${opt.match} match',
                                                    style:
                                                        AppTypography.labelUppercase(),
                                                  ),
                                                Text(
                                                  'Seller: ${opt.seller} \u2022 Stock: ${opt.stock} \u2022 Price: \u20B1${opt.price.toStringAsFixed(0)}',
                                                  style:
                                                      AppTypography.bodySmall(
                                                        isDark,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isMobile) ...[
                                            const SizedBox(width: 12),
                                            Text(
                                              '${opt.match} match',
                                              style:
                                                  AppTypography.labelUppercase(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPanel
                          : AppColors.lightPanel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.emerald.withValues(alpha: 0.35),
                      ),
                    ),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NEXT STEP',
                                style: AppTypography.labelUppercase().copyWith(
                                  color: AppColors.emeraldLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ready to compare your selections?',
                                style: AppTypography.headingMedium(isDark),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Let BiMO compare your selected parts and find better-value alternatives.',
                                style: AppTypography.bodySmall(isDark),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.emerald,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                  onPressed: () => setState(() {
                                    _step = 3;
                                    _useOptimizedSelection = null;
                                  }),
                                  icon: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'FIND BEST DEAL',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NEXT STEP',
                                      style: AppTypography.labelUppercase()
                                          .copyWith(
                                            color: AppColors.emeraldLight,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ready to compare your selections?',
                                      style: AppTypography.headingMedium(
                                        isDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Let BiMO compare your selected parts and find better-value alternatives.',
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.emerald,
                                  foregroundColor: Colors.black,
                                  minimumSize: const Size(170, 48),
                                ),
                                onPressed: () => setState(() {
                                  _step = 3;
                                  _useOptimizedSelection = null;
                                }),
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'FIND BEST DEAL',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  BiMOBackButton(
                    onPressed: () => setState(() => _step = 1),
                    label: 'Back to Checklist',
                  ),
                ]
                // Step 3: Smart Alternatives & Deals
                else if (_step == 3 && _currentProject != null) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Deals & Alternatives',
                        style: AppTypography.headingLarge(isDark),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Compare your current selections with BiMO's optimized recommendations before continuing.",
                        style: AppTypography.bodySmall(isDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final recommendationCardWidth = isMobile
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 16) / 2;
                      final currentTotal = _currentSelectionTotal(
                        _currentProject!,
                      );
                      final optimizedTotal = _optimizedSelectionTotal(
                        _currentProject!,
                      );
                      final currentSelected = _useOptimizedSelection == false;
                      final optimizedSelected = _useOptimizedSelection == true;
                      final unselectedBorder = isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder;

                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: recommendationCardWidth,
                            child: InkWell(
                              onTap: () => _handleSmartDealSelection(false),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: currentSelected
                                        ? AppColors.emeraldLight
                                        : unselectedBorder,
                                    width: currentSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (currentSelected) ...[
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.emeraldLight,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'SELECTED',
                                            style: AppTypography.labelUppercase(
                                              color: AppColors.emeraldLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    Text(
                                      'Your Current Selection',
                                      style: AppTypography.headingMedium(
                                        isDark,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _formatCurrency(currentTotal),
                                      style: AppTypography.displayLarge(isDark),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '\u2022 Current component selections\n\u2022 Individual supplier/shipping costs',
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: currentSelected
                                              ? AppColors.emeraldLight
                                              : (isDark
                                                    ? Colors.white
                                                    : Colors.black),
                                          side: BorderSide(
                                            color: currentSelected
                                                ? AppColors.emeraldLight
                                                : unselectedBorder,
                                          ),
                                          minimumSize: const Size.fromHeight(
                                            46,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _handleSmartDealSelection(false),
                                        icon: Icon(
                                          currentSelected
                                              ? Icons.check_circle_rounded
                                              : Icons.radio_button_unchecked,
                                          size: 18,
                                        ),
                                        label: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'USE CURRENT SELECTION',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          SizedBox(
                            width: recommendationCardWidth,
                            child: InkWell(
                              onTap: () => _handleSmartDealSelection(true),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSurface
                                      : AppColors.lightSurface,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: optimizedSelected
                                        ? AppColors.emeraldLight
                                        : AppColors.emeraldSoftBorder,
                                    width: optimizedSelected ? 2 : 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'BiMO Optimized Selection',
                                            style: AppTypography.headingMedium(
                                              isDark,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.emeraldSoft,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color:
                                                  AppColors.emeraldSoftBorder,
                                            ),
                                          ),
                                          child: Text(
                                            'RECOMMENDED',
                                            style: AppTypography.labelUppercase(
                                              color: AppColors.emeraldLight,
                                            ).copyWith(fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (optimizedSelected) ...[
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.emeraldLight,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'SELECTED',
                                            style: AppTypography.labelUppercase(
                                              color: AppColors.emeraldLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                    const SizedBox(height: 12),
                                    Text(
                                      _formatCurrency(optimizedTotal),
                                      style: AppTypography.displayLarge(
                                        isDark,
                                      ).copyWith(color: AppColors.emeraldLight),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _formatOptimizedSavings(_currentProject!),
                                      style: AppTypography.bodyMedium(isDark)
                                          .copyWith(
                                            color: AppColors.emeraldLight,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      '\u2022 Compatible equivalent component suggestions\n\u2022 Consolidated supplier sourcing where possible',
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: optimizedSelected
                                              ? AppColors.emeraldLight
                                              : (isDark
                                                    ? Colors.white
                                                    : Colors.black),
                                          side: BorderSide(
                                            color: optimizedSelected
                                                ? AppColors.emeraldLight
                                                : AppColors.emeraldSoftBorder,
                                          ),
                                          minimumSize: const Size.fromHeight(
                                            46,
                                          ),
                                        ),
                                        onPressed: () =>
                                            _handleSmartDealSelection(true),
                                        icon: Icon(
                                          optimizedSelected
                                              ? Icons.check_circle_rounded
                                              : Icons.radio_button_unchecked,
                                          size: 18,
                                        ),
                                        label: const FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'USE OPTIMIZED SELECTION',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(cardPadding),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPanel
                          : AppColors.lightPanel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.emerald.withValues(alpha: 0.35),
                      ),
                    ),
                    child: isMobile
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NEXT STEP',
                                style: AppTypography.labelUppercase().copyWith(
                                  color: AppColors.emeraldLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ready to review your final plan?',
                                style: AppTypography.headingMedium(isDark),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Continue to the procurement tracker to review your selected parts, estimated cost, and build status.',
                                style: AppTypography.bodySmall(isDark),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.emerald,
                                    foregroundColor: Colors.black,
                                    disabledBackgroundColor: isDark
                                        ? AppColors.darkBorder
                                        : AppColors.lightPanelStrong,
                                    disabledForegroundColor: isDark
                                        ? AppColors.darkTextMuted
                                        : AppColors.lightTextMuted,
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                  onPressed: _useOptimizedSelection == null
                                      ? null
                                      : () => setState(() => _step = 4),
                                  icon: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                  ),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'GO TO TRACKER SUMMARY',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'NEXT STEP',
                                      style: AppTypography.labelUppercase()
                                          .copyWith(
                                            color: AppColors.emeraldLight,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ready to review your final plan?',
                                      style: AppTypography.headingMedium(
                                        isDark,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Continue to the procurement tracker to review your selected parts, estimated cost, and build status.',
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.emerald,
                                  foregroundColor: Colors.black,
                                  disabledBackgroundColor: isDark
                                      ? AppColors.darkBorder
                                      : AppColors.lightPanelStrong,
                                  disabledForegroundColor: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                  minimumSize: const Size(230, 48),
                                ),
                                onPressed: _useOptimizedSelection == null
                                    ? null
                                    : () => setState(() => _step = 4),
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'GO TO TRACKER SUMMARY',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 24),
                  BiMOBackButton(
                    onPressed: () => setState(() => _step = 2),
                    label: 'Back to Sourced Parts',
                  ),
                ]
                // Step 4: Tracker Summary
                else if (_step == 4 && _currentProject != null) ...[
                  Text(
                    'Procurement Tracker Summary',
                    style: AppTypography.headingLarge(isDark),
                  ),
                  const SizedBox(height: 16),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final leftColumnWidth = isMobile
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 20) * 6 / 11;
                      final rightColumnWidth = isMobile
                          ? constraints.maxWidth
                          : (constraints.maxWidth - 20) * 5 / 11;

                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: [
                          SizedBox(
                            width: leftColumnWidth,
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Shopping Cart Items',
                                        style: AppTypography.headingMedium(
                                          isDark,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount:
                                            _currentProject!.components.length,
                                        itemBuilder: (context, idx) {
                                          final item =
                                              _currentProject!.components[idx];
                                          if (isMobile) {
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 8,
                                                  ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          item.local,
                                                          style:
                                                              AppTypography.bodyMedium(
                                                                isDark,
                                                              ),
                                                        ),
                                                        Text(
                                                          item.notes,
                                                          style:
                                                              AppTypography.bodySmall(
                                                                isDark,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Text(
                                                    '\u20B1${(item.totalPrice * (_currentProject!.isOptimized ? 0.75 : 1.0)).toStringAsFixed(0)}',
                                                    style:
                                                        AppTypography.bodyMedium(
                                                          isDark,
                                                        ).copyWith(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: AppColors
                                                              .emeraldLight,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }

                                          return ListTile(
                                            contentPadding: EdgeInsets.zero,
                                            title: Text(
                                              item.local,
                                              style: AppTypography.bodyMedium(
                                                isDark,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            subtitle: Text(
                                              item.notes,
                                              style: AppTypography.bodySmall(
                                                isDark,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            trailing: Text(
                                              '\u20B1${(item.totalPrice * (_currentProject!.isOptimized ? 0.75 : 1.0)).toStringAsFixed(0)}',
                                              style:
                                                  AppTypography.bodyMedium(
                                                    isDark,
                                                  ).copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        AppColors.emeraldLight,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                MarkCompleteCard(
                                  isCompleted: _currentProject!.isCompleted,
                                  onToggle: (val) {
                                    ref
                                        .read(projectsProvider.notifier)
                                        .toggleCompletion(
                                          _currentProject!.id,
                                          val,
                                        );
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),

                          SizedBox(
                            width: rightColumnWidth,
                            child: Column(
                              children: [
                                const StoreMapVisual(
                                  locationQuery: 'Manila Agora Hardware Hub',
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(20),
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
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order Summary',
                                        style: AppTypography.headingMedium(
                                          isDark,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.darkPanel
                                              : AppColors.lightPanel,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: AppColors.emerald
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: Text(
                                          'Note: Prices are estimates and may vary by physical store. For online supplies, BiMO recommends trusted shops but does not process transactions directly.',
                                          style: AppTypography.bodySmall(isDark)
                                              .copyWith(
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              'Total Cost',
                                              style: AppTypography.bodyMedium(
                                                isDark,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '\u20B1${_currentProject!.finalCost.toStringAsFixed(0)}',
                                            style:
                                                AppTypography.headingLarge(
                                                  isDark,
                                                ).copyWith(
                                                  color: AppColors.emeraldLight,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.emerald,
                                          foregroundColor: Colors.black,
                                          minimumSize: const Size.fromHeight(
                                            48,
                                          ),
                                        ),
                                        onPressed: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Project saved to your Tracker!',
                                              ),
                                            ),
                                          );
                                          context.go('/saved');
                                        },
                                        icon: const Icon(Icons.save_rounded),
                                        label: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            isMobile
                                                ? 'SAVE PROJECT'
                                                : 'SAVE PROJECT TO TRACKER',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      OutlinedButton.icon(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: isDark
                                              ? Colors.white
                                              : Colors.black,
                                          side: BorderSide(
                                            color: isDark
                                                ? AppColors.darkBorder
                                                : AppColors.lightBorder,
                                          ),
                                          minimumSize: const Size.fromHeight(
                                            48,
                                          ),
                                        ),
                                        onPressed: () {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Saved Plan as Document (PDF/Word) - Mock',
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.picture_as_pdf_rounded,
                                        ),
                                        label: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            isMobile
                                                ? 'SAVE PDF'
                                                : 'SAVE PLAN AS DOCUMENT (PDF)',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  BiMOBackButton(
                    onPressed: () => setState(() => _step = 3),
                    label: 'Back to Smart Deals',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
