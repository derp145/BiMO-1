<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Services\OpenAIService;
use App\Services\UrlExtractorService;
use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class AiBomController extends Controller
{
    public function __construct(
        protected OpenAIService $openAIService,
        protected UrlExtractorService $urlExtractorService,
    ) {}

    /**
     * Generate structured BOM and project specifications from prompt or reference URL.
     * Also geocodes AI-suggested stores via Nominatim for real map markers.
     */
    public function generateBom(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'project_id'      => 'nullable|string',
            'input_mode'      => 'required|string|in:text,url',
            'input'           => 'required|string|min:3',
            'current_project' => 'nullable|array',
        ]);

        $inputMode      = $validated['input_mode'];
        $rawInput       = trim($validated['input']);
        $projectId      = $validated['project_id'] ?? null;
        $currentProject = $validated['current_project'] ?? null;

        try {
            $extractedText = $rawInput;
            if ($inputMode === 'url') {
                $extractedText = $this->urlExtractorService->extractContent($rawInput);
            }

            $aiResult = $this->openAIService->generateBOM(
                input: $extractedText,
                inputMode: $inputMode,
                currentProject: $currentProject
            );

            // Determine final project ID
            $finalId = $projectId;
            if (empty($finalId) && !empty($currentProject['id'])) {
                $finalId = $currentProject['id'];
            }
            if (empty($finalId)) {
                $finalId = 'proj-' . (int)(microtime(true) * 1000);
            }

            // Build audit log entry
            $existingLogs      = $currentProject['auditLog'] ?? $currentProject['audit_log'] ?? [];
            $actionDescription = $inputMode === 'url'
                ? "Generated BOM from URL: {$rawInput}"
                : 'Generated BOM from project prompt';

            $finalAuditLog = is_array($existingLogs)
                ? array_merge($existingLogs, [['action' => $actionDescription, 'timestamp' => 'Just now']])
                : [['action' => $actionDescription, 'timestamp' => 'Just now']];

            // Geocode AI-suggested stores via Nominatim (free, no key required)
            $city   = $currentProject['city']   ?? null;
            $region = $currentProject['region'] ?? null;
            $geocodedStores = $this->geocodeStoreSuggestions(
                $aiResult['storeSuggestions'] ?? [],
                $city,
                $region
            );

            $projectPayload = [
                'id'                => $finalId,
                'title'             => $aiResult['title'],
                'category'          => $aiResult['category'],
                'createdAt'         => $currentProject['createdAt']   ?? $currentProject['created_at']   ?? now()->toIso8601String(),
                'deletedAt'         => $currentProject['deletedAt']   ?? $currentProject['deleted_at']   ?? null,
                'isOptimized'       => $currentProject['isOptimized'] ?? $currentProject['is_optimized'] ?? true,
                'isCompleted'       => $currentProject['isCompleted'] ?? $currentProject['is_completed'] ?? false,
                'components'        => $aiResult['components'],
                'auditLog'          => $finalAuditLog,
                'region'            => $currentProject['region']      ?? null,
                'city'              => $currentProject['city']        ?? null,
                'barangay'          => $currentProject['barangay']    ?? null,
                'promptOrUrl'       => $rawInput,
                'authorName'        => $currentProject['authorName']  ?? $currentProject['author_name']  ?? null,
                'thumbnailUrl'      => $currentProject['thumbnailUrl'] ?? $currentProject['thumbnail_url'] ?? null,
                'buildInstructions' => $aiResult['buildInstructions'],
                'suggestedStores'   => $geocodedStores,
            ];

            return response()->json([
                'success' => true,
                'message' => 'Bill of Materials generated successfully.',
                'project' => $projectPayload,
            ]);
        } catch (Exception $e) {
            return response()->json([
                'success' => false,
                'message' => $e->getMessage(),
            ], 422);
        }
    }

    /**
     * Geocode each AI-suggested store name using Nominatim (OpenStreetMap).
     * Returns stores with lat/lng for map markers. Stores not found in OSM are still
     * returned (lat/lng = null) so the UI can show their name without a pin.
     *
     * @param array       $suggestions  Raw AI store list [{name, type, reason}, ...]
     * @param string|null $city         Project city (e.g. "Manila")
     * @param string|null $region       Project region (e.g. "NCR")
     * @return array Geocoded store list
     */
    private function geocodeStoreSuggestions(array $suggestions, ?string $city, ?string $region): array
    {
        if (empty($suggestions)) {
            return [];
        }

        // Build a location context string for Nominatim queries
        $locationParts = array_filter([$city, $region, 'Philippines']);
        $locationCtx   = implode(', ', $locationParts);

        $geocoded = [];

        foreach ($suggestions as $store) {
            $name = $store['name'] ?? '';
            if (empty($name)) {
                continue;
            }

            $query = "{$name}, {$locationCtx}";

            try {
                $response = Http::timeout(6)
                    ->withHeaders([
                        // Nominatim requires a descriptive User-Agent
                        'User-Agent' => 'BiMO-App/1.0 (contact@bimo.example.com)',
                    ])
                    ->get('https://nominatim.openstreetmap.org/search', [
                        'q'              => $query,
                        'format'         => 'json',
                        'limit'          => 1,
                        'addressdetails' => 0,
                    ]);

                $results = $response->json();

                if (!empty($results[0]['lat']) && !empty($results[0]['lon'])) {
                    $geocoded[] = [
                        'name'        => $name,
                        'type'        => $store['type']   ?? 'hardware',
                        'reason'      => $store['reason'] ?? '',
                        'lat'         => (float) $results[0]['lat'],
                        'lng'         => (float) $results[0]['lon'],
                        'displayName' => $results[0]['display_name'] ?? $name,
                    ];
                } else {
                    // Not found in OSM — include without coords
                    $geocoded[] = [
                        'name'        => $name,
                        'type'        => $store['type']   ?? 'hardware',
                        'reason'      => $store['reason'] ?? '',
                        'lat'         => null,
                        'lng'         => null,
                        'displayName' => $name,
                    ];
                }
            } catch (Exception $e) {
                Log::warning("Nominatim geocoding failed for '{$name}': " . $e->getMessage());
                $geocoded[] = [
                    'name'        => $name,
                    'type'        => $store['type']   ?? 'hardware',
                    'reason'      => $store['reason'] ?? '',
                    'lat'         => null,
                    'lng'         => null,
                    'displayName' => $name,
                ];
            }

            // Nominatim usage policy: max 1 request/second
            usleep(1_100_000);
        }

        return $geocoded;
    }
}
