import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/reading_habits.dart';

class ReadingHabitsSection extends StatelessWidget {
  final ReadingHabits habits;

  const ReadingHabitsSection({super.key, required this.habits});

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours == 0) return '${minutes}m';
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final hasData = habits.averageSession > Duration.zero;

    final items = <_HabitItem>[
      _HabitItem(
        icon: Icons.timer_outlined,
        label: 'Average session',
        value: hasData ? _formatDuration(habits.averageSession) : '—',
      ),
      _HabitItem(
        icon: Icons.menu_book_outlined,
        label: 'Avg pages / session',
        value: hasData ? habits.averagePagesPerSession.toStringAsFixed(1) : '—',
      ),
      _HabitItem(
        icon: Icons.today_outlined,
        label: 'Avg daily reading',
        value: hasData ? _formatDuration(habits.averageDailyReadingTime) : '—',
      ),
      _HabitItem(
        icon: Icons.wb_sunny_outlined,
        label: 'Preferred time',
        value: habits.preferredTime?.label ?? '—',
      ),
      _HabitItem(
        icon: Icons.hourglass_bottom_outlined,
        label: 'Longest session',
        value: hasData ? _formatDuration(habits.longestSession) : '—',
      ),
      _HabitItem(
        icon: Icons.bolt_outlined,
        label: 'Fastest reading day',
        value: habits.fastestDay != null
            ? DateFormat('d MMM').format(habits.fastestDay!)
            : '—',
      ),
    ];

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
            'Reading Habits',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 20, color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
            items[i],
          ],
        ],
      ),
    );
  }
}

class _HabitItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HabitItem({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}