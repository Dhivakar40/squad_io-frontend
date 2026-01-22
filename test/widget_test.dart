import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squad_io/screens/login_screen.dart';

void main() {
  testWidgets('Login Screen UI smoke test', (WidgetTester tester) async {
    // 1. Build the LoginScreen wrapped in a MaterialApp 
    // (We wrap it because LoginScreen uses Scaffold/Theme which require MaterialApp)
    await tester.pumpWidget(const MaterialApp(
      home: LoginScreen(),
    ));

    // 2. Verify that our key UI elements are present
    // Check for the main title
    expect(find.text('Student Login'), findsOneWidget);

    // Check for the subtitle
    expect(find.text('Use your college credentials'), findsOneWidget);

    // 3. Verify that the "Counter" text (from the old template) is NOT present
    expect(find.text('0'), findsNothing);
    expect(find.byIcon(Icons.add), findsNothing);
  });
}