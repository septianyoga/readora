import 'package:flutter/material.dart';

import '../../../reading_goal/domain/entities/reading_goal.dart';

class ReadingGoalCard extends StatelessWidget {
  final ReadingGoalProgress? progress;
  final VoidCallback onTapSetGoal;

  const ReadingGoalCard({
    super.key,
    required this.progress,
    required this.onTapSetGoal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (progress == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Belum ada target baca. Yuk tentukan satu!',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            FilledButton.tonal(
              onPressed: onTapSetGoal,
              child: const Text('Set Goal'),
            ),
          ],
        ),
      );
    }

    final p = progress!;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: p.fraction),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation(
                        p.isCompleted ? Colors.green : theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${(value * 100).round()}%',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  p.goal.type.label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${p.current.toStringAsFixed(p.current.truncateToDouble() == p.current ? 0 : 1)} / '
                  '${p.goal.target.toStringAsFixed(p.goal.target.truncateToDouble() == p.goal.target ? 0 : 1)} '
                  '${p.goal.type.unit}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (p.isCompleted) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Target tercapai! 🎉',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            tooltip: 'Edit goal',
            onPressed: onTapSetGoal,
          ),
        ],
      ),
    );
  }
}