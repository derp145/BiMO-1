import 'dart:convert';
import 'package:http/http.dart' as http;

import '../domain/models.dart';

class ProjectApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<void> createProject(ProjectModel project) async {
    final response = await http.post(
      Uri.parse('$baseUrl/projects'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'id': project.id,
        'title': project.title,
        'category': project.category,
        'created_at': project.createdAt.toIso8601String(),
        'is_optimized': project.isOptimized,
        'is_completed': project.isCompleted,
        'region': project.region,
        'city': project.city,
        'barangay': project.barangay,
        'prompt_or_url': project.promptOrUrl,
        'author_name': project.authorName,
        'thumbnail_url': project.thumbnailUrl,
        'build_instructions': project.buildInstructions,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception(
        'Failed to save project: ${response.statusCode} ${response.body}',
      );
    }
  }
}