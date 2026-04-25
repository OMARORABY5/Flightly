// widget_test.dart — FLIGHTLY Basic Widget Test
// Updated to reference the correct app class name

import 'package:flutter_test/flutter_test.dart';
import 'package:flightly/main.dart';

void main() {
  testWidgets('FLIGHTLY app smoke test', (WidgetTester tester) async {
    // Build the app with onboarding shown (first launch)
    await tester.pumpWidget(
      const FlightlyApp(showOnboarding: true),
    );

    // Verify FLIGHTLY title is present
    expect(find.text('FLIGHTLY'), findsOneWidget);
  });
}
