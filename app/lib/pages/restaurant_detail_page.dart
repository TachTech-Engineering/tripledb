import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/restaurant_providers.dart';
import '../widgets/restaurant/dish_card.dart';
import '../widgets/restaurant/visit_card.dart';

class RestaurantDetailPage extends ConsumerWidget {
  final String id;

  const RestaurantDetailPage({super.key, required this.id});

  String _getEmojiForCuisine(String cuisine) {
    final c = cuisine.toLowerCase();
    if (c.contains('pizza') || c.contains('italian')) return '🍕';
    if (c.contains('burger') || c.contains('american')) return '🍔';
    if (c.contains('mexican') || c.contains('tex-mex')) return '🌮';
    if (c.contains('bbq') || c.contains('barbecue')) return '🍖';
    if (c.contains('sushi') || c.contains('japanese')) return '🍣';
    if (c.contains('noodle') || c.contains('asian')) return '🍜';
    if (c.contains('soul') || c.contains('southern')) return '🥘';
    return '🍽️';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Restaurant Detail')),
      body: restaurantsAsync.when(
        data: (restaurants) {
          final restaurant = restaurants.firstWhere(
            (r) => r.id == id,
            orElse: () => throw Exception('Restaurant not found'),
          );

          final emoji = _getEmojiForCuisine(restaurant.cuisineType);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Placeholder
                Container(
                  width: double.infinity,
                  color: theme.colorScheme.primary.withValues(alpha: 0.8),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
                  child: Column(
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        restaurant.name,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${restaurant.city}, ${restaurant.state} · ${restaurant.cuisineType}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      if (restaurant.ownerChef != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Chef: ${restaurant.ownerChef}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Action Bar
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: theme.colorScheme.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: implement directions using url_launcher
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: theme.colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: implement website using url_launcher
                        },
                        icon: const Icon(Icons.public),
                        label: const Text('Website'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          side: BorderSide(color: theme.colorScheme.secondary),
                          foregroundColor: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(24.0), // spacing.lg
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dishes',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16), // spacing.md
                      ...restaurant.dishes.map((dish) => DishCard(dish: dish)),
                      
                      const SizedBox(height: 32), // spacing.xl
                      
                      Text(
                        'DDD Appearances',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16), // spacing.md
                      ...restaurant.visits.map(
                        (visit) => VisitCard(visit: visit),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
