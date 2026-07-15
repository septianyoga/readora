import 'dart:io';

import 'package:flutter/material.dart';

import '../../domain/entities/book.dart';

/// Kartu buku reusable, dipakai di grid Library screen.
///
/// Menampilkan cover, judul, progress membaca (persentase) dan halaman
/// terakhir dibaca — sesuai spesifikasi UI:
///
/// ```
/// [Cover]
/// Clean Code
/// 67% selesai
/// Last read: Page 214
/// ```
class BookCard extends StatelessWidget {
  final Book book;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const BookCard({
    super.key,
    required this.book,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasProgress = book.currentPage > 0 && book.totalPages > 0;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _Cover(book: book)),
              const SizedBox(height: 8),
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              if (hasProgress) ...[
                Text(
                  '${(book.percentage).clamp(0, 100).toStringAsFixed(0)}% selesai',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  'Last read: Page ${book.currentPage}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ] else
                Text(
                  'Belum dibaca',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  final Book book;

  const _Cover({required this.book});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverPath = book.coverPath;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Hero(
        tag: 'book-cover-${book.id}',
        child: SizedBox.expand(
          child: coverPath != null && File(coverPath).existsSync()
              ? Image.file(File(coverPath), fit: BoxFit.cover)
              : Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 36,
                    color: theme.colorScheme.outline,
                  ),
                ),
        ),
      ),
    );
  }
}