import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../pages/main_page.dart';
import '../pages/search_results_page.dart';
import '../pages/restaurant_detail_page.dart';
import '../pages/map_page.dart';

part 'router_provider.g.dart';

@riverpod
GoRouter router(RouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const MainPage()),
      GoRoute(
        path: '/search',
        builder: (context, state) {
          final query = state.uri.queryParameters['q'] ?? '';
          return SearchResultsPage(query: query);
        },
      ),
      GoRoute(
        path: '/restaurant/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return RestaurantDetailPage(id: id);
        },
      ),
      GoRoute(path: '/map', builder: (context, state) => const MapPage()),
    ],
  );
}
