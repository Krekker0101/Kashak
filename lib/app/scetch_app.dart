import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/settings/presentation/settings_screen.dart';
import 'router/app_router.dart';
import 'theme/scetch_theme.dart';

class ScetchApp extends ConsumerWidget {
  const ScetchApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'Scetch',
    debugShowCheckedModeBanner: false,
    theme: ScetchTheme.create(Brightness.light),
    darkTheme: ScetchTheme.create(Brightness.dark),
    themeMode: ref.watch(themeProvider),
    routerConfig: ref.watch(routerProvider),
  );
}
