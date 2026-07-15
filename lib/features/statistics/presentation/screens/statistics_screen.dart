import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/reading_statistics.dart';
import '../providers/statistics_providers.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  String _formatReadTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours == 0 && minutes == 0) return '0 menit';
    if (hours == 0) return '$minutes menit';
    if (minutes == 0) return '$hours jam';
    return '$hours jam $minutes menit';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(statisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(statisticsProvider),
          ),
        ],
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Terjadi kesalahan: $error')),
        data: (stats) => _StatisticsGrid(
          stats: stats,
          formatReadTime: _formatReadTime,
          onRefresh: () async => ref.invalidate(statisticsProvider),
        ),
      ),
    );
  }
}

/// Grid 2x2 statistik.
///
/// SEBELUMNYA pakai `GridView` dengan `childAspectRatio` (dihitung manual
/// dari text scale) — pendekatan itu rapuh, angkanya sulit pas untuk
/// semua kombinasi device + font size, dan `FittedBox` yang dipasang
/// sebagai "pengaman" ternyata tidak pernah aktif karena di dalam
/// `Column(mainAxisSize: min)` tanpa batas tinggi eksplisit, `FittedBox`
/// tidak punya box untuk di-"fit"-kan.
///
/// SEKARANG: setiap baris dibungkus `IntrinsicHeight`, jadi tinggi baris
/// otomatis mengikuti card tertinggi di baris itu — card TIDAK PERNAH
/// dipaksa ke tinggi tertentu, jadi tidak mungkin overflow di ukuran
/// font berapa pun. Seluruh grid dibungkus `SingleChildScrollView` supaya
/// kalau suatu saat kontennya lebih tinggi dari layar (misal font sangat
/// besar di layar kecil), dia scroll — bukan overflow.
class _StatisticsGrid extends StatelessWidget {
  final ReadingStatistics stats;
  final String Function(int) formatReadTime;
  final Future<void> Function() onRefresh;

  const _StatisticsGrid({
    required this.stats,
    required this.formatReadTime,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCard(
        icon: Icons.library_books_outlined,
        label: 'Total books',
        value: '${stats.totalBooks}',
      ),
      _StatCard(
        icon: Icons.auto_stories_outlined,
        label: 'Pages read',
        value: '${stats.pagesRead}',
      ),
      _StatCard(
        icon: Icons.schedule_outlined,
        label: 'Reading time',
        value: formatReadTime(stats.totalReadTimeSeconds),
      ),
      _StatCard(
        icon: Icons.local_fire_department_outlined,
        label: 'Reading streak',
        value: '${stats.readingStreakDays} hari',
      ),
    ];

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _StatRow(left: cards[0], right: cards[1]),
            const SizedBox(height: 16),
            _StatRow(left: cards[2], right: cards[3]),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _StatRow({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 26),
            const SizedBox(height: 10),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}