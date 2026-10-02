import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bimo_app/shared/widgets/bimo_notification.dart';
import 'package:bimo_app/auth/services/mock_auth_service.dart';
import 'package:bimo_app/features/projects/domain/models.dart';

void main() {
  group('BiMO Notification Tests', () {
    testWidgets(
      'shows success notification matching Project Saved style on desktop',
      (tester) async {
        tester.view.physicalSize = const Size(1200, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => showBiMONotification(
                    context,
                    message: 'Plan saved successfully.',
                  ),
                  child: const Text('Show Notification'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Notification'));
        await tester.pump(); // Start animation
        await tester.pump(const Duration(milliseconds: 300)); // Animate in

        expect(find.text('Plan saved successfully.'), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

        final snackBarFinder = find.byType(SnackBar);
        expect(snackBarFinder, findsOneWidget);
        final snackBar = tester.widget<SnackBar>(snackBarFinder);
        expect(snackBar.behavior, SnackBarBehavior.floating);
        expect(snackBar.backgroundColor, const Color(0xFF1E2028));

        // Desktop bottom-right margin check
        final margin = snackBar.margin as EdgeInsets;
        expect(margin.right, 24);
        expect(margin.bottom, 24);
        expect(margin.left, 1200 - 340);
      },
    );

    testWidgets('shows success notification on mobile with safe margins', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showBiMONotification(
                  context,
                  message: 'Logged in successfully.',
                ),
                child: const Text('Show Notification'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Notification'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Logged in successfully.'), findsOneWidget);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final margin = snackBar.margin as EdgeInsets;
      expect(margin.left, 16);
      expect(margin.right, 16);
      expect(margin.bottom, 20);
    });

    testWidgets('shows error notification with error icon and red accent', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => showBiMONotification(
                  context,
                  message:
                      'Unable to log in. Please check your email and password.',
                  isError: true,
                ),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.text('Unable to log in. Please check your email and password.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets(
      'PersistentAuthNotification persists until cleared on successful login',
      (tester) async {
        AuthNotificationState.clear();
        addTearDown(AuthNotificationState.clear);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Center(child: Text('Login Screen Content')),
                  PersistentAuthNotification(),
                ],
              ),
            ),
          ),
        );

        // Initially no notification
        expect(find.byType(BiMONotificationCard), findsNothing);

        // Trigger account created notification
        const testMsg =
            'Account created successfully. A confirmation email has been sent to your email. Please confirm your email before logging in.';
        AuthNotificationState.showAccountCreated(testMsg);
        await tester.pump();

        expect(find.byType(BiMONotificationCard), findsOneWidget);
        expect(find.text(testMsg), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);

        // Advance time - verify it does NOT auto-dismiss
        await tester.pump(const Duration(seconds: 10));
        expect(find.byType(BiMONotificationCard), findsOneWidget);
        expect(find.text(testMsg), findsOneWidget);

        // Login succeeds -> clear notification
        AuthNotificationState.clear();
        await tester.pump();
        expect(find.byType(BiMONotificationCard), findsNothing);
      },
    );
  });

  group('Custom BOM Item Category Tests', () {
    test('bomCategories contains all 9 required categories', () {
      const expected = [
        'Microcontrollers',
        'Sensors',
        'Actuators',
        'Power',
        'Passive Components',
        'Hardware',
        'Modules',
        'Connectivity',
        'Other',
      ];
      expect(bomCategories, expected);
    });

    test('BOMComponent defaults to Hardware if category not specified', () {
      final comp = BOMComponent(
        orig: 'Custom Bolt',
        local: 'Custom Bolt',
        notes: 'M3x10',
      );
      expect(comp.category, 'Hardware');
    });

    test(
      'BOMComponent retains custom chosen category across serialization',
      () {
        final comp = BOMComponent(
          orig: 'BME280',
          local: 'BME280',
          category: 'Sensors',
          notes: 'I2C Temp/Humidity',
          isCustom: true,
        );
        expect(comp.category, 'Sensors');

        final json = comp.toJson();
        expect(json['category'], 'Sensors');

        final restored = BOMComponent.fromJson(json);
        expect(restored.category, 'Sensors');
        expect(restored.isCustom, isTrue);
      },
    );

    test('componentIdentity distinguishes items in different categories', () {
      final comp1 = BOMComponent(
        orig: 'ESP32',
        local: 'ESP32',
        category: 'Microcontrollers',
        notes: 'WROOM-32',
      );
      final comp2 = BOMComponent(
        orig: 'ESP32',
        local: 'ESP32',
        category: 'Modules',
        notes: 'WROOM-32',
      );

      expect(componentIdentity(comp1), isNot(equals(componentIdentity(comp2))));

      final merged = normalizeComponents([comp1, comp2]);
      expect(merged.length, 2);
    });
  });

  group('RegisterResult Logic Tests', () {
    test(
      'RegisterResult captures email confirmation requirement correctly',
      () {
        const emailConfirmResult = RegisterResult(
          isSuccess: true,
          requiresEmailConfirmation: true,
        );
        expect(emailConfirmResult.isSuccess, isTrue);
        expect(emailConfirmResult.requiresEmailConfirmation, isTrue);

        const immediateResult = RegisterResult(
          isSuccess: true,
          requiresEmailConfirmation: false,
        );
        expect(immediateResult.isSuccess, isTrue);
        expect(immediateResult.requiresEmailConfirmation, isFalse);

        const failureResult = RegisterResult(
          isSuccess: false,
          errorMessage: 'Unable to create an account.',
        );
        expect(failureResult.isSuccess, isFalse);
        expect(failureResult.errorMessage, 'Unable to create an account.');
      },
    );
  });
}
