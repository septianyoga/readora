import 'package:flutter/material.dart';

import '../../domain/entities/statistics_dashboard.dart';

/// 4 card ringkasan di paling atas dashboard. Tetap pakai pola
/// `IntrinsicHeight` (bukan `GridView` + `childAspectRatio`) — pelajaran
/// dari bug overflow sebelumnya: tinggi card harus mengikuti konten
/// aslinya, bukan dipaksa ke angka tertentu, supaya aman di font size
/// berapa pun.
class OverviewCards extends StatelessWidget {
  final StatisticsDashboard dashboard;

  const OverviewCards({super.key, required this.dashboard});

  String _formatReadTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours == 0 && minutes == 0) return '0m';
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _OverviewCard(
        icon: Icons.library_books_outlined,
        label: 'Total Books',
        value: '${dashboard.totalBooks}',
        color: Colors.indigo,
      ),
      _OverviewCard(
        icon: Icons.auto_stories_outlined,
        label: 'Pages Read',
        value: '${dashboard.pagesRead}',
        color: Colors.teal,
      ),
      _OverviewCard(
        icon: Icons.schedule_outlined,
        label: 'Reading Time',
        value: _formatReadTime(dashboard.readTimeSeconds),
        color: Colors.orange,
      ),
      _OverviewCard(
        icon: Icons.local_fire_department_outlined,
        label: 'Reading Streak',
        value: '${dashboard.readingStreakDays}d',
        color: Colors.deepOrange,
      ),
    ];

    return Column(
      children: [
        _Row(left: cards[0], right: cards[1]),
        const SizedBox(height: 12),
        _Row(left: cards[2], right: cards[3]),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final Widget left;
  final Widget right;

  const _Row({required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          const SizedBox(width: 12),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _OverviewCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}