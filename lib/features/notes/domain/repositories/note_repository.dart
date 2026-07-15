import '../entities/note.dart';

abstract class NoteRepository {
  /// Semua catatan untuk satu buku, terurut dari halaman terkecil.
  Future<List<Note>> getNotesForBook(String bookId);

  Future<void> addNote({
    required String bookId,
    required int pageNumber,
    required String content,
  });

  Future<void> updateNote({
    required String id,
    required String content,
  });

  Future<void> deleteNote(String id);
}