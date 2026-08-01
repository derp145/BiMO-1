import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bimo_app/main.dart';

void main() {
  testWidgets('BiMO App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: BiMoApp()));

    // Verify that BiMO title or app renders.
    expect(find.byType(BiMoApp), findsOneWidget);

    // Pump to settle frame animations
    await tester.pump(const Duration(milliseconds: 500));
  });
}
