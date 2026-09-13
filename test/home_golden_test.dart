import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:scetch/app/bootstrap/providers.dart';
import 'package:scetch/app/theme/scetch_theme.dart';
import 'package:scetch/features/home/presentation/home_screen.dart';
import 'package:scetch/features/onboarding/presentation/onboarding_screen.dart';
import 'support/memory_project_repository.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('home ${dark ? 'dark' : 'light'} golden', (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(preferences),
            projectRepositoryProvider.overrideWithValue(
              MemoryProjectRepository(),
            ),
          ],
          child: MaterialApp(
            theme: ScetchTheme.create(
              dark ? Brightness.dark : Brightness.light,
            ),
            home: const RepaintBoundary(key: Key('home'), child: HomeScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const Key('home')),
        matchesGoldenFile('goldens/home_${dark ? 'dark' : 'light'}.png'),
      );
    }, tags: ['golden']);
  }
  testWidgets('onboarding fits a phone with large text', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const OnboardingScreen(),
        ),
      ),
    );
    await tester.ensureVisible(find.text('Start drawing'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
