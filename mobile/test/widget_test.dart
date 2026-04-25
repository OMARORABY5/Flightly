// widget_test.dart — FLIGHTLY Basic Widget Test
// Updated to reference the correct app class name

import 'package:flutter_test/flutter_test.dart';
import 'package:flightly/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flightly/core/providers/storage_provider.dart';

void main() {
  testWidgets('FLIGHTLY app smoke test', (WidgetTester tester) async {
    // Setup mock preferences for the test
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build the app with ProviderScope and overrides
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const FlightlyApp(),
      ),
    );

    // Initial check (may need pumpAndSettle for GoRouter)
    await tester.pumpAndSettle();
  });
}
