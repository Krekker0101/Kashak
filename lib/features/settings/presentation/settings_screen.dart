import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/bootstrap/providers.dart';
import '../../../shared/widgets/failure_view.dart';

final themeProvider = NotifierProvider<ThemeController, ThemeMode>(
  ThemeController.new,
);

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final index = ref.watch(preferencesProvider).getInt('theme') ?? 0;
    return ThemeMode.values[index.clamp(0, 2).toInt()];
  }

  Future<void> change(ThemeMode mode) async {
    final saved = await ref
        .read(preferencesProvider)
        .setInt('theme', mode.index);
    if (!saved) {
      throw StateError('Settings could not be saved');
    }
    state = mode;
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Settings')),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Make it yours.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        const Text('Appearance'),
        const SizedBox(height: 12),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
          ],
          selected: {ref.watch(themeProvider)},
          onSelectionChanged: (selection) async {
            try {
              await ref.read(themeProvider.notifier).change(selection.first);
            } catch (error) {
              if (context.mounted) {
                showFailure(context, error);
              }
            }
          },
        ),
        const SizedBox(height: 40),
        const Icon(Icons.shield_outlined, size: 40),
        const SizedBox(height: 16),
        const Text('Your drawings stay with you.', textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text(
          'No account. No uploads. No analytics. Images and projects are stored on this device. Deleting the app removes them.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        const Text('Scetch · 1.0.0', textAlign: TextAlign.center),
        TextButton(
          onPressed: () =>
              showLicensePage(context: context, applicationName: 'Scetch'),
          child: const Text('Open-source licenses'),
        ),
      ],
    ),
  );
}
