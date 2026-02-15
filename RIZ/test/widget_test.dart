import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:demo/main.dart'; // Ensure 'demo' matches your project name

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // We changed MyApp to RISApp here
    await tester.pumpWidget(const RISApp());

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add_task));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
