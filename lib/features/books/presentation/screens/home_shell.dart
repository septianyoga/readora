import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../statistics/presentation/providers/statistics_providers.dart';
import '../../../statistics/presentation/screens/statistics_screen.dart';
import 'library_screen.dart';

/// Shell utama aplikasi dengan bottom navigation 3 tab:
/// Library, Statistics, Settings.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;
  static const _statisticsTabIndex = 1;

  static const _screens = [
    LibraryScreen(),
    StatisticsScreen(),
    SettingsScreen(),
  ];

  void _onDestinationSelected(int index) {
    setState(() => _currentIndex = index);
    // Statistics dipakai IndexedStack (screen-nya tetap "hidup" di
    // belakang layar saat pindah tab, bukan dibuang), jadi dia tidak
    // otomatis re-fetch data sendiri kalau cuma pindah-pindah tab.
    // Daripada mengandalkan tombol refresh manual, di-refresh otomatis
    // setiap kali tab ini ditekan — termasuk saat menekannya lagi ketika
    // sudah berada di tab ini, supaya angka reading time/pages terbaru
    // (misalnya baru saja selesai baca) langsung kelihatan.
    if (index == _statisticsTabIndex) {
      invalidateAllStatistics(ref);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.library_books_outlined),
            selectedIcon: Icon(Icons.library_books),
            label: 'Library',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}