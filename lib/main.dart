import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/providers/settings_providers.dart';

void main() {
  runApp(const ProviderScope(child: BookReaderApp()));
}

class BookReaderApp extends ConsumerWidget {
  const BookReaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Baseline font size aplikasi adalah 16pt (lihat AppSettings.defaults),
    // jadi setting "Font size" diterapkan sebagai rasio scaling terhadap
    // baseline itu, bukan menimpa ukuran font Material secara langsung.
    final settings = ref.watch(settingsProvider).valueOrNull;
    final textScale = (settings?.fontSize ?? 16) / 16;

    return MaterialApp(
      title: 'BookReader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settings?.darkMode == true ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child!,
        );
      },
    );
  }
}