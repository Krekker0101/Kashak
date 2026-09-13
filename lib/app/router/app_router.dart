import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../bootstrap/providers.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/projects/presentation/projects_screen.dart';
import '../../features/image_editor/presentation/editor_screen.dart';
import '../../features/tracing/presentation/tracing_screen.dart';
import '../../features/tracing/presentation/camera_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: ref.read(preferencesProvider).getBool('onboarded') == true
        ? '/'
        : '/welcome',
    routes: [
      GoRoute(path: '/', builder: (_, state) => const HomeScreen()),
      GoRoute(
        path: '/welcome',
        builder: (_, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/projects', builder: (_, state) => const ProjectsScreen()),
      GoRoute(path: '/settings', builder: (_, state) => const SettingsScreen()),
      GoRoute(path: '/camera', builder: (_, state) => const CameraScreen()),
      GoRoute(
        path: '/editor/:id',
        builder: (_, state) => EditorScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/trace/:id',
        builder: (_, state) => TracingScreen(id: state.pathParameters['id']!),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => context.go('/'),
          child: const Text('Page not found · Go home'),
        ),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
