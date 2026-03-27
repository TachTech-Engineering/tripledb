import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/restaurant_providers.dart';
import '../widgets/trivia/trivia_card.dart';
import '../widgets/restaurant/restaurant_card.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantListProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Explore Flavortown', style: theme.textTheme.displayMedium),
            const SizedBox(height: 24),
            const TriviaCard(),
            const SizedBox(height: 40),
            restaurantsAsync.when(
              data: (restaurants) {
                if (restaurants.isEmpty) return const SizedBox.shrink();

                // Top States
                final stateCounts = <String, int>{};
                for (final r in restaurants) {
                  if (r.state == 'UNKNOWN' || r.state.isEmpty) continue;
                  stateCounts[r.state] = (stateCounts[r.state] ?? 0) + 1;
                }
                final sortedStates = stateCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                // Cuisine Breakdown
                final cuisineCounts = <String, int>{};
                for (final r in restaurants) {
                  final types = r.cuisineType.split(', ');
                  for (final type in types) {
                    if (type.isEmpty || type == 'Unknown') continue;
                    cuisineCounts[type] = (cuisineCounts[type] ?? 0) + 1;
                  }
                }
                final sortedCuisines = cuisineCounts.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                // Most Visited (3+ appearances)
                final mostVisited = restaurants.where((r) => r.visits.length >= 3).toList()
                  ..sort((a, b) => b.visits.length.compareTo(a.visits.length));

                // Enrichment Stats
                final ratedRestaurants = restaurants.where((r) => r.googleRating != null).toList();
                final closedRestaurants = restaurants.where((r) => r.stillOpen == false).toList();
                final avgRating = ratedRestaurants.isEmpty
                    ? 0.0
                    : ratedRestaurants.map((r) => r.googleRating!).reduce((a, b) => a + b) / ratedRestaurants.length;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Top States', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sortedStates.take(10).map((e) {
                        return Chip(
                          label: Text('${e.key} (${e.value})'),
                          backgroundColor: theme.colorScheme.secondary.withValues(alpha: 0.1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                    Text('Enrichment Stats', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatItem(theme, ratedRestaurants.length.toString(), 'Rated on Google'),
                              _buildStatItem(theme, closedRestaurants.length.toString(), 'Permanently Closed'),
                              _buildStatItem(theme, avgRating.toStringAsFixed(1), 'Avg Rating'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text('Most Visited Diners', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Column(
                      children: mostVisited.take(5).map((r) {
                        return RestaurantCard(restaurant: r);
                      }).toList(),
                    ),
                    const SizedBox(height: 40),
                    Text('Cuisine Breakdown', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: sortedCuisines.take(15).map((e) {
                        return Chip(
                          label: Text('${e.key} (${e.value})'),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
