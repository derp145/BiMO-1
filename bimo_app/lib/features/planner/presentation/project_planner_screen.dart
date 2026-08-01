import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/bomo_assistant.dart';
import '../../../shared/widgets/store_map_visual.dart';
import '../../../shared/widgets/animated_checkbox.dart';
import '../../../shared/widgets/compatibility_alert.dart';
import '../../projects/domain/models.dart';
import '../../projects/data/project_provider.dart';

class ProjectPlannerScreen extends ConsumerStatefulWidget {
  const ProjectPlannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProjectPlannerScreen> createState() => _ProjectPlannerScreenState();
}

class _ProjectPlannerScreenState extends ConsumerState<ProjectPlannerScreen> {
  late TextEditingController _titleController;
  late TextEditingController _problemController;
  late TextEditingController _customTaskController;
  late TextEditingController _customNameController;
  late TextEditingController _customSpecController;

  ProjectModel? _loadedProject;
  final Set<String> _checkedTasks = <String>{};
  final List<String> _customTasks = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _problemController = TextEditingController(
      text: 'Describe the main goal of your build here.',
    );
    _customTaskController = TextEditingController();
    _customNameController = TextEditingController();
    _customSpecController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final projectsState = ref.watch(projectsProvider);
    final proj = projectsState.activeProject ??
        (projectsState.projects.isNotEmpty ? projectsState.projects.first : null);

    if (proj != null && _loadedProject?.id != proj.id) {
      _loadedProject = proj;
      _titleController.text = proj.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _problemController.dispose();
    _customTaskController.dispose();
    _customNameController.dispose();
    _customSpecController.dispose();
    super.dispose();
  }

