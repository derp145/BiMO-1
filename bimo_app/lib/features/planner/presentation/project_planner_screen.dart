import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../shared/layouts/app_scaffold.dart';
import '../../../shared/widgets/bomo_assistant.dart';
import '../../../shared/widgets/bimo_back_button.dart';
import '../../../shared/widgets/store_map_visual.dart';
import '../../../shared/widgets/animated_checkbox.dart';
import '../../projects/domain/models.dart';
import '../../projects/data/project_provider.dart';
import '../../../shared/widgets/bimo_notification.dart';
import 'package:latlong2/latlong.dart' as latlong;

enum UnsavedChangesAction { cancel, saveAndLeave, leaveWithoutSaving }

class ProjectPlannerScreen extends ConsumerStatefulWidget {
  const ProjectPlannerScreen({super.key});

  @override
  ConsumerState<ProjectPlannerScreen> createState() =>
      _ProjectPlannerScreenState();
}

class _ProjectPlannerScreenState extends ConsumerState<ProjectPlannerScreen> {
  late TextEditingController _titleController;
  late TextEditingController _problemController;
  late TextEditingController _customTaskController;
  late TextEditingController _customNameController;
  late TextEditingController _customSpecController;
  late TextEditingController _customPriceController;

  String _selectedCustomCategory = 'Hardware';
  String? _loadedProjectId;
  String? _customItemError;
  String? _initialTitle;
  String? _initialProblem;
  bool _isDirty = false;
  bool _isDialogShowing = false;

