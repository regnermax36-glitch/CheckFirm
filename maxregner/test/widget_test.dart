import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maxregner/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaxRegnerApp());

    // Verify that our app displays "MaxRegner AI".
    expect(find.text('MaxRegner AI'), findsOneWidget);
  });
}
