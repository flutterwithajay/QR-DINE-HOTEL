import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitchen_app/main.dart';

void main() {
  testWidgets('Kitchen app loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const KitchenApp());

    // Verify that the app bar title is shown
    expect(find.text('🍳 Kitchen Orders'), findsOneWidget);
    
    // Verify that order tabs are shown
    expect(find.text('Pending'), findsOneWidget);
    expect(find.text('Preparing'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
    expect(find.text('Served'), findsOneWidget);
  });
}