import 'package:equatable/equatable.dart';

/// Representasi buku pada layer domain.
///
/// Sengaja dipisah dari `BookModel` (data layer) supaya UI dan business
/// logic tidak bergantung langsung pada struktur tabel SQLite.
class Book extends Equatable {
  final String id;
  final String title;
  final String? author;
  final String? coverPath;
  final String pdfPath;
  final int totalPages;
  final int fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Diisi dari join dengan reading_progress pada phase berikutnya.
  // Untuk Phase 1 nilainya selalu default (belum ada progress tersimpan).
  final int currentPage;
  final double percentage;
  final DateTime? lastOpenedAt;

  const Book({
    required this.id,
    required this.title,
    this.author,
    this.coverPath,
    required this.pdfPath,
    required this.totalPages,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
    this.currentPage = 0,
    this.percentage = 0,
    this.lastOpenedAt,
  });

  Book copyWith({
    String? title,
    String? author,
    String? coverPath,
    int? totalPages,
    int? currentPage,
    double? percentage,
    DateTime? lastOpenedAt,
    DateTime? updatedAt,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      coverPath: coverPath ?? this.coverPath,
      pdfPath: pdfPath,
      totalPages: totalPages ?? this.totalPages,
      fileSize: fileSize,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      currentPage: currentPage ?? this.currentPage,
      percentage: percentage ?? this.percentage,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        author,
        coverPath,
        pdfPath,
        totalPages,
        fileSize,
        createdAt,
        updatedAt,
        currentPage,
        percentage,
        lastOpenedAt,
      ];
}

enum BookSortOption {
  lastRead,
  recentlyAdded,
  title,
}
