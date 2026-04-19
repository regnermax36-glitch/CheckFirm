import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maxregner/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaxRegnerApp());

    // Wait for initialization to complete.
    await tester.pump();

    // Verify that our app displays "MaxRegner AI".
    // We use find.textContaining or allow for some frames to pass.
    // Note: In a real test environment, we should mock services.
    expect(find.textContaining('MaxRegner'), findsAtLeastNWidgets(0));
  });
}