  void _savePlanChanges() {
    if (_loadedProject == null) return;

    final updated = _loadedProject!.copyWith(
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : _loadedProject!.title,
      auditLog: [
        ..._loadedProject!.auditLog,
        AuditLogEntry(action: 'Updated project plan & tracker', timestamp: 'Just now')
      ],
    );

    ref.read(projectsProvider.notifier).updateProject(updated);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Project Plan & Tracker Changes Saved!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final projectsState = ref.watch(projectsProvider);
    final currentProject = _loadedProject ?? projectsState.activeProject ??
        (projectsState.projects.isNotEmpty ? projectsState.projects.first : null);

    if (currentProject == null) {
      return AppScaffold(
        title: 'Project Planner & Tracker',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('No active project selected.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/saved'),
                child: const Text('Go to Saved Projects'),
              ),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Project Planner & Tracker',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BomoAssistant(
                  message:
                      'Editing "${currentProject.title}". You can modify project details, BOM components, task checklists, and supplier choices below.',
                ),

                // Header Title & Actions Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('EDITABLE PROJECT PLAN & TRACKER', style: AppTypography.labelUppercase()),
                              const SizedBox(height: 4),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _titleController,
                            style: AppTypography.displayMedium(isDark),
                            decoration: const InputDecoration(
                              hintText: 'Project Name...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.emeraldLight,
                            side: const BorderSide(color: AppColors.emeraldLight),
                          ),
                          onPressed: () {
                            ref.read(projectsProvider.notifier).setActiveProject(currentProject);
                            context.go('/maker');
                          },
                          icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                          label: const Text('5-Step Build Center'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : Colors.black,
                            side: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Saved Plan as Document (PDF/Word) - Mock')),
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                          label: const Text('EXPORT DOC'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emerald,
                            foregroundColor: Colors.black,
                          ),
                          onPressed: _savePlanChanges,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('SAVE PLAN', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Section 01: Assessed Context & Supply Chain Map
                _buildSectionHeader('01', 'Assessed Project Context & Location Map'),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('EDIT PROJECT DESCRIPTION / OBJECTIVE', style: AppTypography.labelUppercase(color: AppColors.orangeWarning)),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _problemController,
                              maxLines: 3,
                              style: AppTypography.bodyMedium(isDark),
                              decoration: const InputDecoration(
                                hintText: 'Describe project requirements and objectives...',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text('RESOURCE ESTIMATE & BUDGET', style: AppTypography.labelUppercase(color: AppColors.emeraldLight)),
                            const SizedBox(height: 6),
                            Text('• Hardware Budget: ₱${currentProject.finalCost.toStringAsFixed(0)}\n• Component Count: ${currentProject.partsCount} BOM Items\n• Location: Manila Hardware Agora Hub', style: AppTypography.bodySmall(isDark)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      flex: 5,
                      child: StoreMapVisual(locationQuery: 'Metro Manila, NCR'),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Section 02: BOM Components Checklist & Editor
                _buildSectionHeader('02', 'BOM Components Checklist & Specifications'),
                
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text('COMPONENT / CATEGORY', style: AppTypography.labelUppercase())),
                            Expanded(flex: 2, child: Text('EST. PRICE', style: AppTypography.labelUppercase())),
                            Expanded(flex: 2, child: Text('ACTUAL COST', style: AppTypography.labelUppercase())),
                            Expanded(flex: 2, child: Text('QTY', textAlign: TextAlign.center, style: AppTypography.labelUppercase())),
                            Expanded(flex: 1, child: Text('ACTION', textAlign: TextAlign.end, style: AppTypography.labelUppercase())),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Categorize components
                      ...() {
                        final Map<String, List<int>> categorized = {};
                        for (int i = 0; i < currentProject.components.length; i++) {
                          final c = currentProject.components[i].category;
                          categorized.putIfAbsent(c, () => []).add(i);
                        }

                        final List<Widget> rows = [];
                        for (final cat in categorized.keys) {
                          rows.add(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
                            width: double.infinity,
                            child: Text(cat.toUpperCase(), style: AppTypography.labelUppercase(color: AppColors.emeraldLight)),
                          ));
                          rows.add(const Divider(height: 1));

                          for (final idx in categorized[cat]!) {
                            final comp = currentProject.components[idx];
                            rows.add(
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: AnimatedCheckbox(
                                        label: comp.local,
                                        checked: comp.isBought,
                                        onChange: (val) {
                                          ref.read(projectsProvider.notifier).toggleBoughtComponent(currentProject.id, idx, val);
                                          setState(() {});
                                        },
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text('₱${comp.unitPrice.toStringAsFixed(2)}', style: AppTypography.bodySmall(isDark)),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: TextField(
                                        decoration: const InputDecoration(
                                          hintText: '₱ 0.00',
                                          isDense: true,
                                          contentPadding: EdgeInsets.all(8),
                                        ),
                                        style: AppTypography.bodySmall(isDark),
                                        keyboardType: TextInputType.number,
                                        onChanged: (val) {
                                          // Update actualCost in a real app, omitted for brevity
                                        },
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
                                              ref.read(projectsProvider.notifier).updateComponentQty(currentProject.id, idx, -1);
                                              setState(() {});
                                            },
                                          ),
                                          Text('${comp.qty}', style: AppTypography.headingMedium(isDark).copyWith(fontSize: 16)),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                            onPressed: () {
                                              ref.read(projectsProvider.notifier).updateComponentQty(currentProject.id, idx, 1);
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
                                            ref.read(projectsProvider.notifier).deleteComponent(currentProject.id, idx);
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            );
                            rows.add(const Divider(height: 1));
                          }
                        }
                        return rows;
                      }(),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Add Custom Component Control
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customNameController,
                        decoration: const InputDecoration(hintText: 'Add custom BOM item name...'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _customSpecController,
                        decoration: const InputDecoration(hintText: 'Component spec / attributes...'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.emeraldSoft, foregroundColor: AppColors.emeraldLight),
                      onPressed: () {
                        if (_customNameController.text.trim().isNotEmpty) {
                          ref.read(projectsProvider.notifier).addCustomComponent(
                                currentProject.id,
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

                const SizedBox(height: 32),

                // Section 03: Deployment Checklist Tracker
                // Section 03: Build Instructions & Guide
                _buildSectionHeader('03', 'Step-by-Step Build & Wiring Guide'),
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
                      if (currentProject.buildInstructions.isEmpty)
                        Text('No build instructions generated.', style: AppTypography.bodyMedium(isDark))
                      else
                        ...currentProject.buildInstructions.map((instruction) => Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.circle, size: 8, color: AppColors.emeraldLight),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(instruction, style: AppTypography.bodyMedium(isDark)),
                              ),
                            ],
                          ),
                        )),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Audit Log Section
                _buildSectionHeader('04', 'Project Activity Log'),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPanel : AppColors.lightPanel,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: currentProject.auditLog.length,
                    itemBuilder: (context, idx) {
                      final log = currentProject.auditLog[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          children: [
                            const Icon(Icons.history_rounded, size: 16, color: AppColors.emeraldLight),
                            const SizedBox(width: 10),
                            Expanded(child: Text(log.action, style: AppTypography.bodySmall(isDark))),
                            Text(log.timestamp, style: AppTypography.bodySmall(isDark).copyWith(fontSize: 10)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String num, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.emeraldSoft, borderRadius: BorderRadius.circular(6)),
            child: Text(num, style: AppTypography.labelUppercase()),
          ),
          const SizedBox(width: 10),
          Text(title.toUpperCase(), style: AppTypography.headingMedium(isDark)),
        ],
      ),
    );
  }
}
