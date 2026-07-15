import 'package:equatable/equatable.dart';

/// Representasi progress membaca satu buku, terpisah dari entity [Book]
/// supaya fitur reader tidak bergantung pada struktur tabel `books`.
class ReadingProgress extends Equatable {
  final String id;
  final String bookId;
  final int currentPage;
  final double percentage;
  final DateTime? lastOpenedAt;
  final int totalReadTimeSeconds;

  const ReadingProgress({
    required this.id,
    required this.bookId,
    required this.currentPage,
    required this.percentage,
    this.lastOpenedAt,
    this.totalReadTimeSeconds = 0,
  });

  factory ReadingProgress.initial(String bookId) {
    return ReadingProgress(
      id: bookId, // 1 buku = 1 baris progress, jadi aman dipakai sebagai id
      bookId: bookId,
      currentPage: 0,
      percentage: 0,
      lastOpenedAt: null,
      totalReadTimeSeconds: 0,
    );
  }

  ReadingProgress copyWith({
    int? currentPage,
    double? percentage,
    DateTime? lastOpenedAt,
    int? totalReadTimeSeconds,
  }) {
    return ReadingProgress(
      id: id,
      bookId: bookId,
      currentPage: currentPage ?? this.currentPage,
      percentage: percentage ?? this.percentage,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      totalReadTimeSeconds: totalReadTimeSeconds ?? this.totalReadTimeSeconds,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookId,
        currentPage,
        percentage,
        lastOpenedAt,
        totalReadTimeSeconds,
      ];
}

/// Reading mode untuk tampilan halaman PDF.
enum ReadingMode { light, dark, sepia }
