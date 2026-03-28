import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'firebase_options.dart';
import 'providers/router_provider.dart';
import 'theme/app_theme.dart';

part 'main.g.dart';

@riverpod
class ThemeModeSetting extends _$ThemeModeSetting {
  @override
  ThemeMode build() => ThemeMode.light;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Cookie and analytics providers are lazy — resolved when first watched
  // in the widget tree (MainPage). Do NOT access providers here.
  runApp(
    const ProviderScope(
      child: TripleDBApp(),
    ),
  );
}

class TripleDBApp extends ConsumerWidget {
  const TripleDBApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeSettingProvider);

    return MaterialApp.router(
      title: 'TripleDB',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
