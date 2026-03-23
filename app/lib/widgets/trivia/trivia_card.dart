import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/trivia_providers.dart';

class TriviaCard extends ConsumerWidget {
  const TriviaCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facts = ref.watch(triviaFactsProvider);
    final index = ref.watch(currentTriviaIndexProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 600),
      child: Card(
        elevation: 1, // elevation.sm
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // borderRadius.xl
          side: isDark
              ? BorderSide(color: theme.colorScheme.primary)
              : BorderSide.none,
        ),
        color: isDark
            ? theme.colorScheme.surface
            : theme.colorScheme.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Text(
                    'Did you know?',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isDark ? theme.colorScheme.primary : theme.colorScheme.primary.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  facts[index % facts.length],
                  key: ValueKey(index),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
