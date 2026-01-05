import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waste_tracker/home_page.dart';

void main() {
  testWidgets('HomeScreen shows welcome text and location button', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
  MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HomePage(),
  ),
);

    // Check for home page text
    expect(find.text('Home Page'), findsOneWidget);

    // Check for the button
    expect(find.text('Open Map'), findsOneWidget);
  });
}