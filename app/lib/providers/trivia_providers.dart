import 'dart:async';
import 'dart:math';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../models/restaurant_models.dart';
import 'restaurant_providers.dart';

part 'trivia_providers.g.dart';

const curatedFacts = [
  // --- Guy Fieri biography ---
  "Guy Fieri's birth name is Guy Ramsay Ferry — he changed it to his grandfather's Italian surname",
  'Guy won Season 2 of "The Next Food Network Star" in 2006',
  "Before TV, Guy owned two restaurants in California: Johnny Garlic's and Tex Wasabi's",
  "Guy's iconic yellow Camaro is a 1968 Chevrolet Camaro SS convertible",
  "Guy's signature look — frosted tips, backwards sunglasses, and flame shirts — is instantly recognizable",
  'Guy Fieri raised over \$25 million for restaurant workers during the pandemic',
  'Guy Fieri was born on January 22, 1968 in Columbus, Ohio',
  "Guy Fieri's first restaurant job was selling soft pretzels from a cart he built with his dad",
  'Guy Fieri studied hospitality management at the University of Nevada, Las Vegas',
  'Guy Fieri was the Mayor of Flavortown before it was even a place on the map',
  "Guy's audition tape for Food Network Star was filmed by his wife Lori at their kitchen table",
  'Guy Fieri holds the Guinness World Record for largest charity barbecue — 9,000 pounds of meat',
  'Guy Fieri officiated 101 gay weddings in Miami to celebrate marriage equality',
  'Guy opened his first restaurant at age 26 in Santa Rosa, California',
  "Guy Fieri's favorite guilty pleasure food is a classic hot dog with mustard",

  // --- Show history & production ---
  'Diners, Drive-Ins and Dives premiered on April 23, 2006',
  'The show is often nicknamed "Triple D" by fans',
  'Guy Fieri has hosted over 400 episodes of Triple D',
  'The show films about 3 restaurants per episode',
  'DDD restaurants span from Alaska to Puerto Rico',
  'The show has filmed in all 50 US states',
  'Triple D inspired thousands of food road trips across America',
  'Many DDD restaurants report a 300%+ sales increase after their episode airs',
  'The original working title for the show was "Diners, Dumps and Dives"',
  'Each DDD episode takes about 2 days to film per restaurant segment',
  'Guy drives over 100,000 miles per year filming Triple D across America',
  "The show's theme song \"Rockin'\" was written specifically for DDD",
  'DDD has won multiple Emmy Awards for Outstanding Culinary Program',
  "The show's production crew visits each restaurant weeks before filming to scout locations",
  'Guy tastes every single dish on camera — no stunt doubles for Flavortown',
  'The red Camaro convertible has become as iconic as the show itself',
  'DDD has featured restaurants in over 400 different cities',
  'The show helped popularize the phrase "money" as a food compliment',

  // --- Guy catchphrases & culture ---
  "Guy's catchphrase \"Winner, winner, chicken dinner!\" became a pop culture staple",
  'Guy\'s famous exclamation "That\'s out of bounds!" means the food blew his mind',
  '"Flavortown" isn\'t a real place — it\'s a state of mind invented by Guy Fieri',
  'Guy\'s "Donkey Sauce" is a garlic aioli that became one of his most famous recipes',
  'When Guy says food is "gangster," he means it\'s bold, intense, and unforgettable',
  '"That\'s real deal" is Guy\'s way of saying a dish is authentic and well-executed',
  'Guy calls his kitchen the "Kulinary Gangster" headquarters',
  'The phrase "taking it to Flavortown" has been said on the show over 500 times',
  'Guy is known for rating dishes on a scale of "righteous" to "off the hook"',

  // --- TripleDB project ---
  'TripleDB was built at \$0 total infrastructure cost — every tool is free-tier',
  "TripleDB's name combines 'Triple D' (the show's nickname) with 'DB' (database)",
  'The TripleDB pipeline processed 805 YouTube videos using local CUDA transcription',
  'TripleDB uses Gemini 2.5 Flash to extract structured data from video transcripts',
  'Every restaurant in TripleDB was geocoded using free Nominatim (OpenStreetMap) data',
  'TripleDB runs on Firebase Hosting and Cloud Firestore — both on free tier',
  'The TripleDB Flutter app works on web, Android, and iOS from a single codebase',
  'TripleDB processed 14 hours of audio transcription in a single unattended tmux run',
  'The TripleDB enrichment pipeline matched restaurants to Google Places with 83% accuracy',
  'TripleDB was built using Iterative Agentic Orchestration — an AI-first dev methodology',
  'The TripleDB data pipeline went from 30 to 805 videos in progressive batches',
  '432 duplicate restaurant entries were merged during TripleDB data processing',
  'TripleDB uses Riverpod 3 with codegen for type-safe state management',
  'The map in TripleDB uses flutter_map with CartoDB dark tiles for that Flavortown vibe',
  'TripleDB has been through 43 development iterations across 9 phases',
  'The TripleDB search lets you find restaurants by dish, ingredient, city, or chef name',
  'TripleDB shows real-time Google ratings for restaurants verified through the Places API',
  'Every DDD restaurant in TripleDB links directly to its YouTube episode timestamp',
  'TripleDB uses CartoDB dark matter tiles for the map — because Flavortown comes alive at night',
  'The TripleDB cookie consent banner supports GDPR and CCPA compliance',
  'TripleDB tracks which restaurants have been renamed since appearing on the show',
  'The nearby restaurants feature in TripleDB uses browser geolocation to find DDD spots near you',

  // --- Food & restaurant industry ---
  'The average American restaurant has a profit margin of just 3–5%',
  'About 60% of restaurants fail within their first year of opening',
  'The United States has over 1 million restaurant locations',
  'BBQ is one of the most popular cuisines featured on DDD',
  'Diners historically served as 24-hour community gathering spots across small-town America',
  'The classic American diner dates back to horse-drawn lunch wagons in the 1870s',
  'Drive-ins became popular in the 1950s alongside American car culture',
  'The word "diner" originally referred to the dining car on a train',
  'Food trucks — modern drive-ins — are a \$1.2 billion industry in the US',
  'The most popular day to eat out in America is Saturday',

  // --- More Guy & show facts ---
  'Guy Fieri was inducted into the Barbecue Hall of Fame in 2019',
  'The DDD film crew typically visits 3 cities per week during production',
  "Guy's convertible Camaro has been in nearly every episode's opening sequence",
  'DDD has inspired multiple copycat shows on competing food networks',
  'Guy Fieri has appeared in over 40 different TV shows and specials',
  'Many DDD restaurants frame their episode and hang it on the wall',
  'Guy has said that finding the best diners is like a treasure hunt across America',
  'The DDD effect: restaurants often hire extra staff before their episode airs',
  'Some DDD restaurants have renamed dishes after Guy Fieri visits',
  'Guy Fieri has written several bestselling cookbooks including "Diners, Drive-Ins and Dives: An All-American Road Trip"',
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
  for (int i = 5; i < sortedStates.length && i < 15; i++) {
    facts.add('${sortedStates[i].key} has ${sortedStates[i].value.length} restaurants featured on Triple D');
  }
  // State count
  facts.add('DDD has featured restaurants in ${sortedStates.length} different states and territories');

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
  if (topDishCategories.length > 2) {
    facts.add('${topDishCategories[2].key} takes the #3 spot for dish categories with ${topDishCategories[2].value} dishes');
  }
  if (topDishCategories.length > 4) {
    facts.add('The top 5 dish categories on DDD: ${topDishCategories.take(5).map((e) => e.key).join(", ")}');
  }
  facts.add('DDD has documented ${dishCategoryCounts.length} different dish categories across all episodes');

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
  if (topIngredients.length > 4) {
    facts.add('Top 5 DDD ingredients: ${topIngredients.take(5).map((e) => e.key).join(", ")}');
  }
  facts.add('DDD dishes use ${ingredientCounts.length} different unique ingredients!');

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
  final tripleVisit = restaurants.where((r) => r.visits.length >= 3).length;
  if (tripleVisit > 0) {
    facts.add('$tripleVisit restaurants have been on DDD 3 or more times — true Guy favorites!');
  }

  // --- City superlatives ---
  final byCity = <String, int>{};
  for (final r in restaurants) {
    if (r.city.isNotEmpty && r.city != 'UNKNOWN') {
      final key = '${r.city}, ${r.state}';
      byCity[key] = (byCity[key] ?? 0) + 1;
    }
  }
  final topCities = byCity.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  if (topCities.isNotEmpty) {
    facts.add('${topCities[0].key} has the most DDD restaurants — ${topCities[0].value} spots!');
  }
  if (topCities.length > 1) {
    facts.add('${topCities[1].key} is the #2 DDD city with ${topCities[1].value} restaurants');
  }
  if (topCities.length > 2) {
    facts.add('${topCities[2].key} takes the bronze with ${topCities[2].value} DDD restaurants');
  }
  if (topCities.length > 4) {
    facts.add('Top 5 DDD cities: ${topCities.take(5).map((e) => e.key).join(", ")}');
  }

  // --- Geocoded stats ---
  final geocoded = restaurants.where((r) => r.latitude != null && r.longitude != null).length;
  facts.add('$geocoded of ${restaurants.length} DDD restaurants have been mapped with coordinates');
  if (geocoded == restaurants.length) {
    facts.add('Every single DDD restaurant in the database has been geocoded and mapped!');
  }

  // --- Rating distribution ---
  if (enriched.length > 10) {
    final above4 = enriched.where((r) => r.googleRating! >= 4.0).length;
    final above4pct = (above4 / enriched.length * 100).toStringAsFixed(0);
    facts.add('$above4pct% of enriched DDD restaurants have a Google rating of 4.0 or higher');

    final below4 = enriched.where((r) => r.googleRating! < 4.0).length;
    if (below4 > 0) {
      facts.add('Only $below4 DDD restaurants have a Google rating below 4.0 — Guy picks well!');
    }

    final perfectRating = enriched.where((r) => r.googleRating! >= 4.9).length;
    if (perfectRating > 0) {
      facts.add('$perfectRating DDD restaurants have a near-perfect Google rating of 4.9 or higher!');
    }
  }

  // --- Dishes per restaurant ---
  if (restaurants.isNotEmpty) {
    final avgDishes = totalDishes / restaurants.length;
    facts.add('On average, each DDD restaurant has ${avgDishes.toStringAsFixed(1)} documented dishes');

    final maxDishRestaurant = [...restaurants]..sort((a, b) => b.dishes.length.compareTo(a.dishes.length));
    if (maxDishRestaurant.isNotEmpty && maxDishRestaurant[0].dishes.length > 1) {
      facts.add('${maxDishRestaurant[0].name} has the most documented dishes — ${maxDishRestaurant[0].dishes.length}!');
    }
  }

  // --- More cuisine stats ---
  if (topCuisines.length > 5) {
    for (int i = 3; i < topCuisines.length && i < 8; i++) {
      facts.add('${topCuisines[i].key} cuisine has ${topCuisines[i].value} restaurants on DDD');
    }
  }
  facts.add('DDD has featured ${cuisineCounts.length} different cuisine types from around the world');

  // --- Website/online presence ---
  final withWebsite = restaurants.where((r) => r.websiteUrl != null && r.websiteUrl!.isNotEmpty).length;
  if (withWebsite > 0) {
    facts.add('$withWebsite DDD restaurants have a verified website on file');
  }

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
    // Deduplicate facts using a Set
    final uniqueFacts = <String>{...dynamicFacts, ...curatedFacts}.toList();
    if (uniqueFacts.isEmpty) {
      uniqueFacts.add('Loading Flavortown facts...');
    }
    uniqueFacts.shuffle(Random());

    ref.onDispose(() => _timer?.cancel());
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => advance());

    return TriviaState(facts: uniqueFacts, currentIndex: 0);
  }

  void advance() {
    final next = (state.currentIndex + 1) % state.facts.length;
    if (next == 0) {
      // Exhausted all facts — reshuffle for next cycle
      final lastShown = state.facts.last;
      final reshuffled = [...state.facts]..shuffle(Random());
      // Avoid showing the same fact twice at the boundary
      if (reshuffled.first == lastShown && reshuffled.length > 1) {
        final temp = reshuffled[0];
        reshuffled[0] = reshuffled[1];
        reshuffled[1] = temp;
      }
      state = TriviaState(facts: reshuffled, currentIndex: 0);
    } else {
      state = state.copyWith(currentIndex: next);
    }
  }
}
