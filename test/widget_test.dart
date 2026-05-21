import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventtab/main.dart';

void main() {
  testWidgets('shows login and create account screen', (tester) async {
    await tester.pumpWidget(const MyApp());

    await tester.pump();

    expect(find.text('EVENTTAB'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);

    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('CREATE ACCOUNT'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'USERNAME'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'EMAIL ADDRESS'), findsOneWidget);
  });
}
