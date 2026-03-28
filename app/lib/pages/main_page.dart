import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../main.dart';
import '../providers/cookie_provider.dart';
import '../widgets/cookie_consent_banner.dart';
import 'home_page.dart';
import 'map_page.dart';
import 'explore_page.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  int _currentIndex = 1;

  final List<Widget> _pages = const [
    MapPage(),
    HomePage(),
    ExplorePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize analytics with current cookie consent state
      final cookieService = ref.read(cookieServiceProvider);
      ref.read(analyticsServiceProvider).initialize(
        analyticsConsent: cookieService.hasConsent('analytics'),
      );
      ref.read(analyticsServiceProvider).logPageView('List');
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeSettingProvider);
    final isDark = themeMode == ThemeMode.dark;
    final hasConsented = ref.watch(hasConsentedProvider);
    final cookieService = ref.watch(cookieServiceProvider);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Row(
              children: [
                Text('🍔', style: TextStyle(fontSize: 24)),
                SizedBox(width: 8),
                Text('TripleDB'),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  ref.read(themeModeSettingProvider.notifier).toggle();
                },
              ),
            ],
          ),
          body: IndexedStack(
            index: _currentIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);
              // Log page view when tab changes
              final pageNames = ['Map', 'List', 'Explore'];
              ref.read(analyticsServiceProvider).logPageView(pageNames[index]);
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: 'List'),
              BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
            ],
          ),
        ),
        if (!hasConsented)
          CookieConsentBanner(
            cookieService: cookieService,
            onAction: () {
              ref.read(hasConsentedProvider.notifier).set(true);
            },
          ),
      ],
    );
  }
}
