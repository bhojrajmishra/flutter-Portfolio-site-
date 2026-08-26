// Basic smoke test: the app boots and renders the public site route.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:portfolio_app/main.dart';

void main() {
  testWidgets('App boots and shows the public site', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PortfolioApp()));
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
