import 'dart:async';
import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/restaurant_models.dart';
import 'restaurant_providers.dart';

part 'trivia_providers.g.dart';

const curatedFacts = [
  "Guy Fieri's birth name is Guy Ramsay Ferry — he changed it to his grandfather's Italian surname",
  'Diners, Drive-Ins and Dives premiered on April 23, 2006',
  'The show is often nicknamed "Triple D" by fans',
  "Guy's iconic yellow Camaro is a 1968 Chevrolet Camaro SS convertible",
  'Guy Fieri has hosted over 400 episodes of Triple D',
  'The show films about 3 restaurants per episode',
  "Guy's catchphrase \"Winner, winner, chicken dinner!\" became a pop culture staple",
  'DDD restaurants span from Alaska to Puerto Rico',
  'The show has filmed in all 50 US states',
  'Guy Fieri raised over \$25 million for restaurant workers during the pandemic',
  "Before TV, Guy owned two restaurants in California: Johnny Garlic's and Tex Wasabi's",
  'Guy won Season 2 of "The Next Food Network Star" in 2006',
  'Triple D inspired thousands of food road trips across America',
  "Guy's signature look — frosted tips, backwards sunglasses, and flame shirts — is instantly recognizable",
  'Many DDD restaurants report a 300%+ sales increase after their episode airs',
];

