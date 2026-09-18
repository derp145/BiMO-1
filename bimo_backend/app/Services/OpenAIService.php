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
Your task is to analyze the user's project description or tutorial content and generate a structured Bill of Materials (BOM) and step-by-step build instructions.

RULES:
1. Extract or determine an accurate, concise project title.
2. Categorize the project into one of: 'engineering', 'electronics', 'hardware'.
3. Identify all necessary hardware components, microcontrollers, sensors, actuators, power supplies, and accessories.
4. Set realistic, practical quantities for each component (minimum 1).
5. Categorize each component logically (e.g., 'Microcontrollers', 'Sensors', 'Actuators', 'Power', 'Passive Components', 'Hardware', 'Modules', 'Connectivity').
6. Provide clear, concise technical notes for each component explaining its specific role, operating voltage, or pin interface.
7. Generate 3 to 6 practical, actionable build instructions in chronological order.
8. CRITICAL: For each component, set 'options' to an empty array [] unless real supplier data was explicitly provided in the input. NEVER invent fake supplier names, fake store stock, fake prices, or fake match percentages.
9. Always set 'isBought' to false, 'isCustom' to false, 'actualCost' to null, and 'selectedOptionIndex' to 0.
10. If existing project data is provided, update and refine the components and instructions rather than needlessly replacing everything.
11. STORES: Suggest 4 to 6 real Philippine store chains or shops where the project components can be sourced. Use ONLY real, well-known store names that actually exist in the Philippines (e.g., 'PC Express', 'CDR King', 'Wilcon Depot', 'All Home', 'True Value Hardware', 'Automatic Centre', 'Octagon Computer Superstore', 'DataBlitz', 'Electrotek', 'Electronics Warehouse'). Choose stores relevant to the component types needed. Include the store type (e.g., 'electronics', 'hardware', 'specialty').
PROMPT;

        $userPrompt = "Input Mode: {$inputMode}\nInput Content:\n{$input}";

        if (!empty($currentProject)) {
            $userPrompt .= "\n\nCurrent Existing Project JSON:\n" . json_encode($currentProject);
        }

        $jsonSchema = [
            'name' => 'bom_generation',
            'strict' => true,
            'schema' => [
                'type' => 'object',
                'properties' => [
                    'title' => [
                        'type' => 'string',
                        'description' => 'A clear, concise title for the project.',
                    ],
                    'category' => [
                        'type' => 'string',
                        'enum' => ['engineering', 'electronics', 'hardware'],
                        'description' => 'Project category.',
                    ],
                    'buildInstructions' => [
                        'type' => 'array',
                        'description' => 'Step-by-step instructions to assemble and build the project.',
                        'items' => [
                            'type' => 'string',
                        ],
                    ],
                    'storeSuggestions' => [
                        'type' => 'array',
                        'description' => 'Real Philippine store chains recommended for sourcing components for this project.',
                        'items' => [
                            'type' => 'object',
                            'properties' => [
                                'name' => [
                                    'type' => 'string',
                                    'description' => 'Exact real store chain name (e.g. PC Express, Wilcon Depot, CDR King).',
                                ],
                                'type' => [
                                    'type' => 'string',
                                    'enum' => ['electronics', 'hardware', 'specialty'],
                                    'description' => 'Store category.',
                                ],
                                'reason' => [
                                    'type' => 'string',
                                    'description' => 'One sentence explaining why this store is recommended for this project.',
                                ],
                            ],
                            'required' => ['name', 'type', 'reason'],
                            'additionalProperties' => false,
                        ],
                    ],
                    'components' => [
                        'type' => 'array',
                        'description' => 'List of hardware components required for the Bill of Materials.',
                        'items' => [
                            'type' => 'object',
                            'properties' => [
                                'orig' => [
                                    'type' => 'string',
                                    'description' => 'Original component name or generic specification.',
                                ],
                                'local' => [
                                    'type' => 'string',
                                    'description' => 'Localized or standard descriptive component name.',
                                ],
                                'notes' => [
                                    'type' => 'string',
                                    'description' => 'Technical notes, voltage specifications, or wiring tips.',
                                ],
                                'qty' => [
                                    'type' => 'integer',
                                    'description' => 'Quantity needed (minimum 1).',
                                ],
                                'selectedOptionIndex' => [
                                    'type' => 'integer',
                                    'description' => 'Default selected option index (0).',
                                ],
                                'isBought' => [
                                    'type' => 'boolean',
                                    'description' => 'Whether the item has already been purchased (false).',
                                ],
                                'isCustom' => [
                                    'type' => 'boolean',
                                    'description' => 'Whether this is a user-added custom item (false).',
                                ],
                                'category' => [
                                    'type' => 'string',
                                    'description' => 'Component category (e.g. Microcontrollers, Sensors, Power, etc.).',
                                ],
                                'options' => [
                                    'type' => 'array',
                                    'description' => 'Supplier options. Must be empty array [] if no real supplier data exists.',
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
