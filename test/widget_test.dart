import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eventtab/main.dart';
import 'package:eventtab/signin.dart';

void main() {
  setUp(AuthCredentialsStore.clear);

  testWidgets('creates an account and logs in with it', (tester) async {
    await tester.pumpWidget(
      MyApp(
        statusLoader: () async {
          return const BackendStatus(
            status: 'ok',
            backend: 'django',
            database: DatabaseStatus(
              engine: 'django.db.backends.postgresql',
              configuredName: 'eventtabs',
              currentDatabase: 'eventtabs',
              currentUser: 'event_users',
              serverAddr: '127.0.0.1',
              serverPort: 5432,
            ),
          );
        },
      ),
    );

    await tester.pump();

    expect(find.text('EVENTTAB'), findsOneWidget);
    expect(find.text('LOG IN'), findsOneWidget);

    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    expect(find.text('CREATE ACCOUNT'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'EMAIL OR USERNAME'),
      'admin',
    );
    await tester.enterText(find.widgetWithText(TextField, 'PASSWORD'), 'pass');
    await tester.enterText(
      find.widgetWithText(TextField, 'CONFIRM PASSWORD'),
      'pass',
    );
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'EMAIL OR USERNAME'),
      'admin',
    );
    await tester.enterText(find.widgetWithText(TextField, 'PASSWORD'), 'pass');
    await tester.tap(find.text('LOG IN'));
    await tester.pumpAndSettle();

    expect(find.text('Django backend connected'), findsOneWidget);
    expect(find.text('django.db.backends.postgresql'), findsOneWidget);
    expect(find.text('eventtabs'), findsOneWidget);
    expect(find.text('event_users'), findsOneWidget);
  });
}
