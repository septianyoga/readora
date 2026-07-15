import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../books/presentation/providers/book_providers.dart';
import '../../domain/entities/note.dart';
import '../providers/note_providers.dart';
import '../widgets/note_form_dialog.dart';

class NotesScreen extends ConsumerWidget {
  final String bookId;

  const NotesScreen({super.key, required this.bookId});

  Future<void> _addNote(BuildContext context, WidgetRef ref, int totalPages) async {
    final result = await showNoteFormDialog(context, totalPages: totalPages);
    if (result == null) return;
    await ref.read(noteListProvider(bookId).notifier).add(
          pageNumber: result.pageNumber,
          content: result.content,
        );
  }

  Future<void> _editNote(BuildContext context, WidgetRef ref, Note note, int totalPages) async {
    final result = await showNoteFormDialog(
      context,
      initialPage: note.pageNumber,
      initialContent: note.content,
      totalPages: totalPages,
    );
    if (result == null) return;
    await ref.read(noteListProvider(bookId).notifier).edit(
          noteId: note.id,
          content: result.content,
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(noteListProvider(bookId));
    final bookAsync = ref.watch(bookByIdProvider(bookId));
    final totalPages = bookAsync.valueOrNull?.totalPages ?? 1;

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNote(context, ref, totalPages),
        child: const Icon(Icons.add),
      ),
      body: notesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Terjadi kesalahan: $error')),
        data: (notes) {
          if (notes.isEmpty) {
            return const _EmptyNotes();
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final note = notes[index];
              return _NoteTile(
                note: note,
                onTap: () => _editNote(context, ref, note, totalPages),
                onDelete: () =>
                    ref.read(noteListProvider(bookId).notifier).remove(note.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NoteTile({
    required this.note,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ListTile(
        onTap: onTap,
        isThreeLine: true,
        title: Text(
          'Page ${note.pageNumber}',
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        subtitle: Text(
          note.content,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Hapus note',
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _EmptyNotes extends StatelessWidget {
  const _EmptyNotes();

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
              Icons.notes_outlined,
              size: 56,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('Belum ada catatan', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Tekan tombol + untuk menambahkan catatan pada halaman tertentu.',
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