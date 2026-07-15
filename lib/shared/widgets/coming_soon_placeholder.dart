import 'package:flutter/material.dart';

/// Placeholder generik untuk screen yang belum diimplementasikan pada
/// phase saat ini. Dipakai oleh tab Statistics & Settings di Phase 1,
/// akan digantikan dengan screen sungguhan di Phase 3 & Phase 4.
class ComingSoonPlaceholder extends StatelessWidget {
  final String label;
  final IconData icon;

  const ComingSoonPlaceholder({
    super.key,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            '$label — coming soon',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
