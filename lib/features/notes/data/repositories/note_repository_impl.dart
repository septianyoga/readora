import '../../domain/entities/note.dart';
import '../../domain/repositories/note_repository.dart';
import '../datasources/note_local_datasource.dart';

class NoteRepositoryImpl implements NoteRepository {
  final NoteLocalDataSource _localDataSource;

  NoteRepositoryImpl({NoteLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? NoteLocalDataSource();

  Note _mapRow(Map<String, dynamic> row) {
    return Note(
      id: row['id'] as String,
      bookId: row['book_id'] as String,
      pageNumber: row['page_number'] as int,
      content: row['content'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(row['created_at'] as int),
    );
  }

  @override
  Future<List<Note>> getNotesForBook(String bookId) async {
    final rows = await _localDataSource.getByBookId(bookId);
    return rows.map(_mapRow).toList();
  }

  @override
  Future<void> addNote({
    required String bookId,
    required int pageNumber,
    required String content,
  }) {
    return _localDataSource.insert(
      bookId: bookId,
      pageNumber: pageNumber,
      content: content,
    );
  }

  @override
  Future<void> updateNote({required String id, required String content}) {
    return _localDataSource.update(id: id, content: content);
  }

  @override
  Future<void> deleteNote(String id) {
    return _localDataSource.deleteById(id);
  }
}