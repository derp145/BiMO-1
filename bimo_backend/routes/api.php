<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\ProjectController;
use App\Http\Controllers\Api\AiBomController;

// Health check endpoint
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'app' => 'BiMO Backend API',
        'timestamp' => now()->toIso8601String(),
    ]);
});

// AI BOM Generation Endpoint
Route::post('/ai/generate-bom', [AiBomController::class, 'generateBom']);

// Projects CRUD Endpoints
Route::get('/projects', [ProjectController::class, 'index']);
Route::post('/projects', [ProjectController::class, 'store']);
Route::get('/projects/{id}', [ProjectController::class, 'show']);
Route::put('/projects/{id}', [ProjectController::class, 'update']);
Route::delete('/projects/{id}', [ProjectController::class, 'destroy']);