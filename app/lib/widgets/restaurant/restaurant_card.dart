import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/restaurant_models.dart';

class RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantCard({super.key, required this.restaurant});

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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final emoji = _getEmojiForCuisine(restaurant.cuisineType);
    final firstVisit = restaurant.visits.isNotEmpty ? restaurant.visits.first : null;
    final videoType = firstVisit?.videoType ?? 'Appearance';
    final visitCount = restaurant.visits.length;
    final badgeText = '$videoType • $visitCount visit${visitCount == 1 ? '' : 's'}';

    return Card(
      elevation: 2, // elevation.md
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // borderRadius.lg
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/restaurant/${restaurant.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0), // padding.md
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${restaurant.city}, ${restaurant.state} • ${restaurant.cuisineType}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Episode Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: theme.colorScheme.secondary),
                      ),
                      child: Text(
                        badgeText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
