import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/restaurant_providers.dart';
import '../widgets/restaurant/restaurant_card.dart';

class SearchResultsPage extends ConsumerWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sync query with provider if it came from URL
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(searchQueryProvider) != query) {
        ref.read(searchQueryProvider.notifier).update(query);
      }
    });

    final results = ref.watch(filteredRestaurantsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Search: $query')),
      body: results.when(
        data: (restaurants) {
          if (restaurants.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Guy hasn\'t rolled out here yet!',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  '${restaurants.length} results found',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: restaurants.length,
                  itemBuilder: (context, index) {
                    return RestaurantCard(restaurant: restaurants[index]);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}
