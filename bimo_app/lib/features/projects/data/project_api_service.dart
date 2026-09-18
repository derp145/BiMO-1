import 'dart:convert';
import 'package:http/http.dart' as http;

import '../domain/models.dart';

class ProjectApiService {
  static const String baseUrl = String.fromEnvironment(
    'BIMO_API_URL',
    defaultValue: 'https://bimo-backend-uxh5.onrender.com/api',
  );

  static Future<ProjectModel> generateBOM({
    String? projectId,
    required String inputMode,
    required String input,
    ProjectModel? currentProject,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/generate-bom'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        if (projectId != null && projectId.isNotEmpty) 'project_id': projectId,
        'input_mode': inputMode,
        'input': input,
        if (currentProject != null) 'current_project': currentProject.toJson(),
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['project'] != null) {
        final projData = data['project'];
        if (projData is Map<String, dynamic>) {
          return ProjectModel.fromJson(projData);
        } else if (projData is Map) {
          return ProjectModel.fromJson(Map<String, dynamic>.from(projData));
        }
      }
      throw Exception(data['message'] ?? 'Failed to parse generated BOM response.');
    } else {
      String errorMessage = 'Failed to generate BOM (HTTP ${response.statusCode})';
      try {
        final errData = jsonDecode(response.body);
        if (errData['message'] != null) {
          errorMessage = errData['message'].toString();
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  static Future<void> createProject(ProjectModel project) async {
    final response = await http.post(
      Uri.parse('$baseUrl/projects'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(project.toJson()),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(
        'Failed to save project: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<void> updateProject(ProjectModel project) async {
    final response = await http.put(
      Uri.parse('$baseUrl/projects/${project.id}'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(project.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update project: ${response.statusCode} ${response.body}',
      );
    }
  }

  static Future<List<ProjectModel>> fetchProjects() async {
    final response = await http.get(
      Uri.parse('$baseUrl/projects'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        return data
            .map((item) => ProjectModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } else {
      throw Exception('Failed to fetch projects: ${response.statusCode}');
    }
  }
}