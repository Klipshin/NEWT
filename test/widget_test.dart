import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:newt_2/main.dart';

void main() {
  testWidgets('Swamp Landing Page test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the main title is displayed.
    expect(find.text('Welcome to the Swamp'), findsOneWidget);

    // Verify that the welcome message is displayed.
    expect(find.text('Hello Adventurer!'), findsOneWidget);

    // Verify that all menu buttons are present.
    expect(find.text('Start Adventure'), findsOneWidget);
    expect(find.text('Load Game'), findsOneWidget);
    expect(find.text('Exit'), findsOneWidget);
  });

  testWidgets('Tap on Start Adventure button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Tap Start Adventure button
    await tester.tap(find.text('Start Adventure'));
    await tester.pump();

    // For now, just check that the tap didn’t crash.
    expect(find.text('Start Adventure'), findsOneWidget);
  });

  testWidgets('Settings button presence', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Verify settings button is present.
    expect(find.byIcon(Icons.settings), findsOneWidget);

    // Tap settings button.
    await tester.tap(find.byIcon(Icons.settings));
    await tester.pump();

    // Nothing happens yet, just ensure no crash.
    expect(find.byIcon(Icons.settings), findsOneWidget);
  });
}
