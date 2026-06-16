import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic testing environment check', (WidgetTester tester) async {
    // Build a simple app to verify the testing environment is working
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Smart Student Platform Test'),
        ),
      ),
    ));

    // Verify that our text is found.
    expect(find.text('Smart Student Platform Test'), findsOneWidget);
  });
}
