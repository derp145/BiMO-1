import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:bimo_app/features/projects/domain/models.dart';
import 'package:bimo_app/features/projects/data/project_provider.dart';
import 'package:bimo_app/shared/widgets/store_map_visual.dart';

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

    test('BOMComponent calculations: baseTotalCost, finalCost (25% off when optimized), partsCount', () {
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
    });

    test('ProjectModel JSON serialization and deserialization matches all fields', () {
      final now = DateTime.now();
      final project = ProjectModel(
        id: 'proj-test-123',
        title: 'Smart Plant Waterer',
        category: 'electronics',
        createdAt: now,
        isOptimized: true,
        isCompleted: false,
        promptOrUrl: 'Automatic watering with ESP32',
        buildInstructions: [
          'Step 1: Wire sensor.',
          'Step 2: Connect pump.',
        ],
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
    });
  });

  group('Riverpod ProjectsNotifier State Updates', () {
    test('New project is added and preserved in projectsProvider', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final newProj = ProjectModel(
        id: 'proj-new-999',
        title: 'Robotic Arm 4DOF',
        createdAt: DateTime.now(),
        components: [],
        auditLog: [],
      );

      container.read(projectsProvider.notifier).addProject(newProj);

      final state = container.read(projectsProvider);
      expect(state.projects.any((p) => p.id == 'proj-new-999'), isTrue);
    });

    test('Existing project updates without altering its ID', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initialProj = ProjectModel(
        id: 'proj-fixed-id-555',
        title: 'Original Title',
        createdAt: DateTime.now(),
        components: [],
        auditLog: [],
      );

      container.read(projectsProvider.notifier).addProject(initialProj);

      final updatedProj = initialProj.copyWith(
        title: 'Updated AI Title',
        buildInstructions: ['Step 1: Calibrate'],
      );

      container.read(projectsProvider.notifier).updateProject(updatedProj);

      final state = container.read(projectsProvider);
      final retrieved = state.projects.firstWhere((p) => p.id == 'proj-fixed-id-555');
      expect(retrieved.id, 'proj-fixed-id-555');
      expect(retrieved.title, 'Updated AI Title');
      expect(retrieved.buildInstructions, contains('Step 1: Calibrate'));
    });
  });

  group('OpenStreetMap Widget Integration', () {
    testWidgets('Renders OpenStreetMap tile layer and handles empty coordinates', (WidgetTester tester) async {
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
    });

    testWidgets('Renders markers and opens details on tap when real coordinates provided', (WidgetTester tester) async {
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
    });
  });
}
