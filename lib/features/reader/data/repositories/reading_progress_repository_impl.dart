import '../../domain/entities/reading_progress.dart';
import '../../domain/repositories/reading_progress_repository.dart';
import '../datasources/reading_progress_local_datasource.dart';

class ReadingProgressRepositoryImpl implements ReadingProgressRepository {
  final ReadingProgressLocalDataSource _localDataSource;

  ReadingProgressRepositoryImpl({
    ReadingProgressLocalDataSource? localDataSource,
  }) : _localDataSource = localDataSource ?? ReadingProgressLocalDataSource();

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
  Future<void> addReadingTime({
    required String bookId,
    required int seconds,
  }) async {
    if (seconds <= 0) return;
    await _localDataSource.incrementReadingTime(bookId, seconds);
  }

  @override
  Future<void> clearAllHistory() {
    return _localDataSource.clearAll();
  }
}