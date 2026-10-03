import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/models.dart';

abstract class ProjectRepository {
  Future<ProjectModel> createProject(ProjectModel project);
  Future<List<ProjectModel>> fetchProjects();
  Future<ProjectModel> updateProject(
    ProjectModel project, {
    List<AuditLogEntry> activityLogs = const [],
  });
  Future<void> moveToTrash(String projectId, AuditLogEntry activityLog);
  Future<void> restoreProject(String projectId, AuditLogEntry activityLog);
  Future<void> deleteProject(String projectId);
}

class SupabaseProjectRepository implements ProjectRepository {
  SupabaseProjectRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User get _currentUser {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('You must log in before managing saved projects.');
    }
    return user;
  }

  @override
  Future<ProjectModel> createProject(ProjectModel project) async {
    final user = _currentUser;
    final normalizedComponents = normalizeComponents(project.components);
    final inserted = await _client
        .from('projects')
        .insert(
          _projectValues(project, userId: user.id, includeCreatedAt: true),
        )
        .select()
        .single();

    final savedProject = ProjectModel.fromJson(
      Map<String, dynamic>.from(inserted),
    ).copyWith(components: normalizedComponents, auditLog: project.auditLog);

    try {
      await _replaceComponents(savedProject.id, normalizedComponents);
      await _insertActivityLogs(savedProject.id, project.auditLog);
      return savedProject;
    } catch (_) {
      // Avoid retaining a half-created project when its dependent rows fail.
      await _client
          .from('projects')
          .delete()
          .eq('id', savedProject.id)
          .eq('user_id', user.id);
      rethrow;
    }
  }

  @override
  Future<List<ProjectModel>> fetchProjects() async {
    final user = _currentUser;
    final projectRows = await _client
        .from('projects')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return Future.wait(
      (projectRows as List<dynamic>).map((row) async {
        final projectRow = Map<String, dynamic>.from(row as Map);
        final projectId = projectRow['id'].toString();
        final componentRows = await _client
            .from('project_components')
            .select()
            .eq('project_id', projectId)
            .order('id');
        final logRows = await _client
            .from('activity_logs')
            .select()
            .eq('project_id', projectId)
            .order('created_at');

        return ProjectModel.fromJson({
          ...projectRow,
          'components': (componentRows as List<dynamic>)
              .map((component) => _componentFromRow(component as Map))
              .toList(),
          'audit_log': (logRows as List<dynamic>)
              .map((log) => _auditLogFromRow(log as Map))
              .toList(),
        });
      }),
    );
  }

  @override
  Future<ProjectModel> updateProject(
    ProjectModel project, {
    List<AuditLogEntry> activityLogs = const [],
  }) async {
    final user = _currentUser;
    final normalizedComponents = normalizeComponents(project.components);
    final updated = await _client
        .from('projects')
        .update(_projectValues(project, includeCreatedAt: false))
        .eq('id', project.id)
        .eq('user_id', user.id)
        .select()
        .maybeSingle();

    if (updated == null) {
      throw StateError('Project not found or you no longer have access to it.');
    }

    await _replaceComponents(project.id, normalizedComponents);
    await _insertActivityLogs(project.id, activityLogs);

    return ProjectModel.fromJson(
      Map<String, dynamic>.from(updated),
    ).copyWith(components: normalizedComponents, auditLog: project.auditLog);
  }

  @override
  Future<void> moveToTrash(String projectId, AuditLogEntry activityLog) async {
    await _setDeletedAt(projectId, DateTime.now().toUtc());
    await _insertActivityLogs(projectId, [activityLog]);
  }

  @override
  Future<void> restoreProject(
    String projectId,
    AuditLogEntry activityLog,
  ) async {
    final user = _currentUser;
    final updated = await _client
        .from('projects')
        .update({
          'deleted_at': null,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', projectId)
        .eq('user_id', user.id)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw StateError('Project not found or you no longer have access to it.');
    }
    await _insertActivityLogs(projectId, [activityLog]);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    final user = _currentUser;
    await _client.from('activity_logs').delete().eq('project_id', projectId);
    await _client
        .from('project_components')
        .delete()
        .eq('project_id', projectId);
    final deleted = await _client
        .from('projects')
        .delete()
        .eq('id', projectId)
        .eq('user_id', user.id)
        .select('id')
        .maybeSingle();
    if (deleted == null) {
      throw StateError('Project not found or you no longer have access to it.');
    }
  }

  Map<String, dynamic> _projectValues(
    ProjectModel project, {
    String? userId,
    required bool includeCreatedAt,
  }) {
    return {
      'id': project.id,
      'user_id': ?userId,
      'title': project.title,
      'category': project.category,
      if (includeCreatedAt)
        'created_at': project.createdAt.toUtc().toIso8601String(),
      'deleted_at': project.deletedAt?.toUtc().toIso8601String(),
      'is_optimized': project.isOptimized,
      'is_completed': project.isCompleted,
      'region': project.region,
      'city': project.city,
      'barangay': project.barangay,
      'prompt_or_url': project.promptOrUrl,
      'author_name': project.authorName,
      'thumbnail_url': project.thumbnailUrl,
      'build_instructions': project.buildInstructions,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<void> _setDeletedAt(String projectId, DateTime deletedAt) async {
    final user = _currentUser;
    final updated = await _client
        .from('projects')
        .update({
          'deleted_at': deletedAt.toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', projectId)
        .eq('user_id', user.id)
        .select('id')
        .maybeSingle();
    if (updated == null) {
      throw StateError('Project not found or you no longer have access to it.');
    }
  }

  Future<void> _replaceComponents(
    String projectId,
    List<BOMComponent> components,
  ) async {
    await _client
        .from('project_components')
        .delete()
        .eq('project_id', projectId);
    final normalizedComponents = normalizeComponents(components);
    if (normalizedComponents.isEmpty) return;

    await _client
        .from('project_components')
        .insert(
          normalizedComponents
              .map((component) => _componentValues(projectId, component))
              .toList(),
        );
  }

  Future<void> _insertActivityLogs(
    String projectId,
    List<AuditLogEntry> logs,
  ) async {
    if (logs.isEmpty) return;
    await _client
        .from('activity_logs')
        .insert(
          logs
              .map(
                (log) => {
                  'project_id': projectId,
                  'action': log.action,
                  'created_at': _logTimestamp(log.timestamp).toIso8601String(),
                },
              )
              .toList(),
        );
  }

  Map<String, dynamic> _componentValues(
    String projectId,
    BOMComponent component,
  ) {
    return {
      'project_id': projectId,
      'orig': component.orig,
      'local': component.local,
      'notes': component.notes,
      'quantity': component.qty,
      'selected_option_index': component.selectedOptionIndex,
      'options': component.options.map((option) => option.toJson()).toList(),
      'is_bought': component.isBought,
      'is_custom': component.isCustom,
      'category': component.category,
      'actual_cost': component.actualCost,
    };
  }

  Map<String, dynamic> _componentFromRow(Map row) {
    return {
      'orig': row['orig'],
      'local': row['local'],
      'notes': row['notes'],
      'qty': row['quantity'],
      'selected_option_index': row['selected_option_index'],
      'options': row['options'],
      'is_bought': row['is_bought'],
      'is_custom': row['is_custom'],
      'category': row['category'],
      'actual_cost': row['actual_cost'],
    };
  }

  Map<String, dynamic> _auditLogFromRow(Map row) {
    return {
      'action': row['action'],
      'timestamp': row['created_at']?.toString() ?? '',
    };
  }

  DateTime _logTimestamp(String timestamp) {
    return DateTime.tryParse(timestamp)?.toUtc() ?? DateTime.now().toUtc();
  }
}
