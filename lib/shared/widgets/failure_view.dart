import 'package:flutter/material.dart';
import '../../core/errors/app_failure.dart';

class FailureView extends StatelessWidget {
  const FailureView({super.key, required this.error, this.retry});
  final Object error;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline_rounded, size: 36),
          const SizedBox(height: 16),
          Text(
            error is AppFailure
                ? (error as AppFailure).message
                : 'Something went wrong. Please try again.',
            textAlign: TextAlign.center,
          ),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

void showFailure(BuildContext context, Object error) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        error is AppFailure
            ? error.message
            : 'Something went wrong. Please try again.',
      ),
    ),
  );
}
