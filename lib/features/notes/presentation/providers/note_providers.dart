import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/note.dart';

class NoteListNotifier extends FamilyAsyncNotifier<List<Note>, String> {
  @override
  Future<List<Note>> build(String bookId) async {
    final repository = ref.watch(noteRepositoryProvider);
    return repository.getNotesForBook(bookId);
  }

  Future<void> _refresh() async {
    final repository = ref.read(noteRepositoryProvider);
    state = await AsyncValue.guard(() => repository.getNotesForBook(arg));
  }

  Future<void> add({required int pageNumber, required String content}) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.addNote(bookId: arg, pageNumber: pageNumber, content: content);
    await _refresh();
  }

  Future<void> edit({required String noteId, required String content}) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.updateNote(id: noteId, content: content);
    await _refresh();
  }

  Future<void> remove(String noteId) async {
    final repository = ref.read(noteRepositoryProvider);
    await repository.deleteNote(noteId);
    await _refresh();
  }
}

final noteListProvider =
    AsyncNotifierProvider.family<NoteListNotifier, List<Note>, String>(
  NoteListNotifier.new,
);