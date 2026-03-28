import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/search/search_bar_widget.dart';
import '../widgets/trivia/trivia_card.dart';
import '../widgets/restaurant/restaurant_card.dart';
import '../widgets/cookie_consent_banner.dart';
import '../providers/location_providers.dart';
import '../providers/cookie_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final nearbyAsync = ref.watch(nearbyRestaurantsProvider);
    final userLocationAsync = ref.watch(userLocationProvider);
    final nearbyCount = ref.watch(nearbyCountProvider);

    return SingleChildScrollView(
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
                      '📍 Nearby Restaurants',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  userLocationAsync.when(
                    data: (pos) {
                      if (pos == null) {
                        return Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enable location to find diners near you!',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: () {
                                    ref.read(userLocationProvider.notifier).refresh();
                                  },
                                  child: const Text('Enable Location'),
                                )
                              ],
                            ),
                          ),
                        );
                      }

                      // Location is enabled, show nearby restaurants
                      return nearbyAsync.when(
                        data: (nearbyList) {
                          if (nearbyList.isEmpty) {
                            return Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No nearby diners found. The database might not have coordinates yet!',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                            );
                          }
                          return Column(
                            children: [
                              ...nearbyList.map((nr) => RestaurantCard(
                                restaurant: nr.restaurant,
                                distanceLabel: nr.formattedDistance,
                              )),
                              if (nearbyCount <= 15)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: TextButton(
                                    onPressed: () {
                                      ref.read(nearbyCountProvider.notifier).showMore();
                                    },
                                    child: const Text('Show all nearby'),
                                  ),
                                ),
                            ],
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => Text('Error: $err'),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Could not get location. Ensure your browser allows it.\nError: $err',
                              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(userLocationProvider.notifier).refresh();
                              },
                              child: const Text('Try Again'),
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
            TextButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CookieSettingsModal(
                    cookieService: ref.read(cookieServiceProvider),
                    onSaved: (prefs) {
                      ref.read(hasConsentedProvider.notifier).set(true);
                    },
                  ),
                );
              },
              child: const Text('Manage Cookies'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
