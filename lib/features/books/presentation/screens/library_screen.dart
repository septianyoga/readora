import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../shared/widgets/staggered_fade_in.dart';
import '../../domain/entities/book.dart';
import '../providers/book_providers.dart';
import '../widgets/book_card.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  Future<void> _pickAndImportBook(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);

    try {
      await ref.read(bookLibraryProvider.notifier).importBook(file);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengimpor PDF: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(filteredBooksProvider);
    final sortOption = ref.watch(bookSortOptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          PopupMenuButton<BookSortOption>(
            icon: const Icon(Icons.sort),
            initialValue: sortOption,
            onSelected: (value) =>
                ref.read(bookSortOptionProvider.notifier).state = value,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: BookSortOption.lastRead,
                child: Text('Terakhir dibaca'),
              ),
              PopupMenuItem(
                value: BookSortOption.recentlyAdded,
                child: Text('Terbaru ditambahkan'),
              ),
              PopupMenuItem(
                value: BookSortOption.title,
                child: Text('Judul'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndImportBook(context, ref),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _SearchField(
              onChanged: (value) =>
                  ref.read(bookSearchQueryProvider.notifier).state = value,
            ),
          ),
          Expanded(
            child: booksAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Text('Terjadi kesalahan: $error'),
              ),
              data: (books) {
                if (books.isEmpty) {
                  return const _EmptyLibrary();
                }
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(bookLibraryProvider.notifier).refresh(),
                  child: GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: books.length,
                    itemBuilder: (context, index) {
                      final book = books[index];
                      return StaggeredFadeIn(
                        index: index,
                        child: BookCard(
                          book: book,
                          onTap: () async {
                            await Navigator.of(context).pushNamed(
                              AppRoutes.bookDetail,
                              arguments: book.id,
                            );
                            // Progress bisa berubah setelah user membaca,
                            // jadi refresh grid saat kembali ke Library.
                            ref.invalidate(bookLibraryProvider);
                          },
                          onLongPress: () =>
                              _showDeleteConfirmation(context, ref, book),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Book book,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus buku?'),
        content: Text('"${book.title}" akan dihapus dari library.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          FilledButton.tonal(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(bookLibraryProvider.notifier).deleteBook(book.id);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Cari judul atau penulis...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Belum ada buku',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menambahkan PDF pertamamu.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}