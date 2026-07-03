import 'package:edutech_app/shared/widgets/app_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('LoadingWidget', () {
    testWidgets('always shows a spinner', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingWidget()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows the message when provided', (tester) async {
      await tester.pumpWidget(_wrap(const LoadingWidget(message: 'Loading…')));
      expect(find.text('Loading…'), findsOneWidget);
    });
  });

  group('ErrorRetryWidget', () {
    testWidgets('renders the message and fires onRetry when tapped', (
      tester,
    ) async {
      var tapped = 0;
      await tester.pumpWidget(
        _wrap(
          ErrorRetryWidget(
            message: 'Something went wrong',
            onRetry: () => tapped++,
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(tapped, 1);
    });
  });

  group('StatChip', () {
    testWidgets('renders its label', (tester) async {
      await tester.pumpWidget(
        _wrap(const StatChip(label: 'Rank #3', color: Colors.indigo)),
      );
      expect(find.text('Rank #3'), findsOneWidget);
    });
  });
}
