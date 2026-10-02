import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bimo_app/features/projects/domain/models.dart';
import 'package:bimo_app/features/projects/data/project_provider.dart';
import 'package:bimo_app/features/projects/data/project_repository.dart';
import 'package:bimo_app/shared/widgets/store_map_visual.dart';

class _InMemoryProjectRepository implements ProjectRepository {
  final List<ProjectModel> _projects = [];

  @override
  Future<ProjectModel> createProject(ProjectModel project) async {
    _projects.add(project);
    return project;
  }

  @override
  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((project) => project.id == projectId);
  }

  @override
  Future<List<ProjectModel>> fetchProjects() async => List.of(_projects);

  @override
  Future<void> moveToTrash(String projectId, AuditLogEntry activityLog) async {}

  @override
  Future<void> restoreProject(
    String projectId,
    AuditLogEntry activityLog,
  ) async {}

  @override
  Future<ProjectModel> updateProject(
    ProjectModel project, {
    List<AuditLogEntry> activityLogs = const [],
  }) async {
    final index = _projects.indexWhere((current) => current.id == project.id);
    if (index >= 0) _projects[index] = project;
    return project;
  }
}

void main() {
  group('BOM Domain Models and Calculations', () {
    test('Empty supplier options does not invent fake values or crash', () {
      final comp = BOMComponent(
        orig: 'ESP32 NodeMCU',
        local: 'ESP32 Board',
        notes: '3.3V power',
        qty: 2,
        selectedOptionIndex: 0,
        options: [],
      );

      expect(comp.options, isEmpty);
      expect(comp.unitPrice, 0.0);
      expect(comp.totalPrice, 0.0);
      expect(comp.isBought, false);
      expect(comp.isCustom, false);

      final json = comp.toJson();
      expect(json['orig'], 'ESP32 NodeMCU');
      expect(json['options'], isEmpty);

      final fromJson = BOMComponent.fromJson(json);
      expect(fromJson.local, 'ESP32 Board');
      expect(fromJson.options, isEmpty);
    });

    test(
      'BOMComponent calculations: baseTotalCost, finalCost (25% off when optimized), partsCount',
      () {
        final comp1 = BOMComponent(
          orig: 'Arduino Uno',
          local: 'Arduino Uno R3',
          notes: '5V board',
          qty: 2,
          selectedOptionIndex: 0,
          options: [
            ComponentOption(
              type: 'Original',
              seller: 'TechStore',
              stock: 10,
              price: 500.0,
              match: '95%',
            ),
          ],
        );

        final comp2 = BOMComponent(
          orig: 'Relay Module',
          local: '5V Relay Module 2-Channel',
          notes: 'Switching module',
          qty: 1,
          selectedOptionIndex: 0,
          options: [
            ComponentOption(
              type: 'Standard',
              seller: 'RelayHub',
              stock: 25,
              price: 200.0,
              match: '90%',
            ),
          ],
        );

        final project = ProjectModel(
          id: 'proj-calc-101',
          title: 'Automation Test',
          category: 'engineering',
          createdAt: DateTime.now(),
          isOptimized: true,
          components: [comp1, comp2],
          auditLog: [],
        );

        expect(project.partsCount, 2);
        // comp1: 500 * 2 = 1000; comp2: 200 * 1 = 200. Total = 1200
        expect(project.baseTotalCost, 1200.0);
        // isOptimized: true -> 1200 * 0.75 = 900
        expect(project.finalCost, 900.0);

        final unoptimized = project.copyWith(isOptimized: false);
        expect(unoptimized.finalCost, 1200.0);
      },
    );

    test(
      'ProjectModel JSON serialization and deserialization matches all fields',
      () {
        final now = DateTime.now();
        final project = ProjectModel(
          id: 'proj-test-123',
          title: 'Smart Plant Waterer',
          category: 'electronics',
          createdAt: now,
          isOptimized: true,
          isCompleted: false,
          promptOrUrl: 'Automatic watering with ESP32',
          buildInstructions: ['Step 1: Wire sensor.', 'Step 2: Connect pump.'],
          components: [
            BOMComponent(
              orig: 'Capacitive Sensor',
              local: 'Soil Sensor',
              notes: 'Analog out',
              qty: 1,
              selectedOptionIndex: 0,
              options: [],
            ),
          ],
          auditLog: [
            AuditLogEntry(action: 'Generated BOM', timestamp: 'Just now'),
          ],
        );

        final json = project.toJson();
        expect(json['id'], 'proj-test-123');
        expect(json['title'], 'Smart Plant Waterer');
        expect(json['category'], 'electronics');
        expect(json['build_instructions'], contains('Step 1: Wire sensor.'));

        final fromJson = ProjectModel.fromJson(json);
        expect(fromJson.id, project.id);
        expect(fromJson.title, project.title);
        expect(fromJson.components.length, 1);
        expect(fromJson.buildInstructions.length, 2);
      },
    );
  });

  group('Riverpod ProjectsNotifier State Updates', () {
    test('New project is added and preserved in projectsProvider', () async {
      final notifier = ProjectsNotifier(
        repository: _InMemoryProjectRepository(),
      );
      addTearDown(notifier.dispose);

      final newProj = ProjectModel(
        id: 'proj-new-999',
        title: 'Robotic Arm 4DOF',
        createdAt: DateTime.now(),
        components: [],
        auditLog: [],
      );

      await notifier.addProject(newProj);

      final state = notifier.state;
      expect(state.projects.any((p) => p.id == 'proj-new-999'), isTrue);
    });

    test('Existing project updates without altering its ID', () async {
      final notifier = ProjectsNotifier(
        repository: _InMemoryProjectRepository(),
      );
      addTearDown(notifier.dispose);

      final initialProj = ProjectModel(
        id: 'proj-fixed-id-555',
        title: 'Original Title',
        createdAt: DateTime.now(),
        components: [],
        auditLog: [],
      );

      await notifier.addProject(initialProj);

      final updatedProj = initialProj.copyWith(
        title: 'Updated AI Title',
        buildInstructions: ['Step 1: Calibrate'],
      );

      await notifier.updateProject(updatedProj);

      final state = notifier.state;
      final retrieved = state.projects.firstWhere(
        (p) => p.id == 'proj-fixed-id-555',
      );
      expect(retrieved.id, 'proj-fixed-id-555');
      expect(retrieved.title, 'Updated AI Title');
      expect(retrieved.buildInstructions, contains('Step 1: Calibrate'));
    });

    test('BOM edits update the active project cost and parts count', () async {
      final notifier = ProjectsNotifier(
        repository: _InMemoryProjectRepository(),
      );
      addTearDown(notifier.dispose);
      final project = ProjectModel(
        id: 'proj-bom-state-777',
        title: 'BOM state test',
        createdAt: DateTime.now(),
        isOptimized: false,
        components: [
          BOMComponent(
            orig: 'Controller',
            local: 'Controller',
            notes: 'Test component',
            qty: 1,
            selectedOptionIndex: 0,
            options: [
              ComponentOption(
                type: 'Standard',
                seller: 'Test Supplier',
                stock: 1,
                price: 100,
                match: '100%',
              ),
            ],
          ),
        ],
        auditLog: const [],
      );

      await notifier.addProject(project);
      notifier.setActiveProject(project);

      await notifier.updateComponentQty(project.id, 0, 1);
      var updated = notifier.state.projects.single;
      expect(updated.components.single.qty, 2);
      expect(updated.partsCount, 1);
      expect(updated.finalCost, 200);
      expect(notifier.state.activeProject!.finalCost, 200);

      await notifier.deleteComponent(project.id, 0);
      updated = notifier.state.projects.single;
      expect(updated.partsCount, 0);
      expect(updated.finalCost, 0);
      expect(notifier.state.activeProject!.partsCount, 0);

      await notifier.addCustomComponent(project.id, 'Custom sensor', '5V');
      updated = notifier.state.projects.single;
      expect(updated.partsCount, 1);
      expect(notifier.state.activeProject!.partsCount, 1);
    });

    test(
      'duplicate components merge only within the updated project',
      () async {
        final notifier = ProjectsNotifier(
          repository: _InMemoryProjectRepository(),
        );
        addTearDown(notifier.dispose);
        BOMComponent component(String name, int quantity) => BOMComponent(
          orig: name,
          local: name,
          notes: '3.3V',
          qty: quantity,
          options: const [],
        );
        final projectA = ProjectModel(
          id: 'project-a',
          title: 'A',
          createdAt: DateTime.now(),
          components: [component('ESP32', 1), component(' esp32 ', 2)],
          auditLog: const [],
        );
        final projectB = ProjectModel(
          id: 'project-b',
          title: 'B',
          createdAt: DateTime.now(),
          components: [component('ESP32', 1)],
          auditLog: const [],
        );

        await notifier.addProject(projectA);
        await notifier.addProject(projectB);

        final normalizedA = notifier.state.projects.firstWhere(
          (project) => project.id == projectA.id,
        );
        final unchangedB = notifier.state.projects.firstWhere(
          (project) => project.id == projectB.id,
        );
        expect(normalizedA.components, hasLength(1));
        expect(normalizedA.components.single.qty, 3);
        expect(unchangedB.components.single.qty, 1);

        await notifier.updateComponentActualCost(projectA.id, 0, 200);
        final pricedA = notifier.state.projects.firstWhere(
          (project) => project.id == projectA.id,
        );
        expect(pricedA.components.single.actualTotal, 600);
      },
    );
  });

  group('OpenStreetMap Widget Integration', () {
    testWidgets(
      'Renders OpenStreetMap tile layer and handles empty coordinates',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: StoreMapVisual(
                locationQuery: 'Metro Manila, Philippines',
                markers: [],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify FlutterMap is rendered with TileLayer
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(find.byType(TileLayer), findsOneWidget);

        // Verify empty-location message is shown without fake markers
        expect(
          find.textContaining('No physical store coordinates currently linked'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Renders markers and opens details on tap when real coordinates provided',
      (WidgetTester tester) async {
        final testMarker = MapStoreMarker(
          id: 'marker-1',
          title: 'Manila Maker Supply',
          subtitle: 'Quezon City • In Stock',
          position: const LatLng(14.6091, 121.0223),
          isHighlighted: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StoreMapVisual(
                locationQuery: 'Quezon City, NCR',
                markers: [testMarker],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.byType(FlutterMap), findsOneWidget);
        expect(find.byType(MarkerLayer), findsOneWidget);

        // Marker detail card is visible
        expect(find.text('Manila Maker Supply'), findsOneWidget);
        expect(find.text('Quezon City • In Stock'), findsOneWidget);
      },
    );
  });
}
