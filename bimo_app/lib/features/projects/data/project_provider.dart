import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models.dart';
import 'project_repository.dart';

const int trashRetentionDays = 15;
const Duration trashRetentionDuration = Duration(days: trashRetentionDays);

List<ProjectModel> _removeExpiredTrash(
  List<ProjectModel> projects,
  DateTime now,
) => projects.where((project) {
  final deletedAt = project.deletedAt;
  return deletedAt == null ||
      now.isBefore(deletedAt.add(trashRetentionDuration));
}).toList();

class ProjectsState {
  static const _unchanged = Object();
  final List<ProjectModel> projects;
  final String activeTab;
  final ProjectModel? activeProject;
  final bool isLoading;

  ProjectsState({
    required this.projects,
    this.activeTab = 'engineering',
    this.activeProject,
    this.isLoading = false,
  });

  ProjectsState copyWith({
    List<ProjectModel>? projects,
    String? activeTab,
    Object? activeProject = _unchanged,
    bool? isLoading,
  }) => ProjectsState(
    projects: projects ?? this.projects,
    activeTab: activeTab ?? this.activeTab,
    activeProject: identical(activeProject, _unchanged)
        ? this.activeProject
        : activeProject as ProjectModel?,
    isLoading: isLoading ?? this.isLoading,
  );

  List<ProjectModel> get filteredProjects {
    if (activeTab == 'trash') {
      return projects.where((p) => p.deletedAt != null).toList();
    }
    final activeItems = projects.where((p) => p.deletedAt == null).toList();
    if (activeTab == 'electronics') {
      return activeItems.where((p) => p.category == 'electronics').toList();
    }
    return activeItems
        .where((p) => p.category == 'engineering' || p.category == 'hardware')
        .toList();
  }

  int get engineeringCount => projects
      .where(
        (p) =>
            p.deletedAt == null &&
            (p.category == 'engineering' || p.category == 'hardware'),
      )
      .length;
  int get electronicsCount => projects
      .where((p) => p.deletedAt == null && p.category == 'electronics')
      .length;
  int get trashCount => projects.where((p) => p.deletedAt != null).length;
}

class ProjectsNotifier extends StateNotifier<ProjectsState> {
  ProjectsNotifier({ProjectRepository? repository})
    : _repository = repository ?? SupabaseProjectRepository(),
      super(ProjectsState(projects: const [])) {
    if (repository == null) {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((authState) {
            if (authState.session == null) {
              state = ProjectsState(
                projects: const [],
                activeTab: state.activeTab,
              );
            } else {
              unawaited(loadProjects());
            }
          });
      if (Supabase.instance.client.auth.currentUser != null) {
        unawaited(loadProjects());
      }
    }
  }

