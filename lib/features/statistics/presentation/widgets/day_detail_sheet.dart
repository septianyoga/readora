import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/day_activity.dart';

Future<void> showDayDetailSheet(BuildContext context, DayActivity day) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => _DayDetailSheet(day: day),
  );
}

class _DayDetailSheet extends StatelessWidget {
  final DayActivity day;

  const _DayDetailSheet({required this.day});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hours = day.readTimeSeconds ~/ 3600;
    final minutes = (day.readTimeSeconds % 3600) ~/ 60;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, d MMMM y').format(day.date),
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),
          if (!day.hasActivity)
            Text(
              'Tidak ada aktivitas baca di hari ini.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            )
          else
            Row(
              children: [
                _Stat(label: 'Reading time', value: '${hours}h ${minutes}m'),
                _Stat(label: 'Pages read', value: '${day.pagesRead}'),
                _Stat(label: 'Sessions', value: '${day.sessionCount}'),
              ],
            ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}