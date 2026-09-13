import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../shared/widgets/failure_view.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(32),
        children: [
          const SizedBox(height: 48),
          const Icon(Icons.draw_outlined, size: 88),
          const SizedBox(height: 40),
          Text(
            'A little guidance.\nYour own hand.',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 32),
          const ListTile(
            leading: Icon(Icons.photo_outlined),
            title: Text('Choose a reference'),
            subtitle: Text('Import and prepare a photo.'),
          ),
          const ListTile(
            leading: Icon(Icons.camera_alt_outlined),
            title: Text('Set up your space'),
            subtitle: Text(
              'Secure your phone above the paper on a stable stand.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.lock_outline),
            title: Text('Align, lock, draw'),
            subtitle: Text(
              'Look through the screen and follow the lines. Hold the lock button to unlock.',
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () async {
              try {
                final saved = await ref
                    .read(preferencesProvider)
                    .setBool('onboarded', true);
                if (!saved) {
                  throw StateError('Could not save onboarding');
                }
                if (context.mounted) {
                  context.go('/');
                }
              } catch (error) {
                if (context.mounted) {
                  showFailure(context, error);
                }
              }
            },
            child: const Text('Start drawing'),
          ),
        ],
      ),
    ),
  );
}
