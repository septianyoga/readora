import 'package:equatable/equatable.dart';

/// Aktivitas baca satu buku dalam periode tertentu — dipakai Top Books
/// section.
class BookActivity extends Equatable {
  final String bookId;
  final String title;
  final String? coverPath;
  final int readTimeSeconds;
  final int pagesRead;
  final double completionPercentage;

  const BookActivity({
    required this.bookId,
    required this.title,
    this.coverPath,
    required this.readTimeSeconds,
    required this.pagesRead,
    required this.completionPercentage,
  });

  @override
  List<Object?> get props => [
        bookId,
        title,
        coverPath,
        readTimeSeconds,
        pagesRead,
        completionPercentage,
      ];
}