List<String> generateDynamicFacts(List<Restaurant> restaurants) {
  final facts = <String>[];
  if (restaurants.isEmpty) return facts;

  final open = restaurants.where((r) => r.stillOpen != false).toList();
  final closed = restaurants.where((r) => r.stillOpen == false).toList();
  final enriched = restaurants.where((r) => r.googleRating != null).toList();
  final renamed = restaurants.where((r) => r.nameChanged).toList();

  // --- Dataset scope ---
  facts.add('Guy Fieri has visited ${restaurants.length} restaurants across America on Triple D!');
  final totalDishes = restaurants.fold(0, (sum, r) => sum + r.dishes.length);
  facts.add('The Triple D database has $totalDishes dishes — and counting!');
  final totalVisits = restaurants.fold(0, (sum, r) => sum + r.visits.length);
  facts.add('There have been $totalVisits restaurant segments across all DDD episodes');

  // --- State facts ---
  final byState = <String, List<Restaurant>>{};
  for (final r in restaurants) {
    if (r.state.isNotEmpty && r.state != 'UNKNOWN') {
      byState.putIfAbsent(r.state, () => []).add(r);
    }
  }
  final sortedStates = byState.entries.toList()
    ..sort((a, b) => b.value.length.compareTo(a.value.length));

  if (sortedStates.isNotEmpty) {
    facts.add('${sortedStates[0].key} leads the pack with ${sortedStates[0].value.length} DDD restaurants!');
  }
  if (sortedStates.length > 1) {
    facts.add('${sortedStates[1].key} comes in second with ${sortedStates[1].value.length} DDD spots');
  }
  if (sortedStates.length > 2) {
    facts.add('${sortedStates[2].key} takes third place with ${sortedStates[2].value.length} restaurants');
  }
  if (sortedStates.length > 3) {
    final smallestState = sortedStates.last;
    facts.add("${smallestState.key} has just ${smallestState.value.length} DDD restaurant — but it's a good one!");
  }
  // Mid-tier states
  for (int i = 5; i < sortedStates.length && i < 12; i++) {
    facts.add('${sortedStates[i].key} has ${sortedStates[i].value.length} restaurants featured on Triple D');
  }

  // --- Unique cities ---
  final uniqueCities = restaurants.map((r) => '${r.city}, ${r.state}').toSet();
  facts.add('DDD restaurants are spread across ${uniqueCities.length} different cities!');

  // --- Restaurant superlatives ---
  final byVisits = [...restaurants]..sort((a, b) => b.visits.length.compareTo(a.visits.length));
  if (byVisits.isNotEmpty) {
    facts.add('${byVisits[0].name} holds the record with ${byVisits[0].visits.length} DDD appearances!');
  }
  if (byVisits.length > 1) {
    facts.add('${byVisits[1].name} has been featured ${byVisits[1].visits.length} times on the show');
  }
  if (byVisits.length > 2) {
    facts.add('${byVisits[2].name} is a Triple D favorite with ${byVisits[2].visits.length} visits');
  }

  // --- Dish facts ---
  final dishCategoryCounts = <String, int>{};
  for (final r in restaurants) {
    for (final d in r.dishes) {
      if (d.dishCategory != null && d.dishCategory!.isNotEmpty) {
        dishCategoryCounts[d.dishCategory!] = (dishCategoryCounts[d.dishCategory!] ?? 0) + 1;
      }
    }
  }
  final topDishCategories = dishCategoryCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (topDishCategories.isNotEmpty) {
    facts.add('${topDishCategories[0].key} is the most common dish category on Triple D (${topDishCategories[0].value} dishes)');
  }
  if (topDishCategories.length > 1) {
    facts.add('${topDishCategories[1].key} is the #2 dish category with ${topDishCategories[1].value} dishes across the show');
  }

  // Ingredient facts
  final ingredientCounts = <String, int>{};
  for (final r in restaurants) {
    for (final d in r.dishes) {
      for (final ing in d.ingredients) {
        final normalized = ing.toLowerCase().trim();
        if (normalized.isNotEmpty) {
          ingredientCounts[normalized] = (ingredientCounts[normalized] ?? 0) + 1;
        }
      }
    }
  }
  final topIngredients = ingredientCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (topIngredients.isNotEmpty) {
    facts.add('The most common ingredient on DDD is ${topIngredients[0].key} — appearing in ${topIngredients[0].value} dishes!');
  }
  if (topIngredients.length > 1) {
    facts.add('${topIngredients[1].key} is the #2 most popular ingredient on the show');
  }
  if (topIngredients.length > 2) {
    facts.add('${topIngredients[2].key} rounds out the top 3 DDD ingredients');
  }

  // --- Rating facts (from enrichment) ---
  if (enriched.isNotEmpty) {
    final avgRating = enriched.fold(0.0, (sum, r) => sum + r.googleRating!) / enriched.length;
    facts.add('The average Google rating for a DDD restaurant is ${avgRating.toStringAsFixed(1)} stars');

    final topRated = [...enriched]..sort((a, b) => b.googleRating!.compareTo(a.googleRating!));
    if (topRated.isNotEmpty) {
      facts.add('${topRated[0].name} has a stellar ${topRated[0].googleRating} rating on Google!');
    }
    if (topRated.length > 1) {
      facts.add('${topRated[1].name} is rated ${topRated[1].googleRating} stars — Guy knows quality!');
    }

    final mostReviewed = [...enriched]
      ..sort((a, b) => (b.googleRatingCount ?? 0).compareTo(a.googleRatingCount ?? 0));
    if (mostReviewed.isNotEmpty && mostReviewed[0].googleRatingCount != null) {
      facts.add('${mostReviewed[0].name} has ${mostReviewed[0].googleRatingCount} Google reviews!');
    }

    final highRated = enriched.where((r) => r.googleRating! >= 4.5).length;
    facts.add('$highRated DDD restaurants have a Google rating of 4.5 or higher!');

    facts.add('${enriched.length} DDD restaurants have been verified with Google Places data');
  }

  // --- Closed/renamed ---
  if (closed.isNotEmpty) {
    facts.add('${closed.length} DDD restaurants have permanently closed since filming');
    facts.add('${open.length} out of ${restaurants.length} DDD restaurants are still open today!');
    final closedPct = (closed.length / restaurants.length * 100).toStringAsFixed(0);
    facts.add('About $closedPct% of DDD restaurants have closed — the restaurant business is tough!');
  }
  if (renamed.isNotEmpty) {
    facts.add('${renamed.length} DDD restaurants have been renamed since their episode aired');
    final exampleRename = renamed.firstWhere(
      (r) => r.googleCurrentName != null && r.name != r.googleCurrentName,
      orElse: () => renamed.first,
    );
    if (exampleRename.googleCurrentName != null && exampleRename.name != exampleRename.googleCurrentName) {
      facts.add('"${exampleRename.name}" is now known as "${exampleRename.googleCurrentName}"');
    }
  }

  // --- Cuisine facts ---
  final cuisineCounts = <String, int>{};
  for (final r in restaurants) {
    if (r.cuisineType.isNotEmpty && r.cuisineType != 'Unknown') {
      for (final c in r.cuisineType.split(',').map((s) => s.trim())) {
        if (c.isNotEmpty) {
          cuisineCounts[c] = (cuisineCounts[c] ?? 0) + 1;
        }
      }
    }
  }
  final topCuisines = cuisineCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (topCuisines.isNotEmpty) {
    facts.add('${topCuisines[0].key} is the most common cuisine on Triple D (${topCuisines[0].value} restaurants)');
  }
  if (topCuisines.length > 1) {
    facts.add('${topCuisines[1].key} comes in at #2 with ${topCuisines[1].value} DDD spots');
  }
  if (topCuisines.length > 2) {
    facts.add('${topCuisines[2].key} rounds out the top 3 cuisines on the show');
  }
  if (topCuisines.length > 4) {
    facts.add('The top 5 cuisines on DDD are: ${topCuisines.take(5).map((e) => e.key).join(", ")}');
  }

  // --- State with most closed ---
  if (closed.isNotEmpty) {
    final closedByState = <String, int>{};
    for (final r in closed) {
      if (r.state.isNotEmpty && r.state != 'UNKNOWN') {
        closedByState[r.state] = (closedByState[r.state] ?? 0) + 1;
      }
    }
    final topClosedState = closedByState.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (topClosedState.isNotEmpty) {
      facts.add('${topClosedState[0].key} has the most closed DDD restaurants (${topClosedState[0].value})');
    }
  }

  // --- Multi-visit restaurants ---
  final multiVisit = restaurants.where((r) => r.visits.length >= 2).length;
  facts.add('$multiVisit restaurants have been featured on DDD more than once!');

  return facts;
}

