import 'package:equatable/equatable.dart';

/// Ringkasan statistik membaca lintas seluruh buku di library.
class ReadingStatistics extends Equatable {
  final int totalBooks;
  final int pagesRead;
  final int totalReadTimeSeconds;
  final int readingStreakDays;

  const ReadingStatistics({
    required this.totalBooks,
    required this.pagesRead,
    required this.totalReadTimeSeconds,
    required this.readingStreakDays,
  });

  static const empty = ReadingStatistics(
    totalBooks: 0,
    pagesRead: 0,
    totalReadTimeSeconds: 0,
    readingStreakDays: 0,
  );

  double get totalReadTimeHours => totalReadTimeSeconds / 3600;

  @override
  List<Object?> get props => [
        totalBooks,
        pagesRead,
        totalReadTimeSeconds,
        readingStreakDays,
      ];
}