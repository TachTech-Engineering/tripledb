import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/restaurant_providers.dart';
import '../providers/cookie_provider.dart';
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

    // Log view once per visit to this page
    SchedulerBinding.instance.addPostFrameCallback((_) {
      restaurantsAsync.whenData((restaurants) {
        final restaurant = restaurants.firstWhere((r) => r.id == id);
        ref.read(analyticsServiceProvider).logViewRestaurant(restaurant.id, restaurant.name);
      });
    });

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
                // Permanently closed banner
                if (restaurant.stillOpen == false)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFDD3333).withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFFDD3333), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'This restaurant has permanently closed',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFDD3333),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Temporarily closed banner
                if (restaurant.stillOpen == true && restaurant.businessStatus == 'CLOSED_TEMPORARILY')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFFDA7E12).withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        const Icon(Icons.schedule, color: Color(0xFFDA7E12), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Temporarily closed',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFDA7E12),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

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
                      if (restaurant.nameChanged && restaurant.googleCurrentName != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Now known as: ${restaurant.googleCurrentName}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white70,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${restaurant.formattedAddress ?? "${restaurant.city}, ${restaurant.state}"} · ${restaurant.cuisineType}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (restaurant.googleRating != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDA7E12), // DDD Orange
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, size: 16, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${restaurant.googleRating} (${restaurant.googleRatingCount ?? 0} reviews)',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (restaurant.stillOpen != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: restaurant.stillOpen! ? Colors.green : const Color(0xFFDD3333), // DDD Red
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                restaurant.stillOpen! ? 'Open' : 'Permanently Closed',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                      if (restaurant.googleMapsUrl != null)
                        ElevatedButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(restaurant.googleMapsUrl!);
                            ref.read(analyticsServiceProvider).logExternalLink('google_maps');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
                          },
                          icon: const Icon(Icons.map),
                          label: const Text('View on Maps'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.colorScheme.secondary,
                            foregroundColor: theme.colorScheme.onSecondary,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      if (restaurant.websiteUrl != null)
                        OutlinedButton.icon(
                          onPressed: () async {
                            final url = Uri.parse(restaurant.websiteUrl!);
                            ref.read(analyticsServiceProvider).logExternalLink('website');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url);
                            }
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
