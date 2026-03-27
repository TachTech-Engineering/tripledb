import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'restaurant_providers.dart';

part 'trivia_providers.g.dart';

@riverpod
class TriviaFacts extends _$TriviaFacts {
  @override
  List<String> build() {
    final restaurantsAsync = ref.watch(restaurantListProvider);

    return restaurantsAsync.maybeWhen(
      data: (restaurants) {
        if (restaurants.isEmpty) return ['Guy is coming!'];

        // Compute facts
        final validStates = restaurants
            .map((r) => r.state)
            .where((s) => s.isNotEmpty && s != 'UNKNOWN')
            .toSet();
        final stateCount = validStates.length;
        
        final totalDishes = restaurants.expand((r) => r.dishes).length;

        // Most common cuisine
        final cuisineCounts = <String, int>{};
        for (final r in restaurants) {
          final types = r.cuisineType.split(', ');
          for (final type in types) {
            if (type.isEmpty) continue;
            cuisineCounts[type] = (cuisineCounts[type] ?? 0) + 1;
          }
        }
        final topCuisine = cuisineCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        // Most visited restaurant
        final sortedByVisits = List.from(restaurants)
          ..sort((a, b) => b.visits.length.compareTo(a.visits.length));
        final topRest = sortedByVisits.first;

        return [
          'Guy has visited ${restaurants.length} restaurants in our database!',
          'There are over $totalDishes unique dishes to explore.',
          'Triple D has covered $stateCount different states and territories.',
          '${topCuisine.first.key} is the most common cuisine type.',
          '${topRest.name} is the most-featured with ${topRest.visits.length} visits!',
        ];
      },
      orElse: () => ['Loading Flavortown facts...'],
    );
  }
}

@riverpod
class CurrentTriviaIndex extends _$CurrentTriviaIndex {
  Timer? _timer;

  @override
  int build() {
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      final facts = ref.read(triviaFactsProvider);
      state = (state + 1) % facts.length;
    });

    ref.onDispose(() => _timer?.cancel());
    return 0;
  }
}
