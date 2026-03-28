import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../providers/restaurant_providers.dart';
import '../providers/location_providers.dart';
import '../providers/cookie_provider.dart';
import '../models/restaurant_models.dart';

class MapPage extends ConsumerWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(restaurantListProvider);
    final userLocationAsync = ref.watch(userLocationProvider);
    final showClosed = ref.watch(showClosedProvider);
    final theme = Theme.of(context);

    final mapController = MapController();

    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'toggle_closed',
            onPressed: () {
              final newValue = !ref.read(showClosedProvider);
              ref.read(showClosedProvider.notifier).toggle();
              ref.read(analyticsServiceProvider).logFilterToggle('show_closed', newValue);
            },
            tooltip: showClosed ? 'Hide closed' : 'Show closed',
            child: Icon(showClosed ? Icons.visibility : Icons.visibility_off),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'near_me',
            onPressed: () {
              ref.read(userLocationProvider.notifier).refresh();
              final pos = ref.read(userLocationProvider).value;
              if (pos != null) {
                mapController.move(LatLng(pos.latitude, pos.longitude), 12.0);
              }
            },
            label: const Text('Near Me'),
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: restaurantsAsync.when(
        data: (restaurants) {
          final markers = restaurants
              .where((r) => r.latitude != null && r.longitude != null)
              .where((r) => showClosed || (r.stillOpen != false))
              .map(
                (r) => Marker(
                  point: LatLng(r.latitude!, r.longitude!),
                  width: 40,
                  height: 40,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: () => _showRestaurantPreview(context, r),
                    child: Icon(
                      Icons.location_on,
                      color: r.stillOpen == false
                          ? Colors.grey // Grey for closed
                          : theme.colorScheme.primary, // Red/Primary for open
                      size: 40,
                    ),
                  ),
                ),
              )
              .toList();

          return FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: userLocationAsync.maybeWhen(
                data: (pos) => pos != null
                    ? LatLng(pos.latitude, pos.longitude)
                    : const LatLng(
                        39.8283,
                        -98.5795,
                      ), // Geographic center of US
                orElse: () => const LatLng(39.8283, -98.5795),
              ),
              initialZoom: 4.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.tripledb.app',
              ),
              MarkerClusterLayerWidget(
                options: MarkerClusterLayerOptions(
                  maxClusterRadius: 80,
                  size: const Size(40, 40),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(50),
                  markers: markers,
                  builder: (context, clusterMarkers) {
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondary, // Orange #DA7E12
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${clusterMarkers.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading map: $err')),
      ),
    );
  }

  void _showRestaurantPreview(BuildContext context, Restaurant restaurant) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      elevation: 4, // elevation.lg
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              restaurant.name,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text('${restaurant.city}, ${restaurant.state}'),
            const SizedBox(height: 8),
            Text(
              restaurant.cuisineType,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    context.pop();
                    context.push('/restaurant/${restaurant.id}');
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
