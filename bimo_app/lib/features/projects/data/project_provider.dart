import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models.dart';
import '../../../mock/mock_data.dart';
import 'project_api_service.dart';

const int trashRetentionDays = 15;
const Duration trashRetentionDuration = Duration(days: trashRetentionDays);

List<ProjectModel> _removeExpiredTrash(
  List<ProjectModel> projects,
  DateTime now,
) {
  return projects.where((project) {
    final deletedAt = project.deletedAt;
    if (deletedAt == null) return true;

    final expiresAt = deletedAt.add(trashRetentionDuration);
    return now.isBefore(expiresAt);
  }).toList();
}

class ProjectsState {
  final List<ProjectModel> projects;
  final String activeTab; // 'engineering', 'electronics', 'trash'
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
    ProjectModel? activeProject,
    bool? isLoading,
  }) {
    return ProjectsState(
      projects: projects ?? this.projects,
      activeTab: activeTab ?? this.activeTab,
      activeProject: activeProject ?? this.activeProject,
      isLoading: isLoading ?? this.isLoading,
    );
  }

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
  ProjectsNotifier()
    : super(
        ProjectsState(
          projects: _removeExpiredTrash(
            MockData.getInitialProjects(),
            DateTime.now(),
          ),
        ),
      );

  void setActiveTab(String tab) {
    state = state.copyWith(activeTab: tab);
  }

  void setActiveProject(ProjectModel? project) {
    state = state.copyWith(activeProject: project);
  }

  Future<void> addProject(ProjectModel newProject) async {
    state = state.copyWith(projects: [newProject, ...state.projects]);

    try {
      await ProjectApiService.createProject(newProject);
      debugPrint('Project saved to Laravel successfully.');
    } catch (e) {
      debugPrint('Failed to save project to Laravel: $e');
    }
  }

  void cleanupExpiredTrash() {
    final cleanedProjects = _removeExpiredTrash(state.projects, DateTime.now());
    if (cleanedProjects.length == state.projects.length) return;

    state = state.copyWith(projects: cleanedProjects);
  }

  void updateProject(ProjectModel updated) {
    final updatedList = state.projects.map((p) {
      return p.id == updated.id ? updated : p;
    }).toList();
    state = state.copyWith(
      projects: updatedList,
      activeProject: state.activeProject?.id == updated.id
          ? updated
          : state.activeProject,
    );
  }

  void softDeleteProject(String id) {
    final now = DateTime.now();
    final updatedList = state.projects.map((p) {
      if (p.id == id) {
        return p.copyWith(
          deletedAt: now,
          auditLog: [
            ...p.auditLog,
            AuditLogEntry(
              action: 'Moved project to trash archive',
              timestamp: 'Just now',
            ),
          ],
        );
      }
      return p;
    }).toList();
    state = state.copyWith(projects: updatedList);
  }

  void restoreProject(String id) {
    final updatedList = state.projects.map((p) {
      if (p.id == id) {
        final restored = p.copyWith(
          auditLog: [
            ...p.auditLog,
            AuditLogEntry(
              action: 'Restored project from trash archive',
              timestamp: 'Just now',
            ),
          ],
        );
        restored.deletedAt = null;
        return restored;
      }
      return p;
    }).toList();
    state = state.copyWith(projects: updatedList);
  }

  void hardDeleteProject(String id) {
    final updatedList = state.projects.where((p) => p.id != id).toList();
    state = state.copyWith(projects: updatedList);
  }

  void updateComponentQty(String projectId, int componentIndex, int delta) {
    final proj = state.projects.firstWhere((p) => p.id == projectId);
    if (componentIndex < 0 || componentIndex >= proj.components.length) return;

    final comp = proj.components[componentIndex];
    final newQty = comp.qty + delta;
    if (newQty <= 0) return;

    final updatedComp = comp.copyWith(qty: newQty);
    final updatedComps = List<BOMComponent>.from(proj.components);
    updatedComps[componentIndex] = updatedComp;

    final updatedProj = proj.copyWith(
      components: updatedComps,
      auditLog: [
        ...proj.auditLog,
        AuditLogEntry(
          action: 'Updated ${comp.local} quantity to $newQty',
          timestamp: 'Just now',
        ),
      ],
    );
    updateProject(updatedProj);
  }

  void deleteComponent(String projectId, int componentIndex) {
    final proj = state.projects.firstWhere((p) => p.id == projectId);
    if (componentIndex < 0 || componentIndex >= proj.components.length) return;

    final compName = proj.components[componentIndex].local;
    final updatedComps = List<BOMComponent>.from(proj.components)
      ..removeAt(componentIndex);

    final updatedProj = proj.copyWith(
      components: updatedComps,
      auditLog: [
        ...proj.auditLog,
        AuditLogEntry(
          action: 'Removed $compName from BOM list',
          timestamp: 'Just now',
        ),
      ],
    );
    updateProject(updatedProj);
  }

  void toggleBoughtComponent(
    String projectId,
    int componentIndex,
    bool isBought,
  ) {
    final proj = state.projects.firstWhere((p) => p.id == projectId);
    if (componentIndex < 0 || componentIndex >= proj.components.length) return;

    final updatedComp = proj.components[componentIndex].copyWith(
      isBought: isBought,
    );
    final updatedComps = List<BOMComponent>.from(proj.components);
    updatedComps[componentIndex] = updatedComp;

    final updatedProj = proj.copyWith(components: updatedComps);
    updateProject(updatedProj);
  }

  void addCustomComponent(String projectId, String name, String spec) {
    final proj = state.projects.firstWhere((p) => p.id == projectId);
    final newComp = BOMComponent(
      orig: name,
      local: name,
      notes: spec.isNotEmpty ? spec : 'Custom user specification',
      qty: 1,
      selectedOptionIndex: 1,
      isCustom: true,
      options: [
        ComponentOption(
          type: 'Premium Selection',
          seller: 'DigiSupply',
          stock: 50,
          price: 500,
          match: '90%',
        ),
        ComponentOption(
          type: 'Standard Edition',
          seller: 'MakerStore',
          stock: 100,
          price: 300,
          match: '95%',
        ),
        ComponentOption(
          type: 'Direct Factory Outlet',
          seller: 'Direct',
          stock: 10,
          price: 200,
          match: '80%',
        ),
      ],
    );

    final updatedComps = [...proj.components, newComp];
    final updatedProj = proj.copyWith(
      components: updatedComps,
      auditLog: [
        ...proj.auditLog,
        AuditLogEntry(
          action: 'Added custom BOM item: $name',
          timestamp: 'Just now',
        ),
      ],
    );
    updateProject(updatedProj);
  }

  void selectComponentOption(
    String projectId,
    int componentIndex,
    int optionIndex,
  ) {
    final proj = state.projects.firstWhere((p) => p.id == projectId);
    if (componentIndex < 0 || componentIndex >= proj.components.length) return;

    final updatedComp = proj.components[componentIndex].copyWith(
      selectedOptionIndex: optionIndex,
    );
    final updatedComps = List<BOMComponent>.from(proj.components);
    updatedComps[componentIndex] = updatedComp;

    final updatedProj = proj.copyWith(components: updatedComps);
    updateProject(updatedProj);
  }

  void toggleOptimization(String projectId, bool isOptimized) {
    final proj = state.projects.firstWhere((p) => p.id == projectId);
    final updatedProj = proj.copyWith(isOptimized: isOptimized);
    updateProject(updatedProj);
  }

  void toggleCompletion(String projectId, bool isCompleted) {
    final proj = state.projects.firstWhere((p) => p.id == projectId);
    final updatedProj = proj.copyWith(
      isCompleted: isCompleted,
      auditLog: [
        ...proj.auditLog,
        AuditLogEntry(
          action: 'Marked project as ${isCompleted ? 'Completed' : 'Active'}',
          timestamp: 'Just now',
        ),
      ],
    );
    updateProject(updatedProj);
  }
}

final projectsProvider = StateNotifierProvider<ProjectsNotifier, ProjectsState>(
  (ref) {
    return ProjectsNotifier();
  },
);

// Profile & Theme State
class ProfileState {
  final String displayName;
  final String profileImage;

  ProfileState({this.displayName = 'Juan Reyes', this.profileImage = ''});

  ProfileState copyWith({String? displayName, String? profileImage}) {
    return ProfileState(
      displayName: displayName ?? this.displayName,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier() : super(ProfileState());

  void setDisplayName(String name) {
    state = state.copyWith(displayName: name);
  }

  void setProfileImage(String image) {
    state = state.copyWith(profileImage: image);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  return ProfileNotifier();
});

// Theme Mode Provider (Light, Dark, System)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
