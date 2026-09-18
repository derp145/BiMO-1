<?php

namespace Tests\Feature;

use App\Models\Project;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ProjectCrudTest extends TestCase
{
    use RefreshDatabase;

    public function test_can_store_and_retrieve_projects(): void
    {
        $projectData = [
            'id' => 'proj-test-101',
            'title' => 'Automated Hydroponics Station',
            'category' => 'engineering',
            'created_at' => now()->toIso8601String(),
            'is_optimized' => true,
            'is_completed' => false,
            'build_instructions' => ['Step 1', 'Step 2'],
            'components' => [
                [
                    'orig' => 'Water Pump 12V',
                    'local' => '12V Submersible Pump',
                    'notes' => 'Food grade submersible pump',
                    'qty' => 1,
                    'selectedOptionIndex' => 0,
                    'options' => [],
                    'isBought' => false,
                    'isCustom' => false,
                    'category' => 'Actuators',
                    'actualCost' => null,
                ],
            ],
            'audit_log' => [
                ['action' => 'Created project', 'timestamp' => 'Just now'],
            ],
        ];

        $storeResponse = $this->postJson('/api/projects', $projectData);
        $storeResponse->assertStatus(201)
            ->assertJson([
                'message' => 'Project saved successfully.',
            ]);

        $this->assertDatabaseHas('projects', [
            'id' => 'proj-test-101',
            'title' => 'Automated Hydroponics Station',
        ]);

        $getResponse = $this->getJson('/api/projects/proj-test-101');
        $getResponse->assertStatus(200)
            ->assertJson([
                'id' => 'proj-test-101',
                'title' => 'Automated Hydroponics Station',
            ]);

        $updateResponse = $this->putJson('/api/projects/proj-test-101', [
            'title' => 'Automated Hydroponics Station v2',
            'is_completed' => true,
        ]);
        $updateResponse->assertStatus(200);

        $this->assertDatabaseHas('projects', [
            'id' => 'proj-test-101',
            'title' => 'Automated Hydroponics Station v2',
            'is_completed' => 1,
        ]);

        $deleteResponse = $this->deleteJson('/api/projects/proj-test-101');
        $deleteResponse->assertStatus(200);

        $this->assertDatabaseMissing('projects', [
            'id' => 'proj-test-101',
        ]);
    }
}
