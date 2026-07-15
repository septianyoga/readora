import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../bookmarks/presentation/providers/bookmark_providers.dart';
import '../../domain/entities/reading_progress.dart';
import '../providers/reader_providers.dart';

/// Toolbar di PDF Reader screen: bookmark, table of contents, search text,
/// dan pengaturan reading mode.
///
/// Pada Phase 3, bookmark sudah fungsional penuh (toggle untuk halaman
/// yang sedang dibuka). Table of contents dan search text masih di luar
/// cakupan spesifikasi Phase 1–3, jadi tetap disediakan sebagai tombol
/// dengan pemberitahuan "belum tersedia" supaya struktur toolbar sudah
/// sesuai spesifikasi sejak awal.
class ReaderToolbar extends ConsumerWidget implements PreferredSizeWidget {
  final String bookId;
  final String bookTitle;
  final int currentPage;

  const ReaderToolbar({
    super.key,
    required this.bookId,
    required this.bookTitle,
    required this.currentPage,
  });

  void _notAvailableYet(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature belum tersedia')),
    );
  }

  Future<void> _toggleBookmark(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(bookmarkListProvider(bookId).notifier);
    final wasBookmarked = isPageBookmarked(
      ref.read(bookmarkListProvider(bookId)).valueOrNull ?? [],
      currentPage,
    );
    await notifier.toggleForPage(currentPage);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          wasBookmarked
              ? 'Bookmark halaman $currentPage dihapus'
              : 'Halaman $currentPage ditandai bookmark',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks =
        ref.watch(bookmarkListProvider(bookId)).valueOrNull ?? [];
    final bookmarked = isPageBookmarked(bookmarks, currentPage);

    return AppBar(
      title: Text(bookTitle, overflow: TextOverflow.ellipsis),
      actions: [
        IconButton(
          tooltip: bookmarked ? 'Hapus bookmark' : 'Bookmark halaman ini',
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) => ScaleTransition(
              scale: animation,
              child: child,
            ),
            child: Icon(
              bookmarked ? Icons.bookmark : Icons.bookmark_border,
              key: ValueKey(bookmarked),
            ),
          ),
          onPressed: () => _toggleBookmark(context, ref),
        ),
        IconButton(
          tooltip: 'Table of contents',
          icon: const Icon(Icons.toc_outlined),
          onPressed: () => _notAvailableYet(context, 'Table of contents'),
        ),
        IconButton(
          tooltip: 'Cari teks',
          icon: const Icon(Icons.search),
          onPressed: () => _notAvailableYet(context, 'Search text'),
        ),
        PopupMenuButton<ReadingMode>(
          tooltip: 'Reading mode',
          icon: const Icon(Icons.brightness_6_outlined),
          initialValue: ref.watch(readingModeProvider),
          onSelected: (mode) =>
              ref.read(readingModeProvider.notifier).state = mode,
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: ReadingMode.light,
              child: Text('Light'),
            ),
            PopupMenuItem(
              value: ReadingMode.dark,
              child: Text('Dark'),
            ),
            PopupMenuItem(
              value: ReadingMode.sepia,
              child: Text('Sepia'),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}