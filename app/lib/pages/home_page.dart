import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/search/search_bar_widget.dart';
import '../widgets/trivia/trivia_card.dart';
import '../widgets/restaurant/restaurant_card.dart';
import '../providers/location_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nearbyAsync = ref.watch(nearbyRestaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TripleDB'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () => context.push('/map'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Text('🍔 TripleDB', style: theme.textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(
                'Every diner from Diners, Drive-Ins & Dives',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 40),
              const SearchBarWidget(),
              const SizedBox(height: 60),
              const TriviaCard(),
              const SizedBox(height: 40),

              // Nearby Section
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                      child: Text(
                        '📍 Top 3 Near You',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    nearbyAsync.when(
                      data: (restaurants) {
                        if (restaurants.isEmpty) {
                          return const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Text(
                                'Enable location to find diners near you!',
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: restaurants
                              .map((r) => RestaurantCard(restaurant: r))
                              .toList(),
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) =>
                          const Text('Unable to load nearby diners.'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () => context.push('/map'),
                icon: const Icon(Icons.map),
                label: const Text('View All on Map'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
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