class TriviaState {
  final List<String> facts;
  final int currentIndex;

  TriviaState({required this.facts, this.currentIndex = 0});

  String get currentFact => facts.isEmpty ? '' : facts[currentIndex];
  int get totalFacts => facts.length;
  int get factNumber => currentIndex + 1;

  TriviaState copyWith({List<String>? facts, int? currentIndex}) {
    return TriviaState(
      facts: facts ?? this.facts,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }
}

@riverpod
class TriviaFacts extends _$TriviaFacts {
  Timer? _timer;

  @override
  TriviaState build() {
    final restaurantsAsync = ref.watch(restaurantListProvider);

    final restaurants = restaurantsAsync.maybeWhen(
      data: (data) => data,
      orElse: () => <Restaurant>[],
    );

    final dynamicFacts = generateDynamicFacts(restaurants);
    final allFacts = [...dynamicFacts, ...curatedFacts];
    if (allFacts.isEmpty) {
      allFacts.add('Loading Flavortown facts...');
    }
    allFacts.shuffle(Random());

    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => advance());

    return TriviaState(facts: allFacts, currentIndex: 0);
  }

  void advance() {
    final next = (state.currentIndex + 1) % state.facts.length;
    if (next == 0) {
      // Exhausted all facts — reshuffle for next cycle
      state = TriviaState(
        facts: [...state.facts]..shuffle(Random()),
        currentIndex: 0,
      );
    } else {
      state = state.copyWith(currentIndex: next);
    }
  }
}
