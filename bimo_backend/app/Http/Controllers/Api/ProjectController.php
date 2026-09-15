<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Project;
use Illuminate\Http\Request;

class ProjectController extends Controller
{
    // Get all projects
    public function index()
    {
        $projects = Project::orderBy('created_at', 'desc')->get();

        return response()->json($projects);
    }

    // Save a new project
    public function store(Request $request)
    {
        $validated = $request->validate([
            'id' => 'required|string',
            'title' => 'required|string|max:255',
            'category' => 'nullable|string|max:100',
            'created_at' => 'nullable|date',
            'is_optimized' => 'nullable|boolean',
            'is_completed' => 'nullable|boolean',
            'region' => 'nullable|string',
            'city' => 'nullable|string',
            'barangay' => 'nullable|string',
            'prompt_or_url' => 'nullable|string',
            'author_name' => 'nullable|string',
            'thumbnail_url' => 'nullable|string',
            'build_instructions' => 'nullable|array',
        ]);

        $project = Project::create($validated);

        return response()->json([
            'message' => 'Project saved successfully.',
            'project' => $project,
        ], 201);
    }

    // Get one project
    public function show(string $id)
    {
        $project = Project::findOrFail($id);

        return response()->json($project);
    }

    // Update a project
    public function update(Request $request, string $id)
    {
        $project = Project::findOrFail($id);

        $validated = $request->validate([
            'title' => 'sometimes|required|string|max:255',
            'category' => 'nullable|string|max:100',
            'deleted_at' => 'nullable|date',
            'is_optimized' => 'nullable|boolean',
            'is_completed' => 'nullable|boolean',
            'region' => 'nullable|string',
            'city' => 'nullable|string',
            'barangay' => 'nullable|string',
            'prompt_or_url' => 'nullable|string',
            'author_name' => 'nullable|string',
            'thumbnail_url' => 'nullable|string',
            'build_instructions' => 'nullable|array',
        ]);

        $project->update($validated);

        return response()->json([
            'message' => 'Project updated successfully.',
            'project' => $project,
        ]);
    }

    // Delete a project
    public function destroy(string $id)
    {
        $project = Project::findOrFail($id);
        $project->delete();

        return response()->json([
            'message' => 'Project deleted successfully.',
        ]);
    }
}