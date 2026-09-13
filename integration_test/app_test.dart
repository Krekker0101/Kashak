import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scetch/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('onboarding, home, projects and settings navigation', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle();
    final start = find.text('Start drawing');
    if (start.evaluate().isNotEmpty) {
      await tester.ensureVisible(start);
      await tester.tap(start);
      await tester.pumpAndSettle();
    }
    expect(find.text('New Drawing'), findsOneWidget);
    await tester.ensureVisible(find.text('Projects'));
    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();
    expect(find.text('Your drawings'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Your drawings stay with you.'), findsOneWidget);
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.text('Appearance'))).brightness,
      Brightness.dark,
    );
  });
}
