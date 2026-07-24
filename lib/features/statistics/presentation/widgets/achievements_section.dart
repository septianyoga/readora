import 'package:flutter/material.dart';

import '../../domain/entities/achievement.dart';

const _iconMap = <String, IconData>{
  'menu_book': Icons.menu_book,
  'local_fire_department': Icons.local_fire_department,
  'whatshot': Icons.whatshot,
  'auto_stories': Icons.auto_stories,
  'library_books': Icons.library_books,
  'weekend': Icons.weekend,
  'nightlight_round': Icons.nightlight_round,
  'wb_twilight': Icons.wb_twilight,
};

class AchievementsSection extends StatelessWidget {
  final List<Achievement> achievements;

  const AchievementsSection({super.key, required this.achievements});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Achievements',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$unlockedCount/${achievements.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AchievementsGrid(achievements: achievements),
        ],
      ),
    );
  }
}

/// Grid 3 kolom yang mengisi PENUH lebar container (bukan `Wrap` dengan
/// card lebar tetap yang menyisakan ruang kosong di kanan kalau jumlah
/// kolom yang muat tidak pas). Baris terakhir yang tidak genap 3 diisi
/// placeholder transparan supaya lebar card tetap konsisten dengan
/// baris-baris lain, bukan card yang melar menutupi sisa ruang.
class _AchievementsGrid extends StatelessWidget {
  final List<Achievement> achievements;
  static const _columns = 3;

  const _AchievementsGrid({required this.achievements});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < achievements.length; i += _columns) {
      final rowItems = achievements.skip(i).take(_columns).toList();
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 12));
      rows.add(_AchievementRow(items: rowItems, columns: _columns));
    }
    return Column(children: rows);
  }
}

class _AchievementRow extends StatelessWidget {
  final List<Achievement> items;
  final int columns;

  const _AchievementRow({required this.items, required this.columns});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < columns; i++) {
      if (i > 0) children.add(const SizedBox(width: 12));
      children.add(
        Expanded(
          child: i < items.length
              ? _AchievementCard(achievement: items[i])
              : const SizedBox.shrink(),
        ),
      );
    }
    return IntrinsicHeight(child: Row(children: children));
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement achievement;

  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icon = _iconMap[achievement.iconKey] ?? Icons.emoji_events_outlined;

    return Opacity(
      opacity: achievement.unlocked ? 1 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: achievement.unlocked
                    ? theme.colorScheme.primary.withOpacity(0.15)
                    : theme.colorScheme.outlineVariant.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: achievement.unlocked
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}