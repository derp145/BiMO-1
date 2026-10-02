<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AiBomGenerationTest extends TestCase
{
    use RefreshDatabase;

    public function test_health_check_endpoint(): void
    {
        $response = $this->getJson('/api/health');
        $response->assertStatus(200)
            ->assertJson([
                'status' => 'ok',
                'app' => 'BiMO Backend API',
            ]);
    }

    public function test_missing_openai_key_returns_clear_error(): void
    {
        Config::set('services.openai.api_key', '');

        $response = $this->postJson('/api/ai/generate-bom', [
            'input_mode' => 'text',
            'input' => 'Build an automated plant watering device with ESP32 and soil sensor',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);

        $this->assertStringContainsString('OpenAI API key is missing', $response->json('message'));
    }

    public function test_text_prompt_generates_structured_bom_successfully(): void
    {
        Config::set('services.openai.api_key', 'test-openai-key');
        Config::set('services.openai.model', 'gpt-4.1-mini');

        $mockOpenAiResponse = [
            'title' => 'Automated Smart Plant Waterer',
            'category' => 'engineering',
            'buildInstructions' => [
                'Step 1: Wire the soil moisture sensor to GPIO 34.',
                'Step 2: Connect the relay switch to 5V power and GPIO 25.',
                'Step 3: Upload firmware and calibrate sensor thresholds.',
            ],
            'components' => [
                [
                    'orig' => 'ESP32 NodeMCU Board',
                    'local' => 'ESP32 Development Board',
                    'notes' => '3.3V logic level with Wi-Fi and Bluetooth',
                    'qty' => 1,
                    'selectedOptionIndex' => 0,
                    'isBought' => false,
                    'isCustom' => false,
                    'category' => 'Microcontrollers',
                    'options' => [],
                ],
                [
                    'orig' => 'Capacitive Soil Moisture Sensor v1.2',
                    'local' => 'Soil Moisture Sensor Module',
                    'notes' => 'Corrosion resistant analog reading module',
                    'qty' => 2,
                    'selectedOptionIndex' => 0,
                    'isBought' => false,
                    'isCustom' => false,
                    'category' => 'Sensors',
                    'options' => [],
                ],
            ],
        ];

        Http::fake([
            'https://api.openai.com/v1/chat/completions' => Http::response([
                'choices' => [
                    [
                        'message' => [
                            'content' => json_encode($mockOpenAiResponse),
                        ],
                    ],
                ],
            ], 200),
        ]);

        $response = $this->postJson('/api/ai/generate-bom', [
            'input_mode' => 'text',
            'input' => 'Automated smart plant waterer with ESP32',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'project' => [
                    'title' => 'Automated Smart Plant Waterer',
                    'category' => 'engineering',
                ],
            ]);

        $project = $response->json('project');
        $this->assertNotEmpty($project['id']);
        $this->assertCount(2, $project['components']);
        $this->assertEquals('ESP32 Development Board', $project['components'][0]['local']);
        $this->assertEmpty($project['components'][0]['options']);
        $this->assertEquals(0, $project['components'][0]['selectedOptionIndex']);
        $this->assertFalse($project['components'][0]['isBought']);
        $this->assertFalse($project['components'][0]['isCustom']);
        $this->assertCount(3, $project['buildInstructions']);
    }

    public function test_existing_project_updates_without_changing_id(): void
    {
        Config::set('services.openai.api_key', 'test-openai-key');

        $mockOpenAiResponse = [
            'title' => 'Smart Solar Power Station v2',
            'category' => 'electronics',
            'buildInstructions' => [
                'Step 1: Check solar charge controller specs.',
                'Step 2: Connect LiFePO4 battery pack.',
            ],
            'components' => [
                [
                    'orig' => 'MPPT Charge Controller 20A',
                    'local' => '20A MPPT Solar Controller',
                    'notes' => '12V/24V auto detection',
                    'qty' => 1,
                    'selectedOptionIndex' => 0,
                    'isBought' => false,
                    'isCustom' => false,
                    'category' => 'Power',
                    'options' => [],
                ],
            ],
        ];

        Http::fake([
            'https://api.openai.com/v1/chat/completions' => Http::response([
                'choices' => [
                    [
                        'message' => [
                            'content' => json_encode($mockOpenAiResponse),
                        ],
                    ],
                ],
            ], 200),
        ]);

        $existingProjectId = 'proj-custom-existing-12345';

        $response = $this->postJson('/api/ai/generate-bom', [
            'project_id' => $existingProjectId,
            'input_mode' => 'text',
            'input' => 'Add MPPT charge controller to existing solar build',
            'current_project' => [
                'id' => $existingProjectId,
                'title' => 'Old Solar Title',
                'createdAt' => '2026-09-01T10:00:00Z',
                'isOptimized' => true,
                'isCompleted' => false,
            ],
        ]);

        $response->assertStatus(200);
        $project = $response->json('project');
        $this->assertEquals($existingProjectId, $project['id']);
        $this->assertEquals('Smart Solar Power Station v2', $project['title']);
        $this->assertEquals('2026-09-01T10:00:00Z', $project['createdAt']);
    }

    public function test_url_input_fetches_and_generates_bom(): void
    {
        Config::set('services.openai.api_key', 'test-openai-key');

        $targetUrl = 'https://example.com/project-tutorial';

        $mockOpenAiResponse = [
            'title' => 'Tutorial Robot Arm 4-DOF',
            'category' => 'hardware',
            'buildInstructions' => [
                'Step 1: Assemble acrylic arm chassis.',
                'Step 2: Calibrate MG996R servo motors.',
            ],
            'components' => [
                [
                    'orig' => 'MG996R High Torque Servo',
                    'local' => 'MG996R Metal Gear Servo',
                    'notes' => 'High torque servo motor for joints',
                    'qty' => 4,
                    'selectedOptionIndex' => 0,
                    'isBought' => false,
                    'isCustom' => false,
                    'category' => 'Actuators',
                    'options' => [],
                ],
            ],
        ];

        Http::fake([
            $targetUrl => Http::response('<html><body><h1>4-DOF Robotic Arm Tutorial</h1><p>Learn to assemble servo motors with Arduino controller.</p></body></html>', 200),
            'https://api.openai.com/v1/chat/completions' => Http::response([
                'choices' => [
                    [
                        'message' => [
                            'content' => json_encode($mockOpenAiResponse),
                        ],
                    ],
                ],
            ], 200),
        ]);

        $response = $this->postJson('/api/ai/generate-bom', [
            'input_mode' => 'url',
            'input' => $targetUrl,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'project' => [
                    'title' => 'Tutorial Robot Arm 4-DOF',
                ],
            ]);
    }

    public function test_unsafe_url_is_rejected(): void
    {
        $response = $this->postJson('/api/ai/generate-bom', [
            'input_mode' => 'url',
            'input' => 'http://localhost:8080/secret-admin',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_invalid_ai_response_is_rejected(): void
    {
        Config::set('services.openai.api_key', 'test-openai-key');

        Http::fake([
            'https://api.openai.com/v1/chat/completions' => Http::response([
                'choices' => [
                    [
                        'message' => [
                            'content' => json_encode([
                                'title' => '',
                                'components' => [],
                            ]),
                        ],
                    ],
                ],
            ], 200),
        ]);

        $response = $this->postJson('/api/ai/generate-bom', [
            'input_mode' => 'text',
            'input' => 'Some hardware project idea',
        ]);

        $response->assertStatus(422)
            ->assertJson([
                'success' => false,
            ]);
    }

    public function test_ai_request_payload_has_max_completion_tokens_and_compact_schema(): void
    {
        Config::set('services.openai.api_key', 'test-openai-key');
        Config::set('services.openai.model', 'gpt-4.1-mini');

        $mockOpenAiResponse = [
            'title' => 'Home Intruder Alarm System',
            'category' => 'electronics',
            'buildInstructions' => [
                'Step 1: Connect PIR sensor VCC to 5V, GND to GND, and OUT to GPIO 13.',
                'Step 2: Connect active buzzer positive pin to GPIO 12 with a current-limiting resistor.',
                'Step 3: Program ESP32 to send push notifications via Wi-Fi upon motion trigger.',
            ],
            'storeSuggestions' => [
                [
                    'name' => 'PC Express',
                    'type' => 'electronics',
                    'reason' => 'Good for microcontrollers and power supplies.',
                ],
                [
                    'name' => 'Wilcon Depot',
                    'type' => 'hardware',
                    'reason' => 'Enclosures and mounting hardware.',
                ],
            ],
            'components' => [
                [
                    'orig' => 'ESP32 NodeMCU Development Board',
                    'local' => 'ESP32 Wi-Fi Module',
                    'notes' => '3.3V logic microcontroller with built-in Wi-Fi',
                    'qty' => 1,
                    'selectedOptionIndex' => 0,
                    'isBought' => false,
                    'isCustom' => false,
                    'category' => 'Microcontrollers',
                    'options' => [],
                ],
                [
                    'orig' => 'HC-SR501 PIR Motion Sensor',
                    'local' => 'PIR Motion Detector Module',
                    'notes' => 'Adjustable sensitivity and delay, 5V power input',
                    'qty' => 1,
                    'selectedOptionIndex' => 0,
                    'isBought' => false,
                    'isCustom' => false,
                    'category' => 'Sensors',
                    'options' => [],
                ],
            ],
        ];

        Http::fake([
            'https://api.openai.com/v1/chat/completions' => Http::response([
                'choices' => [
                    [
                        'message' => [
                            'content' => json_encode($mockOpenAiResponse),
                        ],
                    ],
                ],
            ], 200),
        ]);

        $prompt = 'Build a small home security system that detects when someone enters the house and alerts the homeowner.';

        $response = $this->postJson('/api/ai/generate-bom', [
            'input_mode' => 'text',
            'input' => $prompt,
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'success' => true,
                'project' => [
                    'title' => 'Home Intruder Alarm System',
                    'category' => 'electronics',
                ],
            ]);

        // Verify the outgoing HTTP request payload structure
        Http::assertSent(function (\Illuminate\Http\Client\Request $request) {
            if (!str_contains($request->url(), 'chat/completions')) {
                return false;
            }
            $data = $request->data();

            // 1. max_completion_tokens must be set to 2000
            $hasMaxTokens = isset($data['max_completion_tokens']) && $data['max_completion_tokens'] === 2000;

            // 2. Model must match configuration
            $hasModel = isset($data['model']) && ($data['model'] === 'gpt-4.1-mini');

            // 3. Schema descriptions removed for compactness
            $schemaProps = $data['response_format']['json_schema']['schema']['properties'] ?? [];
            $noTitleDesc = !isset($schemaProps['title']['description']);
            $noCategoryDesc = !isset($schemaProps['category']['description']);

            // 4. Compact system prompt
            $systemContent = $data['messages'][0]['content'] ?? '';
            $compactSystemPrompt = str_contains($systemContent, 'Analyze the project to produce a structured BOM');

            return $hasMaxTokens && $hasModel && $noTitleDesc && $noCategoryDesc && $compactSystemPrompt;
        });

        // Verify project contents returned
        $project = $response->json('project');
        $this->assertEquals('Home Intruder Alarm System', $project['title']);
        $this->assertCount(2, $project['components']);
        $this->assertCount(3, $project['buildInstructions']);
        $this->assertCount(2, $project['suggestedStores']);
    }
}
