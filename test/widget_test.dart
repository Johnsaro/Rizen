import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rizen/main.dart';
void main() {
  testWidgets('Rizen app launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RizenApp(home: Scaffold(body: Text('Guild Master'))));
    expect(find.text('Guild Master'), findsOneWidget);
  });
}
