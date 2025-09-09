// This is a basic Flutter widget test for the Kids Learning App.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newt_2/main.dart';

void main() {
  testWidgets('Kids Learning App landing page test', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KidsLearningApp());

    // Verify that the main title is displayed.
    expect(find.text('🌟 Kids Learning Adventure 🌟'), findsOneWidget);

    // Verify that the welcome message is displayed.
    expect(find.text('Welcome, Little Explorer!'), findsOneWidget);
    expect(find.text('Ready for fun learning?'), findsOneWidget);

    // Verify that all menu cards are present.
    expect(find.text('Mini Games'), findsOneWidget);
    expect(find.text('Storybooks'), findsOneWidget);
    expect(find.text('Learn ABC'), findsOneWidget);
    expect(find.text('Numbers'), findsOneWidget);
    expect(find.text('Colors & Shapes'), findsOneWidget);
    expect(find.text('Achievements'), findsOneWidget);

    // Test tapping on a menu card (Mini Games).
    await tester.tap(find.text('Mini Games'));
    await tester.pump();

    // Verify that a snackbar appears with the correct message.
    expect(find.text('Opening Mini Games...'), findsOneWidget);

    // Wait for snackbar to disappear.
    await tester.pump(const Duration(seconds: 3));

    // Test settings button.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();

    // Verify settings dialog appears.
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Sound Effects'), findsOneWidget);
    expect(find.text('Background Music'), findsOneWidget);
    expect(find.text('Parental Controls'), findsOneWidget);

    // Close the dialog.
    await tester.tap(find.text('Close'));
    await tester.pump();

    // Verify dialog is closed.
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('Menu cards interaction test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KidsLearningApp());

    // Test each menu card.
    final menuItems = [
      'Mini Games',
      'Storybooks',
      'Learn ABC',
      'Numbers',
      'Colors & Shapes',
      'Achievements',
    ];

    for (final item in menuItems) {
      // Tap the menu item.
      await tester.tap(find.text(item));
      await tester.pump();

      // Verify snackbar appears.
      expect(find.text('Opening $item...'), findsOneWidget);

      // Wait for snackbar to disappear.
      await tester.pump(const Duration(seconds: 3));
    }
  });
}
