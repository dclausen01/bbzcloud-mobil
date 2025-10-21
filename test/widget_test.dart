// BBZCloud Mobile - Widget Test
//
// Basic widget test to verify app initialization

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bbzcloud_mobil/main.dart';

void main() {
  testWidgets('App initializes without errors', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(
      const ProviderScope(
        child: BBZCloudApp(),
      ),
    );

    // Wait for async operations to complete
    await tester.pumpAndSettle();

    // Verify that the app initialized
    // (This is a basic smoke test)
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App shows loading state initially', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(
      const ProviderScope(
        child: BBZCloudApp(),
      ),
    );

    // Initially should show CircularProgressIndicator while loading
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
