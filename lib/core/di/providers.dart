import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/backup/data/repositories/backup_repository_impl.dart';
import '../../features/backup/domain/repositories/backup_repository.dart';
import '../../features/books/data/datasources/book_local_datasource.dart';
import '../../features/books/data/repositories/book_repository_impl.dart';
import '../../features/books/domain/repositories/book_repository.dart';
import '../../features/bookmarks/data/datasources/bookmark_local_datasource.dart';
import '../../features/bookmarks/data/repositories/bookmark_repository_impl.dart';
import '../../features/bookmarks/domain/repositories/bookmark_repository.dart';
import '../../features/notes/data/datasources/note_local_datasource.dart';
import '../../features/notes/data/repositories/note_repository_impl.dart';
import '../../features/notes/domain/repositories/note_repository.dart';
import '../../features/reader/data/datasources/reading_progress_local_datasource.dart';
import '../../features/reader/data/repositories/reading_progress_repository_impl.dart';
import '../../features/reader/domain/repositories/reading_progress_repository.dart';
import '../../features/settings/data/datasources/settings_local_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/statistics/data/repositories/statistics_repository_impl.dart';
import '../../features/statistics/domain/repositories/statistics_repository.dart';
import '../database/database_helper.dart';

/// Titik pusat dependency injection aplikasi.
///
/// Semua provider "wiring" (menghubungkan implementasi konkret ke
/// interface) diletakkan di sini supaya mudah ditelusuri, dan supaya
/// widget/provider fitur lain cukup depend pada interface
/// ([bookRepositoryProvider]) tanpa tahu detail implementasinya.

final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

final bookLocalDataSourceProvider = Provider<BookLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return BookLocalDataSource(dbHelper: dbHelper);
});

final readingProgressLocalDataSourceProvider =
    Provider<ReadingProgressLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return ReadingProgressLocalDataSource(dbHelper: dbHelper);
});

final readingProgressRepositoryProvider =
    Provider<ReadingProgressRepository>((ref) {
  final dataSource = ref.watch(readingProgressLocalDataSourceProvider);
  return ReadingProgressRepositoryImpl(localDataSource: dataSource);
});

final bookRepositoryProvider = Provider<BookRepository>((ref) {
  final dataSource = ref.watch(bookLocalDataSourceProvider);
  final progressDataSource = ref.watch(readingProgressLocalDataSourceProvider);
  return BookRepositoryImpl(
    localDataSource: dataSource,
    progressDataSource: progressDataSource,
  );
});

final bookmarkLocalDataSourceProvider = Provider<BookmarkLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return BookmarkLocalDataSource(dbHelper: dbHelper);
});

final bookmarkRepositoryProvider = Provider<BookmarkRepository>((ref) {
  final dataSource = ref.watch(bookmarkLocalDataSourceProvider);
  return BookmarkRepositoryImpl(localDataSource: dataSource);
});

final noteLocalDataSourceProvider = Provider<NoteLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return NoteLocalDataSource(dbHelper: dbHelper);
});

final noteRepositoryProvider = Provider<NoteRepository>((ref) {
  final dataSource = ref.watch(noteLocalDataSourceProvider);
  return NoteRepositoryImpl(localDataSource: dataSource);
});

final statisticsRepositoryProvider = Provider<StatisticsRepository>((ref) {
  final bookDataSource = ref.watch(bookLocalDataSourceProvider);
  final progressDataSource = ref.watch(readingProgressLocalDataSourceProvider);
  return StatisticsRepositoryImpl(
    bookDataSource: bookDataSource,
    progressDataSource: progressDataSource,
  );
});

final settingsLocalDataSourceProvider = Provider<SettingsLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return SettingsLocalDataSource(dbHelper: dbHelper);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dataSource = ref.watch(settingsLocalDataSourceProvider);
  return SettingsRepositoryImpl(localDataSource: dataSource);
});

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return BackupRepositoryImpl(dbHelper: dbHelper);
});