  bool get _hasUnsavedChanges {
    if (_loadedProjectId == null) return false;
    if (_isDirty) return true;
    if (_titleController.text.trim() != (_initialTitle ?? '').trim()) {
      return true;
    }
    if (_problemController.text.trim() != (_initialProblem ?? '').trim()) {
      return true;
    }
    return false;
  }

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
    _customPriceController = TextEditingController();
    _customNameController.addListener(_clearCustomItemErrorIfNeeded);
    _customSpecController.addListener(_clearCustomItemErrorIfNeeded);
    _titleController.addListener(_notifyTitleOrProblemChanged);
    _problemController.addListener(_notifyTitleOrProblemChanged);
  }

  void _notifyTitleOrProblemChanged() {
    if (mounted) setState(() {});
  }

  void _clearCustomItemErrorIfNeeded() {
    if (_customItemError != null) {
      final name = _customNameController.text.trim();
      final spec = _customSpecController.text.trim();
      if (name.isNotEmpty && spec.isNotEmpty) {
        setState(() {
          _customItemError = null;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final projectsState = ref.read(projectsProvider);
    final proj =
        projectsState.activeProject ??
        (projectsState.projects.isNotEmpty
            ? projectsState.projects.first
            : null);

    if (proj != null && _loadedProjectId != proj.id) {
      _loadedProjectId = proj.id;
      _titleController.text = proj.title;
      _problemController.text =
          proj.promptOrUrl ?? 'Describe the main goal of your build here.';
      _initialTitle = proj.title;
      _initialProblem =
          proj.promptOrUrl ?? 'Describe the main goal of your build here.';
      _isDirty = false;
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_notifyTitleOrProblemChanged);
    _problemController.removeListener(_notifyTitleOrProblemChanged);
    _customNameController.removeListener(_clearCustomItemErrorIfNeeded);
    _customSpecController.removeListener(_clearCustomItemErrorIfNeeded);
    _titleController.dispose();
    _problemController.dispose();
    _customTaskController.dispose();
    _customNameController.dispose();
    _customSpecController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(VoidCallback onConfirm) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Component?'),
          content: const Text(
            'Are you sure you want to remove this component from the BOM?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.redAlert),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    if (confirm == true) {
      onConfirm();
    }
  }

  Future<bool> _savePlanChanges(ProjectModel project) async {
    final updated = project.copyWith(
      title: _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : project.title,
      promptOrUrl: _problemController.text.trim().isNotEmpty
          ? _problemController.text.trim()
          : project.promptOrUrl,
      auditLog: [
        ...project.auditLog,
        AuditLogEntry(
          action: 'Updated project plan & tracker',
          timestamp: 'Just now',
        ),
      ],
    );

    final updatedSuccessfully = await _runProjectUpdate(
      () => ref.read(projectsProvider.notifier).updateProject(updated),
    );
    if (!updatedSuccessfully || !mounted) return false;

    setState(() {
      _isDirty = false;
      _initialTitle = _titleController.text.trim();
      _initialProblem = _problemController.text.trim();
    });

    showBiMONotification(
      context,
      message: 'Plan saved successfully.',
      duration: const Duration(seconds: 2),
    );
    return true;
  }

  Future<bool> _confirmLeaveIfUnsaved({VoidCallback? onLeave}) async {
    if (!_hasUnsavedChanges) {
      onLeave?.call();
      return true;
    }

    if (_isDialogShowing) return false;
    _isDialogShowing = true;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final action = await showDialog<UnsavedChangesAction>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes to this project. Would you like to save your updated project before leaving?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(UnsavedChangesAction.cancel),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(UnsavedChangesAction.leaveWithoutSaving),
              child: const Text('Leave Without Saving'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.of(
                dialogContext,
              ).pop(UnsavedChangesAction.saveAndLeave),
              child: const Text('Save & Leave'),
            ),
          ],
        );
      },
    );

    _isDialogShowing = false;

    if (action == null || action == UnsavedChangesAction.cancel) {
      return false;
    }

    if (action == UnsavedChangesAction.leaveWithoutSaving) {
      _isDirty = false;
      onLeave?.call();
      return true;
    }

    if (action == UnsavedChangesAction.saveAndLeave) {
      final currentProject = _projectForState(ref.read(projectsProvider));
      if (currentProject == null) {
        _isDirty = false;
        onLeave?.call();
        return true;
      }

      final saved = await _savePlanChanges(currentProject);
      if (saved && mounted) {
        _isDirty = false;
        onLeave?.call();
        return true;
      }
      return false;
    }

    return false;
  }

  String _formatLogTimestamp(String timestamp) {
    if (timestamp.isEmpty || timestamp == 'Just now') return 'Just now';
    final dt = DateTime.tryParse(timestamp);
    if (dt == null) return timestamp;
    final local = dt.toLocal();
    final diff = DateTime.now().difference(local);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${local.month}/${local.day}/${local.year}';
  }

  ProjectModel? _projectForState(ProjectsState state) {
    final projectId = _loadedProjectId ?? state.activeProject?.id;
    if (projectId != null) {
      for (final project in state.projects) {
        if (project.id == projectId) return project;
      }
    }

    return state.projects.isNotEmpty ? state.projects.first : null;
  }

  Future<bool> _runProjectUpdate(Future<void> Function() update) async {
    try {
      await update();
      if (mounted) {
        setState(() {
          _isDirty = true;
        });
      }
      return true;
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to save project changes.')),
        );
      }
      return false;
    }
  }

  List<MapStoreMarker> _storeMarkers(ProjectModel project) => project
      .suggestedStores
      .map((store) {
        final latitude = double.tryParse(store['lat']?.toString() ?? '');
        final longitude = double.tryParse(store['lng']?.toString() ?? '');
        if (latitude == null || longitude == null) return null;
        return MapStoreMarker(
          id: store['name']?.toString() ?? '',
          title:
              store['displayName']?.toString() ??
              store['name']?.toString() ??
              'Hardware Store',
          subtitle:
              store['reason']?.toString() ?? store['type']?.toString() ?? '',
          position: latlong.LatLng(latitude, longitude),
        );
      })
      .whereType<MapStoreMarker>()
      .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final projectsState = ref.watch(projectsProvider);
    final currentProject = _projectForState(projectsState);

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final allow = await _confirmLeaveIfUnsaved();
        if (allow && context.mounted) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/saved');
          }
        }
      },
      child: AppScaffold(
        title: 'Project Planner & Tracker',
        onBeforeNavigate: (destinationRoute) =>
            _confirmLeaveIfUnsaved(onLeave: () => context.go(destinationRoute)),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1050),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BomoAssistant(
                    message:
                        'Editing "${currentProject.title}". You can modify project details, Bill of Materials (BOM) components, task checklists, and supplier choices below.',
                  ),
                  const SizedBox(height: 12),
                  BiMOBackButton(
                    onPressed: () => _confirmLeaveIfUnsaved(
                      onLeave: () => context.go('/saved'),
                    ),
                    label: 'Back to Saved Projects',
                  ),
                  const SizedBox(height: 12),

                  // Header Title & Actions Bar
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EDITABLE PROJECT PLAN & TRACKER',
                          style: AppTypography.labelUppercase(),
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

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.emeraldLight,
                              side: const BorderSide(
                                color: AppColors.emeraldLight,
                              ),
                            ),
                            onPressed: () => _confirmLeaveIfUnsaved(
                              onLeave: () {
                                ref
                                    .read(projectsProvider.notifier)
                                    .setActiveProject(currentProject);
                                context.go(
                                  '/maker',
                                  extra: {'projectId': currentProject.id},
                                );
                              },
                            ),
                            icon: const Icon(
                              Icons.shopping_bag_outlined,
                              size: 18,
                            ),
                            label: const Text('5-Step Build Center'),
                          ),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: isDark
                                  ? Colors.white
                                  : Colors.black,
                              side: BorderSide(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.lightBorder,
                              ),
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Document export is not available yet.',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.picture_as_pdf_rounded,
                              size: 18,
                            ),
                            label: const Text('EXPORT DOC'),
                          ),
                        ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.emerald,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () => _savePlanChanges(currentProject),
                            icon: const Icon(Icons.save_rounded, size: 18),
                            label: const Text(
                              'SAVE PLAN',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'EDITABLE PROJECT PLAN & TRACKER',
                                    style: AppTypography.labelUppercase(),
                                  ),
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
                                side: const BorderSide(
                                  color: AppColors.emeraldLight,
                                ),
                              ),
                              onPressed: () {
                                _confirmLeaveIfUnsaved(
                                  onLeave: () {
                                    ref
                                        .read(projectsProvider.notifier)
                                        .setActiveProject(currentProject);
                                    context.go(
                                      '/maker',
                                      extra: {'projectId': currentProject.id},
                                    );
                                  },
                                );
                              },
                              icon: const Icon(
                                Icons.shopping_bag_outlined,
                                size: 18,
                              ),
                              label: const Text('5-Step Build Center'),
                            ),

                            const SizedBox(width: 10),

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
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Document export is not available yet.',
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.picture_as_pdf_rounded,
                                size: 18,
                              ),
                              label: const Text('EXPORT DOC'),
                            ),

                            const SizedBox(width: 10),

                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emerald,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () => _savePlanChanges(currentProject),
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: const Text(
                                'SAVE PLAN',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),

                  // Section 01: Assessed Context & Supply Chain Map
                  _buildSectionHeader(
                    '01',
                    'Assessed Project Context & Location Map',
                  ),
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'EDIT PROJECT DESCRIPTION / OBJECTIVE',
                                style: AppTypography.labelUppercase(
                                  color: AppColors.orangeWarning,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _problemController,
                                maxLines: 4,
                                style: AppTypography.bodyMedium(isDark),
                                decoration: const InputDecoration(
                                  hintText:
                                      'Describe project requirements and objectives...',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'RESOURCE ESTIMATE & BUDGET',
                                style: AppTypography.labelUppercase(
                                  color: AppColors.emeraldLight,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '\u2022 Estimated Cost: \u20B1${currentProject.baseTotalCost.toStringAsFixed(2)}\n'
                                '\u2022 Hardware Budget: \u20B1${currentProject.finalCost.toStringAsFixed(0)}\n'
                                'Bill of Materials: ${currentProject.partsCount} total components\n'
                                '\u2022 Location: ${currentProject.city ?? 'Metro Manila'}, ${currentProject.region ?? 'Philippines'}',
                                style: AppTypography.bodySmall(isDark),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          child: StoreMapVisual(
                            locationQuery:
                                currentProject.city != null &&
                                    currentProject.city!.isNotEmpty
                                ? '${currentProject.city}, ${currentProject.region ?? 'Philippines'}'
                                : 'Metro Manila, NCR',
                            markers: _storeMarkers(currentProject),
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: Container(
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'EDIT PROJECT DESCRIPTION / OBJECTIVE',
                                  style: AppTypography.labelUppercase(
                                    color: AppColors.orangeWarning,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _problemController,
                                  maxLines: 3,
                                  style: AppTypography.bodyMedium(isDark),
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Describe project requirements and objectives...',
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'RESOURCE ESTIMATE & BUDGET',
                                  style: AppTypography.labelUppercase(
                                    color: AppColors.emeraldLight,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '\u2022 Estimated Cost: \u20B1${currentProject.baseTotalCost.toStringAsFixed(2)}\n'
                                  '\u2022 Hardware Budget: \u20B1${currentProject.finalCost.toStringAsFixed(0)}\n'
                                  'Bill of Materials: ${currentProject.partsCount} total components\n'
                                  '\u2022 Location: ${currentProject.city ?? 'Metro Manila'}, ${currentProject.region ?? 'Philippines'}',
                                  style: AppTypography.bodySmall(isDark),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 16),

                        Expanded(
                          flex: 5,
                          child: StoreMapVisual(
                            locationQuery:
                                currentProject.city != null &&
                                    currentProject.city!.isNotEmpty
                                ? '${currentProject.city}, ${currentProject.region ?? 'Philippines'}'
                                : 'Metro Manila, NCR',
                            markers: _storeMarkers(currentProject),
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 32),

                  // Section 02: BOM Components Checklist & Editor
                  _buildSectionHeader(
                    '02',
                    'Bill of Materials (BOM) & Specifications',
                  ),

                  if (isMobile)
                    Column(
                      children: [
                        ...() {
                          final Map<String, List<int>> categorized = {};

                          for (
                            int i = 0;
                            i < currentProject.components.length;
                            i++
                          ) {
                            final category =
                                currentProject.components[i].category;
                            categorized.putIfAbsent(category, () => []).add(i);
                          }

                          final List<Widget> mobileCards = [];

                          for (final category in categorized.keys) {
                            mobileCards.add(
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkPanel
                                      : AppColors.lightPanel,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  category.toUpperCase(),
                                  style: AppTypography.labelUppercase(
                                    color: AppColors.emeraldLight,
                                  ),
                                ),
                              ),
                            );

                            for (final idx in categorized[category]!) {
                              final comp = currentProject.components[idx];

                              mobileCards.add(
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurface
                                        : AppColors.lightSurface,
                                    borderRadius: BorderRadius.circular(14),
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
                                      AnimatedCheckbox(
                                        label: comp.local,
                                        checked: comp.isBought,
                                        onChange: (val) async {
                                          await _runProjectUpdate(
                                            () => ref
                                                .read(projectsProvider.notifier)
                                                .toggleBoughtComponent(
                                                  currentProject.id,
                                                  idx,
                                                  val,
                                                ),
                                          );
                                        },
                                      ),

                                      const SizedBox(height: 12),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'EST. UNIT PRICE',
                                                  style:
                                                      AppTypography.labelUppercase(),
                                                ),
                                                const SizedBox(height: 4),
                                                if (comp.isCustom) ...[
                                                  TextFormField(
                                                    key: ValueKey(
                                                      'est-m-${currentProject.id}-${componentIdentity(comp)}',
                                                    ),
                                                    initialValue:
                                                        comp.customEstimatedPrice !=
                                                            null
                                                        ? comp.customEstimatedPrice!
                                                              .toStringAsFixed(
                                                                2,
                                                              )
                                                        : '',
                                                    decoration:
                                                        const InputDecoration(
                                                          prefixText: '\u20B1',
                                                          hintText: '0.00',
                                                          isDense: true,
                                                          contentPadding:
                                                              EdgeInsets.all(8),
                                                        ),
                                                    style:
                                                        AppTypography.bodySmall(
                                                          isDark,
                                                        ),
                                                    keyboardType:
                                                        const TextInputType.numberWithOptions(
                                                          decimal: true,
                                                        ),
                                                    inputFormatters: [
                                                      FilteringTextInputFormatter.allow(
                                                        RegExp(
                                                          r'^\d*\.?\d{0,2}',
                                                        ),
                                                      ),
                                                    ],
                                                    onChanged: (val) {
                                                      final parsed =
                                                          double.tryParse(
                                                            val,
                                                          ) ??
                                                          0.0;
                                                      _runProjectUpdate(
                                                        () => ref
                                                            .read(
                                                              projectsProvider
                                                                  .notifier,
                                                            )
                                                            .updateCustomComponentPrice(
                                                              currentProject.id,
                                                              idx,
                                                              parsed,
                                                            ),
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '\u20B1${comp.totalPrice.toStringAsFixed(2)} total',
                                                    style:
                                                        AppTypography.bodySmall(
                                                          isDark,
                                                        ),
                                                  ),
                                                ] else ...[
                                                  Text(
                                                    '\u20B1${comp.unitPrice.toStringAsFixed(2)} / unit\n'
                                                    '\u20B1${comp.totalPrice.toStringAsFixed(2)} total',
                                                    style:
                                                        AppTypography.bodyMedium(
                                                          isDark,
                                                        ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'ACTUAL UNIT COST',
                                                  style:
                                                      AppTypography.labelUppercase(),
                                                ),
                                                const SizedBox(height: 4),
                                                TextFormField(
                                                  key: ValueKey(
                                                    '${currentProject.id}-${componentIdentity(comp)}',
                                                  ),
                                                  initialValue: comp.actualCost
                                                      ?.toStringAsFixed(2),
                                                  decoration:
                                                      const InputDecoration(
                                                        hintText: '\u20B10.00',
                                                        isDense: true,
                                                        contentPadding:
                                                            EdgeInsets.all(10),
                                                      ),
                                                  style:
                                                      AppTypography.bodySmall(
                                                        isDark,
                                                      ),
                                                  keyboardType:
                                                      const TextInputType.numberWithOptions(
                                                        decimal: true,
                                                      ),
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter.allow(
                                                      RegExp(r'^\d*\.?\d{0,2}'),
                                                    ),
                                                  ],
                                                  onChanged: (value) {
                                                    final actualCost =
                                                        double.tryParse(value);
                                                    if (actualCost == null) {
                                                      return;
                                                    }
                                                    _runProjectUpdate(
                                                      () => ref
                                                          .read(
                                                            projectsProvider
                                                                .notifier,
                                                          )
                                                          .updateComponentActualCost(
                                                            currentProject.id,
                                                            idx,
                                                            actualCost,
                                                          ),
                                                    );
                                                  },
                                                ),
                                                if (comp.actualTotal != null)
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          top: 4,
                                                        ),
                                                    child: Text(
                                                      '\u20B1${comp.actualTotal!.toStringAsFixed(2)} total',
                                                      style:
                                                          AppTypography.bodySmall(
                                                            isDark,
                                                          ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      Row(
                                        children: [
                                          Text(
                                            'QTY',
                                            style:
                                                AppTypography.labelUppercase(),
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
                                              Icons
                                                  .remove_circle_outline_rounded,
                                              size: 20,
                                            ),
                                            onPressed: () async {
                                              await _runProjectUpdate(
                                                () => ref
                                                    .read(
                                                      projectsProvider.notifier,
                                                    )
                                                    .updateComponentQty(
                                                      currentProject.id,
                                                      idx,
                                                      -1,
                                                    ),
                                              );
                                            },
                                          ),

                                          SizedBox(
                                            width: 28,
                                            child: Text(
                                              '${comp.qty}',
                                              textAlign: TextAlign.center,
                                              style:
                                                  AppTypography.headingMedium(
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
                                            onPressed: () async {
                                              await _runProjectUpdate(
                                                () => ref
                                                    .read(
                                                      projectsProvider.notifier,
                                                    )
                                                    .updateComponentQty(
                                                      currentProject.id,
                                                      idx,
                                                      1,
                                                    ),
                                              );
                                            },
                                          ),

                                          const SizedBox(width: 4),

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
                                            onPressed: () async {
                                              _confirmDelete(() async {
                                                await _runProjectUpdate(
                                                  () => ref
                                                      .read(
                                                        projectsProvider
                                                            .notifier,
                                                      )
                                                      .deleteComponent(
                                                        currentProject.id,
                                                        idx,
                                                      ),
                                                );
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          }

                          return mobileCards;
                        }(),
                      ],
                    )
                  else
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
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'COMPONENT / CATEGORY',
                                    style: AppTypography.labelUppercase(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'EST. UNIT PRICE',
                                    style: AppTypography.labelUppercase(),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'ACTUAL COST',
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

                          ...() {
                            final Map<String, List<int>> categorized = {};

                            for (
                              int i = 0;
                              i < currentProject.components.length;
                              i++
                            ) {
                              final c = currentProject.components[i].category;
                              categorized.putIfAbsent(c, () => []).add(i);
                            }

                            final List<Widget> rows = [];

                            for (final cat in categorized.keys) {
                              rows.add(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  color: isDark
                                      ? AppColors.darkPanel
                                      : AppColors.lightPanel,
                                  width: double.infinity,
                                  child: Text(
                                    cat.toUpperCase(),
                                    style: AppTypography.labelUppercase(
                                      color: AppColors.emeraldLight,
                                    ),
                                  ),
                                ),
                              );

                              rows.add(const Divider(height: 1));

                              for (final idx in categorized[cat]!) {
                                final comp = currentProject.components[idx];

                                rows.add(
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 12.0,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: AnimatedCheckbox(
                                            label: comp.local,
                                            checked: comp.isBought,
                                            onChange: (val) async {
                                              await _runProjectUpdate(
                                                () => ref
                                                    .read(
                                                      projectsProvider.notifier,
                                                    )
                                                    .toggleBoughtComponent(
                                                      currentProject.id,
                                                      idx,
                                                      val,
                                                    ),
                                              );
                                            },
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: comp.isCustom
                                              ? Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    TextFormField(
                                                      key: ValueKey(
                                                        'est-d-${currentProject.id}-${componentIdentity(comp)}',
                                                      ),
                                                      initialValue:
                                                          comp.customEstimatedPrice !=
                                                              null
                                                          ? comp.customEstimatedPrice!
                                                                .toStringAsFixed(
                                                                  2,
                                                                )
                                                          : '',
                                                      decoration:
                                                          const InputDecoration(
                                                            prefixText:
                                                                '\u20B1',
                                                            hintText: '0.00',
                                                            isDense: true,
                                                            contentPadding:
                                                                EdgeInsets.all(
                                                                  8,
                                                                ),
                                                          ),
                                                      style:
                                                          AppTypography.bodySmall(
                                                            isDark,
                                                          ),
                                                      keyboardType:
                                                          const TextInputType.numberWithOptions(
                                                            decimal: true,
                                                          ),
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.allow(
                                                          RegExp(
                                                            r'^\d*\.?\d{0,2}',
                                                          ),
                                                        ),
                                                      ],
                                                      onChanged: (val) {
                                                        final parsed =
                                                            double.tryParse(
                                                              val,
                                                            ) ??
                                                            0.0;
                                                        _runProjectUpdate(
                                                          () => ref
                                                              .read(
                                                                projectsProvider
                                                                    .notifier,
                                                              )
                                                              .updateCustomComponentPrice(
                                                                currentProject
                                                                    .id,
                                                                idx,
                                                                parsed,
                                                              ),
                                                        );
                                                      },
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '\u20B1${comp.totalPrice.toStringAsFixed(2)} total',
                                                      style:
                                                          AppTypography.bodySmall(
                                                            isDark,
                                                          ),
                                                    ),
                                                  ],
                                                )
                                              : Text(
                                                  '\u20B1${comp.unitPrice.toStringAsFixed(2)} / unit\n'
                                                  '\u20B1${comp.totalPrice.toStringAsFixed(2)} total',
                                                  style:
                                                      AppTypography.bodySmall(
                                                        isDark,
                                                      ),
                                                ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              TextFormField(
                                                key: ValueKey(
                                                  '${currentProject.id}-${componentIdentity(comp)}',
                                                ),
                                                initialValue: comp.actualCost
                                                    ?.toStringAsFixed(2),
                                                decoration:
                                                    const InputDecoration(
                                                      hintText: '\u20B10.00',
                                                      isDense: true,
                                                      contentPadding:
                                                          EdgeInsets.all(8),
                                                    ),
                                                style: AppTypography.bodySmall(
                                                  isDark,
                                                ),
                                                keyboardType:
                                                    const TextInputType.numberWithOptions(
                                                      decimal: true,
                                                    ),
                                                inputFormatters: [
                                                  FilteringTextInputFormatter.allow(
                                                    RegExp(r'^\d*\.?\d{0,2}'),
                                                  ),
                                                ],
                                                onChanged: (value) {
                                                  final actualCost =
                                                      double.tryParse(value);
                                                  if (actualCost == null) {
                                                    return;
                                                  }
                                                  _runProjectUpdate(
                                                    () => ref
                                                        .read(
                                                          projectsProvider
                                                              .notifier,
                                                        )
                                                        .updateComponentActualCost(
                                                          currentProject.id,
                                                          idx,
                                                          actualCost,
                                                        ),
                                                  );
                                                },
                                              ),
                                              if (comp.actualTotal != null)
                                                Text(
                                                  '\u20B1${comp.actualTotal!.toStringAsFixed(2)} total',
                                                  style:
                                                      AppTypography.bodySmall(
                                                        isDark,
                                                      ),
                                                ),
                                            ],
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
                                                  Icons
                                                      .remove_circle_outline_rounded,
                                                  size: 20,
                                                ),
                                                onPressed: () async {
                                                  await _runProjectUpdate(
                                                    () => ref
                                                        .read(
                                                          projectsProvider
                                                              .notifier,
                                                        )
                                                        .updateComponentQty(
                                                          currentProject.id,
                                                          idx,
                                                          -1,
                                                        ),
                                                  );
                                                },
                                              ),
                                              Text(
                                                '${comp.qty}',
                                                style:
                                                    AppTypography.headingMedium(
                                                      isDark,
                                                    ).copyWith(fontSize: 16),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons
                                                      .add_circle_outline_rounded,
                                                  size: 20,
                                                ),
                                                onPressed: () async {
                                                  await _runProjectUpdate(
                                                    () => ref
                                                        .read(
                                                          projectsProvider
                                                              .notifier,
                                                        )
                                                        .updateComponentQty(
                                                          currentProject.id,
                                                          idx,
                                                          1,
                                                        ),
                                                  );
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
                                              onPressed: () async {
                                                _confirmDelete(() async {
                                                  await _runProjectUpdate(
                                                    () => ref
                                                        .read(
                                                          projectsProvider
                                                              .notifier,
                                                        )
                                                        .deleteComponent(
                                                          currentProject.id,
                                                          idx,
                                                        ),
                                                  );
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                  if (isMobile)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _customNameController,
                          decoration: const InputDecoration(
                            hintText:
                                'Add custom Bill of Materials item name...',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customSpecController,
                          decoration: const InputDecoration(
                            hintText: 'Component spec / attributes...',
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _customPriceController,
                          decoration: const InputDecoration(
                            hintText:
                                'Estimated Unit Price (\u20B1) (optional)...',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCustomCategory,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                          dropdownColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 20,
                          ),
                          items: bomCategories.map((cat) {
                            return DropdownMenuItem<String>(
                              value: cat,
                              child: Text(
                                cat,
                                style: AppTypography.bodyMedium(isDark),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCustomCategory = val);
                            }
                          },
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.emeraldSoft,
                            foregroundColor: AppColors.emeraldLight,
                          ),
                          onPressed: () async {
                            final name = _customNameController.text.trim();
                            final spec = _customSpecController.text.trim();
                            final priceText = _customPriceController.text
                                .trim();
                            final estPrice = priceText.isNotEmpty
                                ? double.tryParse(priceText)
                                : null;

                            if (name.isEmpty && spec.isEmpty) {
                              setState(() {
                                _customItemError =
                                    'Please fill in the required fields.';
                              });
                              return;
                            }
                            if (name.isEmpty) {
                              setState(() {
                                _customItemError =
                                    'Component name is required.';
                              });
                              return;
                            }
                            if (spec.isEmpty) {
                              setState(() {
                                _customItemError = 'Specification is required.';
                              });
                              return;
                            }

                            setState(() {
                              _customItemError = null;
                            });

                            final added = await _runProjectUpdate(
                              () => ref
                                  .read(projectsProvider.notifier)
                                  .addCustomComponent(
                                    currentProject.id,
                                    name,
                                    spec,
                                    category: _selectedCustomCategory,
                                    estimatedUnitPrice: estPrice,
                                  ),
                            );
                            if (!added || !mounted) return;
                            _customNameController.clear();
                            _customSpecController.clear();
                            _customPriceController.clear();
                            setState(
                              () => _selectedCustomCategory = 'Hardware',
                            );
                          },
                          child: const Text('+ Add Item'),
                        ),
                        if (_customItemError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _customItemError!,
                            style: const TextStyle(
                              color: AppColors.redAlert,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _customNameController,
                                decoration: const InputDecoration(
                                  hintText:
                                      'Add custom Bill of Materials item name...',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _customSpecController,
                                decoration: const InputDecoration(
                                  hintText: 'Component spec / attributes...',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: _customPriceController,
                                decoration: const InputDecoration(
                                  hintText: 'Est. Price (\u20B1)...',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d{0,2}'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: _selectedCustomCategory,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                                dropdownColor: isDark
                                    ? AppColors.darkSurface
                                    : AppColors.lightSurface,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 20,
                                ),
                                items: bomCategories.map((cat) {
                                  return DropdownMenuItem<String>(
                                    value: cat,
                                    child: Text(
                                      cat,
                                      style: AppTypography.bodyMedium(isDark),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(
                                      () => _selectedCustomCategory = val,
                                    );
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emeraldSoft,
                                foregroundColor: AppColors.emeraldLight,
                              ),
                              onPressed: () async {
                                final name = _customNameController.text.trim();
                                final spec = _customSpecController.text.trim();
                                final priceText = _customPriceController.text
                                    .trim();
                                final estPrice = priceText.isNotEmpty
                                    ? double.tryParse(priceText)
                                    : null;

                                if (name.isEmpty && spec.isEmpty) {
                                  setState(() {
                                    _customItemError =
                                        'Please fill in the required fields.';
                                  });
                                  return;
                                }
                                if (name.isEmpty) {
                                  setState(() {
                                    _customItemError =
                                        'Component name is required.';
                                  });
                                  return;
                                }
                                if (spec.isEmpty) {
                                  setState(() {
                                    _customItemError =
                                        'Specification is required.';
                                  });
                                  return;
                                }

                                setState(() {
                                  _customItemError = null;
                                });

                                final added = await _runProjectUpdate(
                                  () => ref
                                      .read(projectsProvider.notifier)
                                      .addCustomComponent(
                                        currentProject.id,
                                        name,
                                        spec,
                                        category: _selectedCustomCategory,
                                        estimatedUnitPrice: estPrice,
                                      ),
                                );
                                if (!added || !mounted) return;
                                _customNameController.clear();
                                _customSpecController.clear();
                                _customPriceController.clear();
                                setState(
                                  () => _selectedCustomCategory = 'Hardware',
                                );
                              },
                              child: const Text('+ Add Item'),
                            ),
                          ],
                        ),
                        if (_customItemError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _customItemError!,
                            style: const TextStyle(
                              color: AppColors.redAlert,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),

                  const SizedBox(height: 32),

                  // Section 03: Deployment Checklist Tracker
                  // Section 03: Build Instructions & Guide
                  _buildSectionHeader(
                    '03',
                    'Step-by-Step Build & Wiring Guide',
                  ),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentProject.buildInstructions.isEmpty)
                          Text(
                            'No build instructions generated.',
                            style: AppTypography.bodyMedium(isDark),
                          )
                        else
                          ...currentProject.buildInstructions.map(
                            (instruction) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: AppColors.emeraldLight,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      instruction,
                                      style: AppTypography.bodyMedium(isDark),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Audit Log Section
                  _buildSectionHeader('04', 'Project Activity Log'),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkPanel
                          : AppColors.lightPanel,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        final now = DateTime.now();
                        final recentLogs = currentProject.auditLog
                            .where((log) {
                              if (log.timestamp == 'Just now') return true;
                              final dt = DateTime.tryParse(log.timestamp);
                              if (dt == null) return true;
                              return now.difference(dt).inDays <= 15;
                            })
                            .toList()
                            .reversed
                            .toList();

                        if (recentLogs.isEmpty) {
                          return Text(
                            'No recent activity.',
                            style: AppTypography.bodyMedium(isDark),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: recentLogs.length,
                          itemBuilder: (context, idx) {
                            final log = recentLogs[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4.0,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.history_rounded,
                                    size: 16,
                                    color: AppColors.emeraldLight,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      log.action,
                                      style: AppTypography.bodySmall(isDark),
                                    ),
                                  ),
                                  Text(
                                    _formatLogTimestamp(log.timestamp),
                                    style: AppTypography.bodySmall(
                                      isDark,
                                    ).copyWith(fontSize: 10),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emeraldSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(num, style: AppTypography.labelUppercase()),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              title.toUpperCase(),
              style: AppTypography.headingMedium(isDark),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}
