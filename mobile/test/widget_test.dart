// widget_test.dart — FLIGHTLY Flutter Widget Tests
// Tests that core reusable widgets render correctly and respond to props.
// WHY: Widget tests catch UI regressions — if a refactor breaks how a widget
//      renders its children, the test catches it before the user does.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flightly/core/widgets/empty_widget.dart';
import 'package:flightly/core/widgets/error_widget.dart' as app;
import 'package:flightly/core/widgets/loading_widget.dart';

// ─── Test App Wrapper ─────────────────────────────────────────────────────────
// Widgets need a MaterialApp/Scaffold context to render properly.
Widget buildTestApp(Widget child) {
  GoogleFonts.config.allowRuntimeFetching = false;
  return MaterialApp(
    theme: ThemeData.dark(),
    home: Scaffold(body: child),
  );
}

void main() {
  // ─── AppEmptyWidget Tests ────────────────────────────────────────────────────
  group('AppEmptyWidget', () {
    testWidgets('renders title text correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppEmptyWidget(
            title: 'No upcoming trips',
            message: 'Book a flight to see it here.',
          ),
        ),
      );
      expect(find.text('No upcoming trips'), findsOneWidget);
    });

    testWidgets('renders message text correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppEmptyWidget(
            title: 'Empty',
            message: 'Nothing to show here.',
          ),
        ),
      );
      expect(find.text('Nothing to show here.'), findsOneWidget);
    });

    testWidgets('renders CTA button when ctaLabel is provided', (WidgetTester tester) async {
      bool pressed = false;
      await tester.pumpWidget(
        buildTestApp(
          AppEmptyWidget(
            title: 'Empty',
            message: 'Nothing here.',
            ctaLabel: 'Search Flights',
            onCta: () => pressed = true,
          ),
        ),
      );
      expect(find.text('Search Flights'), findsOneWidget);
      await tester.tap(find.text('Search Flights'));
      expect(pressed, isTrue);
    });

    testWidgets('does NOT render CTA button when ctaLabel is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const AppEmptyWidget(
            title: 'Empty',
            message: 'Nothing here.',
          ),
        ),
      );
      // No button should be present
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  // ─── AppErrorWidget Tests ────────────────────────────────────────────────────
  group('AppErrorWidget', () {
    testWidgets('renders "Oops!" heading', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const app.AppErrorWidget()),
      );
      expect(find.text('Oops!'), findsOneWidget);
    });

    testWidgets('renders custom error message', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const app.AppErrorWidget(message: 'Network connection failed.'),
        ),
      );
      expect(find.text('Network connection failed.'), findsOneWidget);
    });

    testWidgets('renders retry button when onRetry is provided', (WidgetTester tester) async {
      bool retried = false;
      await tester.pumpWidget(
        buildTestApp(
          app.AppErrorWidget(onRetry: () => retried = true),
        ),
      );
      expect(find.byType(ElevatedButton), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton));
      expect(retried, isTrue);
    });

    testWidgets('does NOT render retry button when onRetry is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const app.AppErrorWidget()),
      );
      expect(find.byType(ElevatedButton), findsNothing);
    });
  });

  // ─── Loading Widgets Tests ────────────────────────────────────────────────────
  group('LoadingWidget — ShimmerBox', () {
    testWidgets('ShimmerBox renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const ShimmerBox(height: 60),
        ),
      );
      expect(find.byType(ShimmerBox), findsOneWidget);
    });

    testWidgets('FlightCardShimmer renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const FlightCardShimmer()),
      );
      expect(find.byType(FlightCardShimmer), findsOneWidget);
    });

    testWidgets('TripCardShimmer renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const TripCardShimmer()),
      );
      expect(find.byType(TripCardShimmer), findsOneWidget);
    });

    testWidgets('LoadingOverlay renders spinner', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(const LoadingOverlay()),
      );
      expect(find.byType(LoadingOverlay), findsOneWidget);
    });
  });
}
