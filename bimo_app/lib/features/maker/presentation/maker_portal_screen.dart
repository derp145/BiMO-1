import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/bomo_assistant.dart';
import '../../../shared/widgets/terminal_loader.dart';
import '../../../shared/widgets/animated_checkbox.dart';
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
  int _step = 0; // 0 = Setup, 1 = Checklist, 2 = Sourced Parts, 3 = Smart Deals, 4 = Tracker Summary
  String _inputMode = 'text'; // 'url' or 'text'
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _promptController = TextEditingController(
    text:
        'I want to build a smart automated greenhouse. It needs to monitor soil moisture, ambient temperature, and automatically trigger 12V water pumps and ventilation fans. I want to monitor everything remotely over WiFi.',
  );
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customSpecController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  bool _isExtracting = false;
  bool _extractionComplete = false;
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

  void _handleStartExtraction() {
    setState(() {
      _isExtracting = true;
      _extractionComplete = false;
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
            ComponentOption(type: 'Standard', seller: 'Local Tech Shop', stock: 50, price: 500.0, match: '95%'),
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
            ComponentOption(type: 'Standard', seller: 'Sensor Depot', stock: 100, price: 150.0, match: '98%'),
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
            ComponentOption(type: 'Standard', seller: 'PowerHaus', stock: 30, price: 350.0, match: '99%'),
          ],
        ),
      ],
      auditLog: [
        AuditLogEntry(action: 'Extracted components from prompt', timestamp: 'Just now')
      ],
    );

    ref.read(projectsProvider.notifier).addProject(newProj);

    setState(() {
      _currentProject = newProj;
      _isExtracting = false;
      _step = 1;
    });
  }

  String _getAssistantMessage() {
    switch (_step) {
      case 0:
        return _isExtracting
            ? 'Processing your input... I am running Natural Language Processing to extract technical specifications and cross-reference them with live Agora nodes.'
            : 'Hi there! I am BiMO. Describe your hardware setup or paste a reference link, and I will generate your Bill of Materials and search local suppliers!';
      case 1:
        return 'Extraction complete! I found your parts from local suppliers. I also flagged potential logic level mismatches (ESP32 3.3V vs 5V Relays) — see warning indicator below.';
      case 2:
        return 'I found active component options in supplier warehouse stocks. Pick the specific edition, price, and condition you want for your build!';
      case 3:
        return 'Great news! I swapped out unavailable parts for equivalents, bundled items, and lowered your final price by 25%! Select my recommendations to save.';
      case 4:
      default:
        return 'Your Bill of Materials is ready! You can now download the PDF, export to Sheets, or mark the build as completed.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsState = ref.watch(projectsProvider);

    return AppScaffold(
      title: 'Build Center & BOM Management',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
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
                    style: AppTypography.displayMedium(isDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _inputMode == 'url'
                        ? 'Paste a YouTube or GitHub tutorial link to generate a localized ₱ PHP parts list & budget tracker.'
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
                          Row(
                            children: [
                              ChoiceChip(
                                label: const Text('Text Prompt'),
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
                                label: const Text('Reference URL'),
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
                              controller: _urlController,
                              style: AppTypography.bodyLarge(isDark),
                              decoration: const InputDecoration(
                                hintText: 'https://youtube.com/watch?v=... or GitHub repo URL',
                                prefixIcon: Icon(Icons.link_rounded),
                              ),
                            )
                          else
                            TextField(
                              controller: _promptController,
                              maxLines: 5,
                              style: AppTypography.bodyMedium(isDark),
                              decoration: const InputDecoration(
                                hintText: 'Describe what you want to build in detail...',
                              ),
                            ),

                          const SizedBox(height: 20),
                          GenerateButton(
                            onPressed: _handleStartExtraction,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 36),
                    Text('RECENT PROJECTS', style: AppTypography.labelUppercase()),
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
                              style: AppTypography.headingMedium(isDark).copyWith(fontSize: 15),
                            ),
                            subtitle: Text(
                              '${proj.partsCount} parts • ₱${proj.finalCost.toStringAsFixed(0)}',
                              style: AppTypography.bodySmall(isDark),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () {
                              setState(() {
                                _currentProject = proj;
                                _titleController.text = proj.title;
                                _step = 1;
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentProject!.title,
                              style: AppTypography.headingLarge(isDark),
                            ),
                            Text(
                              'Check off items as you buy them and track quantities.',
                              style: AppTypography.bodySmall(isDark),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () => setState(() => _step = 2),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('SEARCH SUPPLIERS', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        border: Border.all(color: AppColors.redAlert.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: AppColors.redAlert),
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
                      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Expanded(flex: 4, child: Text('ITEM NAME', style: AppTypography.labelUppercase())),
                              Expanded(flex: 3, child: Text('DESIRED SPEC', style: AppTypography.labelUppercase())),
                              Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.center, style: AppTypography.labelUppercase())),
                              Expanded(flex: 1, child: Text('ACTION', textAlign: TextAlign.end, style: AppTypography.labelUppercase())),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Component Rows
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _currentProject!.components.length,
                          separatorBuilder: (context, index) => const Divider(height: 1),
                          itemBuilder: (context, idx) {
                            final comp = _currentProject!.components[idx];

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 4,
                                    child: AnimatedCheckbox(
                                      label: comp.local,
                                      checked: comp.isBought,
                                      onChange: (val) {
                                        ref.read(projectsProvider.notifier).toggleBoughtComponent(_currentProject!.id, idx, val);
                                        setState(() {});
                                      },
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
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                          onPressed: () {
                                            ref.read(projectsProvider.notifier).updateComponentQty(_currentProject!.id, idx, -1);
                                            setState(() {});
                                          },
                                        ),
                                        Text(
                                          '${comp.qty}',
                                          style: AppTypography.headingMedium(isDark).copyWith(fontSize: 16),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                          onPressed: () {
                                            ref.read(projectsProvider.notifier).updateComponentQty(_currentProject!.id, idx, 1);
                                            setState(() {});
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
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.redAlert, size: 20),
                                        onPressed: () {
                                          ref.read(projectsProvider.notifier).deleteComponent(_currentProject!.id, idx);
                                          setState(() {});
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customNameController,
                          decoration: const InputDecoration(hintText: 'Custom item name...'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _customSpecController,
                          decoration: const InputDecoration(hintText: 'Custom specs...'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () {
                          if (_customNameController.text.trim().isNotEmpty) {
                            ref.read(projectsProvider.notifier).addCustomComponent(
                                  _currentProject!.id,
                                  _customNameController.text.trim(),
                                  _customSpecController.text.trim(),
                                );
                            _customNameController.clear();
                            _customSpecController.clear();
                            setState(() {});
                          }
                        },
                        child: const Text('+ Add Item'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => setState(() => _step = 0),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to Setup'),
                  ),
                ]

                // Step 2: Sourced Parts Selection
                else if (_step == 2 && _currentProject != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Sourced Parts Selection', style: AppTypography.headingLarge(isDark)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, foregroundColor: Colors.black),
                        onPressed: () => setState(() => _step = 3),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('FIND BEST DEAL', style: TextStyle(fontWeight: FontWeight.bold)),
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
                              Text(comp.local, style: AppTypography.headingMedium(isDark)),
                              Text(comp.notes, style: AppTypography.bodySmall(isDark)),
                              const SizedBox(height: 12),
                              Column(
                                children: List.generate(comp.options.length, (optIdx) {
                                  final opt = comp.options[optIdx];
                                  final isSelected = comp.selectedOptionIndex == optIdx;

                                  return InkWell(
                                    onTap: () {
                                      ref.read(projectsProvider.notifier).selectComponentOption(_currentProject!.id, idx, optIdx);
                                      setState(() {});
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.emeraldSoft : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? AppColors.emeraldLight : AppColors.darkBorder,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                            color: isSelected ? AppColors.emeraldLight : AppColors.darkTextMuted,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${comp.local} (${opt.type})', style: AppTypography.bodyMedium(isDark)),
                                                Text('Seller: ${opt.seller} • Stock: ${opt.stock} • Price: ₱${opt.price.toStringAsFixed(0)}', style: AppTypography.bodySmall(isDark)),
                                              ],
                                            ),
                                          ),
                                          Text('${opt.match} match', style: AppTypography.labelUppercase()),
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
                  TextButton.icon(
                    onPressed: () => setState(() => _step = 1),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to Checklist'),
                  ),
                ]

                // Step 3: Smart Alternatives & Deals
                else if (_step == 3 && _currentProject != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Smart Deals & Alternatives', style: AppTypography.headingLarge(isDark)),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, foregroundColor: Colors.black),
                        onPressed: () => setState(() => _step = 4),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('GO TO TRACKER SUMMARY', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      // Card 1: Standard Selections
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(projectsProvider.notifier).toggleOptimization(_currentProject!.id, false);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: !_currentProject!.isOptimized ? AppColors.emeraldLight : AppColors.darkBorder,
                                width: !_currentProject!.isOptimized ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Standard Selections', style: AppTypography.headingMedium(isDark)),
                                const SizedBox(height: 12),
                                Text('₱${_currentProject!.baseTotalCost.toStringAsFixed(0)}', style: AppTypography.displayLarge(isDark)),
                                const SizedBox(height: 12),
                                Text('• Manual component selections\n• Individual shipping fees', style: AppTypography.bodySmall(isDark)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Card 2: BiMO Recommendations
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(projectsProvider.notifier).toggleOptimization(_currentProject!.id, true);
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _currentProject!.isOptimized ? AppColors.emeraldLight : AppColors.darkBorder,
                                width: _currentProject!.isOptimized ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('BiMO AI Recommendations', style: AppTypography.headingMedium(isDark).copyWith(color: AppColors.emeraldLight)),
                                const SizedBox(height: 12),
                                Text('₱${_currentProject!.finalCost.toStringAsFixed(0)}', style: AppTypography.displayLarge(isDark).copyWith(color: AppColors.emeraldLight)),
                                const SizedBox(height: 12),
                                Text('• Equivalent board suggestions\n• Consolidated single-supplier shipping (25% Savings)', style: AppTypography.bodySmall(isDark).copyWith(color: AppColors.emeraldLight)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => setState(() => _step = 2),
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to Sourced Parts'),
                  ),
                ]

                // Step 4: Tracker Summary
                else if (_step == 4 && _currentProject != null) ...[
                  Text('Procurement Tracker Summary', style: AppTypography.headingLarge(isDark)),
                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Shopping Cart Items', style: AppTypography.headingMedium(isDark)),
                                  const SizedBox(height: 12),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _currentProject!.components.length,
                                    itemBuilder: (context, idx) {
                                      final item = _currentProject!.components[idx];
                                      return ListTile(
                                        title: Text(item.local, style: AppTypography.bodyMedium(isDark)),
                                        subtitle: Text(item.notes, style: AppTypography.bodySmall(isDark)),
                                        trailing: Text('₱${(item.totalPrice * (_currentProject!.isOptimized ? 0.75 : 1.0)).toStringAsFixed(0)}', style: AppTypography.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold, color: AppColors.emeraldLight)),
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
                                ref.read(projectsProvider.notifier).toggleCompletion(_currentProject!.id, val);
                                setState(() {});
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),

                      Expanded(
                        flex: 5,
                        child: Column(
                          children: [
                            const StoreMapVisual(locationQuery: 'Manila Agora Hardware Hub'),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Order Summary', style: AppTypography.headingMedium(isDark)),
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppColors.emerald.withOpacity(0.3)),
                                    ),
                                    child: Text(
                                      'Note: Prices are estimates and may vary by physical store. For online supplies, BiMO recommends trusted shops but does not process transactions directly.',
                                      style: AppTypography.bodySmall(isDark).copyWith(fontStyle: FontStyle.italic),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Total Cost', style: AppTypography.bodyMedium(isDark)),
                                      Text('₱${_currentProject!.finalCost.toStringAsFixed(0)}', style: AppTypography.headingLarge(isDark).copyWith(color: AppColors.emeraldLight)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.emerald, foregroundColor: Colors.black, minimumSize: const Size.fromHeight(48)),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Project saved to your Tracker!')),
                                      );
                                      context.go('/saved');
                                    },
                                    icon: const Icon(Icons.save_rounded),
                                    label: const Text('SAVE PROJECT TO TRACKER', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 10),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: isDark ? Colors.white : Colors.black,
                                      side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Saved Plan as Document (PDF/Word) - Mock')),
                                      );
                                    },
                                    icon: const Icon(Icons.picture_as_pdf_rounded),
                                    label: const Text('SAVE PLAN AS DOCUMENT (PDF)', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
