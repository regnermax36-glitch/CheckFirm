import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maxregner/main.dart';

void main() {
  testWidgets('MaxRegner Studio Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MaxRegnerStudioApp());

    // Verify that our app displays "MaxRegner".
    expect(find.text('MaxRegner'), findsOneWidget);
    expect(find.text('OFFLINE AI MUSIC STUDIO'), findsOneWidget);
  });
}
