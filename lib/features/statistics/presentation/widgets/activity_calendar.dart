import 'package:flutter/material.dart';

import '../../domain/entities/day_activity.dart';

class ActivityCalendar extends StatelessWidget {
  /// Harus terurut ascending (hari paling lama duluan).
  final List<DayActivity> days;
  final ValueChanged<DayActivity> onSelectDay;

  const ActivityCalendar({
    super.key,
    required this.days,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (days.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxSeconds = days.fold<int>(0, (m, d) => d.readTimeSeconds > m ? d.readTimeSeconds : m);

    // Minggu ala GitHub: Senin di baris paling atas, Minggu di paling
    // bawah, minggu berjalan dari kiri (lama) ke kanan (baru).
    final leadingBlanks = days.first.date.weekday - 1; // Mon=1 -> 0 blanks
    final totalCells = leadingBlanks + days.length;
    final columnCount = (totalCells / 7).ceil();

    final columns = <Widget>[];
    for (var w = 0; w < columnCount; w++) {
      final cells = <Widget>[];
      for (var d = 0; d < 7; d++) {
        final index = w * 7 + d;
        final dayIndex = index - leadingBlanks;
        if (dayIndex < 0 || dayIndex >= days.length) {
          cells.add(const SizedBox(width: 14, height: 14));
        } else {
          final day = days[dayIndex];
          cells.add(_DayCell(
            day: day,
            maxSeconds: maxSeconds,
            onTap: () => onSelectDay(day),
          ));
        }
      }
      columns.add(
        Padding(
          padding: const EdgeInsets.only(right: 3),
          child: Column(
            children: [
              for (var i = 0; i < cells.length; i++) ...[
                if (i > 0) const SizedBox(height: 3),
                cells[i],
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Activity',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Ketuk satu kotak untuk lihat detail hari itu',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // langsung scroll ke minggu terbaru (kanan)
            child: Row(children: columns),
          ),
          const SizedBox(height: 12),
          _Legend(),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DayActivity day;
  final int maxSeconds;
  final VoidCallback onTap;

  const _DayCell({required this.day, required this.maxSeconds, required this.onTap});

  Color _colorFor(BuildContext context) {
    final theme = Theme.of(context);
    if (!day.hasActivity || maxSeconds == 0) {
      return theme.colorScheme.surfaceContainerHighest;
    }
    final intensity = (day.readTimeSeconds / maxSeconds).clamp(0.0, 1.0);
    final opacity = 0.25 + intensity * 0.75;
    return theme.colorScheme.primary.withOpacity(opacity);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: _colorFor(context),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text('Less', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
        const SizedBox(width: 6),
        for (final opacity in [0.0, 0.35, 0.6, 0.85, 1.0]) ...[
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: opacity == 0
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.primary.withOpacity(opacity),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text('More', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
      ],
    );
  }
}