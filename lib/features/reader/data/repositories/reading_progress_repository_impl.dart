import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../datasources/reading_progress_local_datasource.dart';
import '../datasources/reading_session_local_datasource.dart';

class ReadingProgressRepositoryImpl implements ReadingProgressRepository {
  final ReadingProgressLocalDataSource _localDataSource;
  final ReadingSessionLocalDataSource _sessionDataSource;

  ReadingProgressRepositoryImpl({
    ReadingProgressLocalDataSource? localDataSource,
    ReadingSessionLocalDataSource? sessionDataSource,
  })  : _localDataSource = localDataSource ?? ReadingProgressLocalDataSource(),
        _sessionDataSource = sessionDataSource ?? ReadingSessionLocalDataSource();

  ReadingProgress _mapRow(Map<String, dynamic> row) {
    final lastOpenedMillis = row['last_opened_at'] as int?;
    return ReadingProgress(
      id: row['id'] as String,
      bookId: row['book_id'] as String,
      currentPage: row['current_page'] as int? ?? 0,
      percentage: (row['percentage'] as num?)?.toDouble() ?? 0,
      lastOpenedAt: lastOpenedMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(lastOpenedMillis)
          : null,
      totalReadTimeSeconds: row['total_read_time'] as int? ?? 0,
    );
  }

  @override
  Future<ReadingProgress> getProgress(String bookId) async {
    final row = await _localDataSource.getByBookId(bookId);
    if (row == null) return ReadingProgress.initial(bookId);
    return _mapRow(row);
  }

  @override
  Future<Map<String, ReadingProgress>> getProgressForBooks(
    List<String> bookIds,
  ) async {
    final rows = await _localDataSource.getByBookIds(bookIds);
    return {
      for (final row in rows) row['book_id'] as String: _mapRow(row),
    };
  }

  @override
  Future<void> updateCurrentPage({
    required String bookId,
    required int currentPage,
    required int totalPages,
  }) async {
    final percentage = totalPages > 0
        ? (currentPage / totalPages * 100).clamp(0, 100).toDouble()
        : 0.0;

    await _localDataSource.upsert(
      bookId: bookId,
      currentPage: currentPage,
      percentage: percentage,
      lastOpenedAt: DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> logSession({
    required String bookId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int startPage,
    required int endPage,
  }) async {
    final durationSeconds = endedAt.difference(startedAt).inSeconds;
    if (durationSeconds <= 0) return;

    final pagesRead = endPage > startPage ? endPage - startPage : 0;

    await _sessionDataSource.insert(
      bookId: bookId,
      startedAt: startedAt.millisecondsSinceEpoch,
      endedAt: endedAt.millisecondsSinceEpoch,
      durationSeconds: durationSeconds,
      startPage: startPage,
      endPage: endPage,
      pagesRead: pagesRead,
    );

    await _localDataSource.incrementReadingTime(bookId, durationSeconds);
  }

  @override
  Future<void> clearAllHistory() async {
    await _localDataSource.clearAll();
    await _sessionDataSource.clearAll();
  }
}