  final ProjectRepository _repository;
  StreamSubscription<AuthState>? _authSubscription;
  int _stateVersion = 0;
  final Map<String, Future<void>> _projectWrites = {};

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadProjects() async {
    final loadVersion = _stateVersion;
    state = state.copyWith(isLoading: true);
    try {
      final projects = await _repository.fetchProjects();
      if (loadVersion == _stateVersion) {
        state = state.copyWith(
          projects: _removeExpiredTrash(projects, DateTime.now()),
          isLoading: false,
        );
      }
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setActiveTab(String tab) => state = state.copyWith(activeTab: tab);
  void setActiveProject(ProjectModel? project) =>
      state = state.copyWith(activeProject: project);

  Future<ProjectModel> addProject(ProjectModel project) async {
    final normalized = project.copyWith(
      components: normalizeComponents(project.components),
    );
    _stateVersion++;
    final saved = await _repository.createProject(normalized);
    state = state.copyWith(projects: [saved, ...state.projects]);
    return saved;
  }

  Future<void> cleanupExpiredTrash() async {
    final expired = state.projects.where((project) {
      final deletedAt = project.deletedAt;
      return deletedAt != null &&
          !DateTime.now().isBefore(deletedAt.add(trashRetentionDuration));
    }).toList();
    if (expired.isEmpty) return;
    state = state.copyWith(
      projects: _removeExpiredTrash(state.projects, DateTime.now()),
    );
    for (final project in expired) {
      await _repository.deleteProject(project.id);
    }
  }

  Future<ProjectModel> updateProject(ProjectModel updated) async {
    final normalized = updated.copyWith(
      components: normalizeComponents(updated.components),
    );
    final previous = state.projects.firstWhere(
      (project) => project.id == normalized.id,
    );
    final newLogs = normalized.auditLog.skip(previous.auditLog.length).toList();
    final version = ++_stateVersion;
    _replaceProject(normalized);
    final pendingWrite = _projectWrites[normalized.id] ?? Future<void>.value();
    final write = pendingWrite
        .catchError((_) {})
        .then(
          (_) => _repository.updateProject(normalized, activityLogs: newLogs),
        );
    final writeGate = write.then<void>((_) {}, onError: (_, _) {});
    _projectWrites[normalized.id] = writeGate;
    try {
      final saved = await write;
      if (version == _stateVersion) _replaceProject(saved);
      return saved;
    } catch (_) {
      if (version == _stateVersion) _replaceProject(previous);
      rethrow;
    } finally {
      if (identical(_projectWrites[normalized.id], writeGate)) {
        _projectWrites.remove(normalized.id);
      }
    }
  }

  Future<void> softDeleteProject(String id) async {
    _stateVersion++;
    final previous = state.projects.firstWhere((project) => project.id == id);
    final log = AuditLogEntry(
      action: 'Moved project to trash archive',
      timestamp: 'Just now',
    );
    final updated = previous.copyWith(auditLog: [...previous.auditLog, log]);
    updated.deletedAt = DateTime.now();
    _replaceProject(updated);
    try {
      await _repository.moveToTrash(id, log);
    } catch (_) {
      _replaceProject(previous);
      rethrow;
    }
  }

  Future<void> restoreProject(String id) async {
    _stateVersion++;
    final previous = state.projects.firstWhere((project) => project.id == id);
    final log = AuditLogEntry(
      action: 'Restored project from trash archive',
      timestamp: 'Just now',
    );
    final updated = previous.copyWith(auditLog: [...previous.auditLog, log]);
    updated.deletedAt = null;
    _replaceProject(updated);
    try {
      await _repository.restoreProject(id, log);
    } catch (_) {
      _replaceProject(previous);
      rethrow;
    }
  }

  Future<void> hardDeleteProject(String id) async {
    final previous = state.projects.firstWhere((project) => project.id == id);
    _stateVersion++;
    state = state.copyWith(
      projects: state.projects.where((project) => project.id != id).toList(),
      activeProject: state.activeProject?.id == id ? null : state.activeProject,
    );
    try {
      await _repository.deleteProject(id);
    } catch (_) {
      state = state.copyWith(projects: [previous, ...state.projects]);
      rethrow;
    }
  }

  Future<void> updateComponentQty(
    String projectId,
    int componentIndex,
    int delta,
  ) async {
    final project = state.projects.firstWhere((item) => item.id == projectId);
    if (componentIndex < 0 || componentIndex >= project.components.length) {
      return;
    }
    final component = project.components[componentIndex];
    final quantity = component.qty + delta;
    if (quantity <= 0) return;
    final components = List<BOMComponent>.from(project.components);
    components[componentIndex] = component.copyWith(qty: quantity);
    await updateProject(
      project.copyWith(
        components: components,
        auditLog: [
          ...project.auditLog,
          AuditLogEntry(
            action: 'Updated ${component.local} quantity to $quantity',
            timestamp: 'Just now',
          ),
        ],
      ),
    );
  }

  Future<void> deleteComponent(String projectId, int componentIndex) async {
    final project = state.projects.firstWhere((item) => item.id == projectId);
    if (componentIndex < 0 || componentIndex >= project.components.length) {
      return;
    }
    final component = project.components[componentIndex];
    final components = List<BOMComponent>.from(project.components)
      ..removeAt(componentIndex);
    await updateProject(
      project.copyWith(
        components: components,
        auditLog: [
          ...project.auditLog,
          AuditLogEntry(
            action: 'Removed ${component.local} from BOM list',
            timestamp: 'Just now',
          ),
        ],
      ),
    );
  }

  Future<void> toggleBoughtComponent(
    String projectId,
    int componentIndex,
    bool isBought,
  ) async {
    final project = state.projects.firstWhere((item) => item.id == projectId);
    if (componentIndex < 0 || componentIndex >= project.components.length) {
      return;
    }
    final components = List<BOMComponent>.from(project.components);
    components[componentIndex] = components[componentIndex].copyWith(
      isBought: isBought,
    );
    await updateProject(project.copyWith(components: components));
  }

  Future<void> addCustomComponent(
    String projectId,
    String name,
    String spec, {
    String category = 'Hardware',
    double? estimatedUnitPrice,
  }) async {
    final project = state.projects.firstWhere((item) => item.id == projectId);
    final chosenCategory = category.trim().isNotEmpty
        ? category.trim()
        : 'Hardware';
    final component = BOMComponent(
      orig: name,
      local: name,
      category: chosenCategory,
      notes: spec.isNotEmpty ? spec : 'Custom user specification',
      isCustom: true,
      customEstimatedPrice: estimatedUnitPrice,
      options: (estimatedUnitPrice != null && estimatedUnitPrice > 0)
          ? [
              ComponentOption(
                type: 'Estimated Price',
                seller: 'Custom Item',
                stock: 1,
                price: estimatedUnitPrice,
                match: '100%',
              ),
            ]
          : const [],
    );
    await updateProject(
      project.copyWith(
        components: normalizeComponents([...project.components, component]),
        auditLog: [
          ...project.auditLog,
          AuditLogEntry(
            action: 'Added custom BOM item: $name ($chosenCategory)',
            timestamp: 'Just now',
          ),
        ],
      ),
    );
  }

  Future<void> updateCustomComponentPrice(
    String projectId,
    int componentIndex,
    double estimatedPrice,
  ) async {
    final project = state.projects.firstWhere((item) => item.id == projectId);
    if (componentIndex < 0 || componentIndex >= project.components.length) {
      return;
    }
    final comp = project.components[componentIndex];
    final updatedComp = comp.copyWith(
      customEstimatedPrice: estimatedPrice,
      options: [
        ComponentOption(
          type: 'Estimated Price',
          seller: 'Custom Item',
          stock: 1,
          price: estimatedPrice,
          match: '100%',
        ),
      ],
      selectedOptionIndex: 0,
    );
    final components = List<BOMComponent>.from(project.components);
    components[componentIndex] = updatedComp;
    await updateProject(
      project.copyWith(
        components: components,
        auditLog: [
          ...project.auditLog,
          AuditLogEntry(
            action:
                'Updated estimated price for ${comp.local} to ₱${estimatedPrice.toStringAsFixed(2)}',
            timestamp: 'Just now',
          ),
        ],
      ),
    );
  }

  Future<void> selectComponentOption(
    String projectId,
    int componentIndex,
    int optionIndex,
  ) async {
    final project = state.projects.firstWhere((item) => item.id == projectId);
    if (componentIndex < 0 || componentIndex >= project.components.length) {
      return;
    }
    final components = List<BOMComponent>.from(project.components);
    components[componentIndex] = components[componentIndex].copyWith(
      selectedOptionIndex: optionIndex,
    );
    await updateProject(project.copyWith(components: components));
  }

  Future<void> updateComponentActualCost(
    String projectId,
    int componentIndex,
    double actualCost,
  ) async {
    final project = state.projects.firstWhere((item) => item.id == projectId);
    if (componentIndex < 0 || componentIndex >= project.components.length) {
      return;
    }
    final components = List<BOMComponent>.from(project.components);
    components[componentIndex] = components[componentIndex].copyWith(
      actualCost: actualCost,
    );
    await updateProject(project.copyWith(components: components));
  }

  Future<void> toggleOptimization(String projectId, bool isOptimized) async {
    final project = state.projects.firstWhere((item) => item.id == projectId);
    await updateProject(project.copyWith(isOptimized: isOptimized));
  }

  Future<void> toggleCompletion(String projectId, bool isCompleted) async {
    final project = state.projects.firstWhere((item) => item.id == projectId);
    await updateProject(
      project.copyWith(
        isCompleted: isCompleted,
        auditLog: [
          ...project.auditLog,
          AuditLogEntry(
            action: 'Marked project as ${isCompleted ? 'Completed' : 'Active'}',
            timestamp: 'Just now',
          ),
        ],
      ),
    );
  }

  void _replaceProject(ProjectModel project) {
    state = state.copyWith(
      projects: state.projects
          .map((current) => current.id == project.id ? project : current)
          .toList(),
      activeProject: state.activeProject?.id == project.id
          ? project
          : state.activeProject,
    );
  }
}

final projectsProvider = StateNotifierProvider<ProjectsNotifier, ProjectsState>(
  (ref) => ProjectsNotifier(),
);

class ProfileState {
  final String displayName;
  final String profileImage;

  ProfileState({this.displayName = 'User', this.profileImage = ''});

  String get avatarInitial {
    final trimmedName = displayName.trim();
    return trimmedName.isEmpty ? 'U' : trimmedName[0].toUpperCase();
  }

  ProfileState copyWith({String? displayName, String? profileImage}) =>
      ProfileState(
        displayName: displayName ?? this.displayName,
        profileImage: profileImage ?? this.profileImage,
      );
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client,
      super(
        ProfileState(
          displayName: _displayNameFor(
            (client ?? Supabase.instance.client).auth.currentUser,
          ),
        ),
      ) {
    if (client == null) {
      _authSubscription = _client.auth.onAuthStateChange.listen((authState) {
        state = state.copyWith(
          displayName: _displayNameFor(authState.session?.user),
        );
      });
    }
  }

  final SupabaseClient _client;
  StreamSubscription<AuthState>? _authSubscription;

  static String _displayNameFor(User? user) {
    final fullName = user?.userMetadata?['full_name']?.toString().trim();
    if (fullName != null && fullName.isNotEmpty) return fullName;

    final email = user?.email?.trim();
    final emailUsername = email?.split('@').first.trim();
    if (emailUsername != null && emailUsername.isNotEmpty) return emailUsername;

    return 'User';
  }

  void setDisplayName(String name) {
    final trimmedName = name.trim();
    state = state.copyWith(
      displayName: trimmedName.isEmpty
          ? _displayNameFor(_client.auth.currentUser)
          : trimmedName,
    );
  }

  Future<void> saveDisplayName(String name) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      state = state.copyWith(displayName: 'User');
      return;
    }

    final updatedUser = await _client.auth.updateUser(
      UserAttributes(data: {'full_name': name.trim()}),
    );
    state = state.copyWith(displayName: _displayNameFor(updatedUser.user));
  }

  void setProfileImage(String image) =>
      state = state.copyWith(profileImage: image);

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) => ProfileNotifier(),
);
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
