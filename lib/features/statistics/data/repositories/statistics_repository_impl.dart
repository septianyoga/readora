import '../../../books/data/datasources/book_local_datasource.dart';
import '../../../reader/data/datasources/reading_progress_local_datasource.dart';
import '../../domain/entities/reading_statistics.dart';
import '../../domain/repositories/statistics_repository.dart';

class StatisticsRepositoryImpl implements StatisticsRepository {
  final BookLocalDataSource _bookDataSource;
  final ReadingProgressLocalDataSource _progressDataSource;

  StatisticsRepositoryImpl({
    BookLocalDataSource? bookDataSource,
    ReadingProgressLocalDataSource? progressDataSource,
  })  : _bookDataSource = bookDataSource ?? BookLocalDataSource(),
        _progressDataSource = progressDataSource ?? ReadingProgressLocalDataSource();

  @override
  Future<ReadingStatistics> getStatistics() async {
    final books = await _bookDataSource.getAllBooks();
    final progressRows = await _progressDataSource.getAllRows();

    var pagesRead = 0;
    var totalReadTime = 0;
    for (final row in progressRows) {
      pagesRead += row['current_page'] as int? ?? 0;
      totalReadTime += row['total_read_time'] as int? ?? 0;
    }

    return ReadingStatistics(
      totalBooks: books.length,
      pagesRead: pagesRead,
      totalReadTimeSeconds: totalReadTime,
      readingStreakDays: _computeStreak(progressRows),
    );
  }

  /// Reading streak: jumlah hari berturut-turut (dihitung mundur dari hari
  /// ini) di mana ada minimal satu buku yang dibuka (`last_opened_at`).
  ///
  /// Kalau hari ini belum sempat buka buku, streak masih dianggap
  /// tersambung selama kemarin masih ada — supaya streak tidak langsung
  /// putus ke 0 di pagi hari sebelum user sempat membaca.
  int _computeStreak(List<Map<String, dynamic>> rows) {
    final readDates = <DateTime>{};
    for (final row in rows) {
      final millis = row['last_opened_at'] as int?;
      if (millis == null) continue;
      final dt = DateTime.fromMillisecondsSinceEpoch(millis);
      readDates.add(DateTime(dt.year, dt.month, dt.day));
    }
    if (readDates.isEmpty) return 0;

    final today = DateTime.now();
    var cursor = DateTime(today.year, today.month, today.day);

    if (!readDates.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!readDates.contains(cursor)) return 0;
    }

    var streak = 0;
    while (readDates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}