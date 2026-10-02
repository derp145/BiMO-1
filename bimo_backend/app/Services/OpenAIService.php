<?php

namespace App\Services;

use Exception;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class OpenAIService
{
    /**
     * Generate structured BOM and project specifications using OpenAI Structured Outputs.
     *
     * @param string $input Content or prompt to analyze
     * @param string $inputMode 'text' or 'url'
     * @param array|null $currentProject Existing project data if editing
     * @return array Validated structured BOM data
     * @throws Exception
     */
    public function generateBOM(string $input, string $inputMode = 'text', ?array $currentProject = null): array
    {
        $apiKey = config('services.openai.api_key');
        $model = config('services.openai.model', 'gpt-4.1-mini');

        if (empty($apiKey)) {
            throw new Exception("OpenAI API key is missing or not configured on the server.");
        }

        $systemPrompt = <<<PROMPT
You are BiMO's specialized Bill of Materials (BOM) & Hardware Architecture Generator.
Analyze the project to produce a structured BOM, build instructions, and Philippine store suggestions.

RULES:
1. Extract a clear project title and category ('engineering', 'electronics', or 'hardware').
2. Identify all needed hardware components with practical quantities (min 1), logical categories, and brief technical notes.
3. Provide 3-5 concise, sequential build instructions.
4. Suggest 3-5 real Philippine store chains (e.g., PC Express, Wilcon Depot, CDR King, True Value Hardware, Octagon, Electrotek, Electronics Warehouse) with type ('electronics', 'hardware', or 'specialty') and reason.
5. Set options to [] (no fake prices or sellers), isBought to false, isCustom to false, selectedOptionIndex to 0.
6. If existing project data is provided, refine and update it.
PROMPT;

        $userPrompt = "Input Mode: {$inputMode}\nInput Content:\n{$input}";

        if (!empty($currentProject)) {
            $filteredProject = [
                'title' => $currentProject['title'] ?? '',
                'category' => $currentProject['category'] ?? '',
                'components' => array_map(function ($comp) {
                    return [
                        'name' => $comp['local'] ?? $comp['orig'] ?? '',
                        'qty' => $comp['qty'] ?? 1,
                        'category' => $comp['category'] ?? '',
                        'notes' => $comp['notes'] ?? '',
                    ];
                }, $currentProject['components'] ?? []),
            ];
            $userPrompt .= "\n\nExisting Project:\n" . json_encode($filteredProject);
        }

        $jsonSchema = [
            'name' => 'bom_generation',
            'strict' => true,
            'schema' => [
                'type' => 'object',
                'properties' => [
                    'title' => [
                        'type' => 'string',
                    ],
                    'category' => [
                        'type' => 'string',
                        'enum' => ['engineering', 'electronics', 'hardware'],
                    ],
                    'buildInstructions' => [
                        'type' => 'array',
                        'items' => [
                            'type' => 'string',
                        ],
                    ],
                    'storeSuggestions' => [
                        'type' => 'array',
                        'items' => [
                            'type' => 'object',
                            'properties' => [
                                'name' => [
                                    'type' => 'string',
                                ],
                                'type' => [
                                    'type' => 'string',
                                    'enum' => ['electronics', 'hardware', 'specialty'],
                                ],
                                'reason' => [
                                    'type' => 'string',
                                ],
                            ],
                            'required' => ['name', 'type', 'reason'],
                            'additionalProperties' => false,
                        ],
                    ],
                    'components' => [
                        'type' => 'array',
                        'items' => [
                            'type' => 'object',
                            'properties' => [
                                'orig' => [
                                    'type' => 'string',
                                ],
                                'local' => [
                                    'type' => 'string',
                                ],
                                'notes' => [
                                    'type' => 'string',
                                ],
                                'qty' => [
                                    'type' => 'integer',
                                ],
                                'selectedOptionIndex' => [
                                    'type' => 'integer',
                                ],
                                'isBought' => [
                                    'type' => 'boolean',
                                ],
                                'isCustom' => [
                                    'type' => 'boolean',
                                ],
                                'category' => [
                                    'type' => 'string',
                                ],
                                'options' => [
                                    'type' => 'array',
                                    'items' => [
                                        'type' => 'object',
                                        'properties' => [
                                            'type' => ['type' => 'string'],
                                            'seller' => ['type' => 'string'],
                                            'stock' => ['type' => 'integer'],
                                            'price' => ['type' => 'number'],
                                            'match' => ['type' => 'string'],
                                        ],
                                        'required' => ['type', 'seller', 'stock', 'price', 'match'],
                                        'additionalProperties' => false,
                                    ],
                                ],
                            ],
                            'required' => [
                                'orig',
                                'local',
                                'notes',
                                'qty',
                                'selectedOptionIndex',
                                'isBought',
                                'isCustom',
                                'category',
                                'options',
                            ],
                            'additionalProperties' => false,
                        ],
                    ],
                ],
                'required' => ['title', 'category', 'buildInstructions', 'storeSuggestions', 'components'],
                'additionalProperties' => false,
            ],
        ];

        $baseUrl = config('services.openai.base_url') ?: 'https://api.openai.com/v1';
        $endpoint = rtrim($baseUrl, '/') . '/chat/completions';

        try {
            $response = Http::timeout(45)
                ->withHeaders([
                    'Authorization' => "Bearer {$apiKey}",
                    'Content-Type' => 'application/json',
                ])
                ->post($endpoint, [
                    'model' => $model,
                    'messages' => [
                        ['role' => 'system', 'content' => $systemPrompt],
                        ['role' => 'user', 'content' => $userPrompt],
                    ],
                    'response_format' => [
                        'type' => 'json_schema',
                        'json_schema' => $jsonSchema,
                    ],
                    'max_completion_tokens' => 2000,
                ]);

            if (!$response->successful()) {
                $errorJson = $response->json();
                $errorMessage = $errorJson['error']['message'] ?? "OpenAI API returned status {$response->status()}";
                Log::error("OpenAI API Error: " . json_encode($errorJson));
                throw new Exception("OpenAI Error: {$errorMessage}");
            }

            $responseData = $response->json();
            $content = $responseData['choices'][0]['message']['content'] ?? null;

            if (empty($content)) {
                throw new Exception("Empty response from OpenAI API.");
            }

            $parsed = json_decode($content, true);
            if (!is_array($parsed)) {
                throw new Exception("Failed to decode OpenAI JSON output.");
            }

            return $this->validateAndSanitizeOutput($parsed);
        } catch (Exception $e) {
            Log::error("OpenAI Service Exception: " . $e->getMessage());
            throw $e;
        }
    }

    /**
     * Strictly validate and sanitize the AI response before sending to Flutter.
     *
     * @param array $data
     * @return array
     * @throws Exception
     */
    public function validateAndSanitizeOutput(array $data): array
    {
        if (empty($data['title']) || !is_string($data['title'])) {
            throw new Exception("Invalid or missing 'title' in AI response.");
        }

        $category = $data['category'] ?? 'engineering';
        if (!in_array($category, ['engineering', 'electronics', 'hardware'], true)) {
            $category = 'engineering';
        }

        $buildInstructions = [];
        if (!empty($data['buildInstructions']) && is_array($data['buildInstructions'])) {
            foreach ($data['buildInstructions'] as $step) {
                if (is_string($step) && trim($step) !== '') {
                    $buildInstructions[] = trim($step);
                }
            }
        }

        if (empty($buildInstructions)) {
            $buildInstructions = [
                'Step 1: Check components and ensure correct voltage compatibility before connecting power.',
                'Step 2: Assemble hardware modules on a breadboard or PCB according to wiring schematics.',
                'Step 3: Program the controller firmware and test individual sensor/actuator operations.',
            ];
        }

        $components = [];
        if (!empty($data['components']) && is_array($data['components'])) {
            foreach ($data['components'] as $comp) {
                if (!is_array($comp)) continue;

                $orig = trim((string)($comp['orig'] ?? ''));
                $local = trim((string)($comp['local'] ?? ''));

                if (empty($orig) && empty($local)) {
                    continue;
                }

                $qty = max(1, (int)($comp['qty'] ?? 1));
                $notes = trim((string)($comp['notes'] ?? ''));
                $compCategory = trim((string)($comp['category'] ?? 'Hardware'));
                if (empty($compCategory)) {
                    $compCategory = 'Hardware';
                }

                $options = [];
                if (!empty($comp['options']) && is_array($comp['options'])) {
                    foreach ($comp['options'] as $opt) {
                        if (!is_array($opt)) continue;
                        $options[] = [
                            'type' => (string)($opt['type'] ?? 'Standard'),
                            'seller' => (string)($opt['seller'] ?? ''),
                            'stock' => max(0, (int)($opt['stock'] ?? 0)),
                            'price' => max(0.0, (float)($opt['price'] ?? 0.0)),
                            'match' => (string)($opt['match'] ?? '90%'),
                        ];
                    }
                }

                $components[] = [
                    'orig' => $orig ?: $local,
                    'local' => $local ?: $orig,
                    'notes' => $notes ?: 'Specification standard',
                    'qty' => $qty,
                    'selectedOptionIndex' => 0,
                    'options' => $options,
                    'isBought' => false,
                    'isCustom' => false,
                    'category' => $compCategory,
                    'actualCost' => null,
                ];
            }
        }

        if (empty($components)) {
            throw new Exception("AI did not extract any valid components for this project.");
        }

        // Sanitize store suggestions — keep only real entries with a name
        $storeSuggestions = [];
        if (!empty($data['storeSuggestions']) && is_array($data['storeSuggestions'])) {
            foreach ($data['storeSuggestions'] as $store) {
                $name = trim((string)($store['name'] ?? ''));
                if (empty($name)) continue;
                $storeType = $store['type'] ?? 'hardware';
                if (!in_array($storeType, ['electronics', 'hardware', 'specialty'], true)) {
                    $storeType = 'hardware';
                }
                $storeSuggestions[] = [
                    'name'   => $name,
                    'type'   => $storeType,
                    'reason' => trim((string)($store['reason'] ?? '')),
                ];
            }
        }

        return [
            'title'            => trim($data['title']),
            'category'         => $category,
            'buildInstructions' => $buildInstructions,
            'components'       => $components,
            'storeSuggestions' => $storeSuggestions,
        ];
    }
}
