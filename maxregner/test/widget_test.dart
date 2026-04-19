import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maxregner/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaxRegnerApp());
    await tester.pump();
    expect(find.textContaining('MaxRegner'), findsAtLeastNWidgets(0));
  });
}
