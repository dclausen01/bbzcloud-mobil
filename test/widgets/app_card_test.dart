/// BBZCloud Mobile - App Card Widget Tests
/// 
/// Widget tests for AppCard
/// 
/// @version 0.1.0

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bbzcloud_mobil/core/constants/navigation_apps.dart';
import 'package:bbzcloud_mobil/presentation/widgets/app_card.dart';

void main() {
  group('AppCard Widget', () {
    testWidgets('displays app title correctly', (tester) async {
      final testApp = AppItem(
        id: 'test',
        title: 'Test App',
        url: 'https://test.com',
        icon: Icons.star,
        color: Colors.blue,
        requiresAuth: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              app: testApp,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test App'), findsOneWidget);
    });

    testWidgets('displays app icon correctly', (tester) async {
      final testApp = AppItem(
        id: 'test',
        title: 'Test App',
        url: 'https://test.com',
        icon: Icons.school,
        color: Colors.blue,
        requiresAuth: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              app: testApp,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      final testApp = AppItem(
        id: 'test',
        title: 'Test App',
        url: 'https://test.com',
        icon: Icons.star,
        color: Colors.blue,
        requiresAuth: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              app: testApp,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('displays description when provided', (tester) async {
      final testApp = AppItem(
        id: 'test',
        title: 'Test App',
        description: 'Test Description',
        url: 'https://test.com',
        icon: Icons.star,
        color: Colors.blue,
        requiresAuth: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              app: testApp,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Description'), findsOneWidget);
    });

    testWidgets('applies gradient with app color', (tester) async {
      final testColor = Colors.red;
      final testApp = AppItem(
        id: 'test',
        title: 'Test App',
        url: 'https://test.com',
        icon: Icons.star,
        color: testColor,
        requiresAuth: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              app: testApp,
              onTap: () {},
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(InkWell),
          matching: find.byType(Container),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;
      
      expect(gradient.colors.first, testColor);
    });
  });
}
