import '../../domain/entities/book.dart';

/// Representasi baris tabel `books`. Bertanggung jawab untuk konversi
/// antara `Map<String, dynamic>` (format sqflite) dan entity domain [Book].
class BookModel {
  final String id;
  final String title;
  final String? author;
  final String? coverPath;
  final String pdfPath;
  final int totalPages;
  final int fileSize;
  final int createdAt; // epoch millis
  final int updatedAt; // epoch millis

  const BookModel({
    required this.id,
    required this.title,
    this.author,
    this.coverPath,
    required this.pdfPath,
    required this.totalPages,
    required this.fileSize,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookModel.fromMap(Map<String, dynamic> map) {
    return BookModel(
      id: map['id'] as String,
      title: map['title'] as String,
      author: map['author'] as String?,
      coverPath: map['cover_path'] as String?,
      pdfPath: map['pdf_path'] as String,
      totalPages: map['total_pages'] as int? ?? 0,
      fileSize: map['file_size'] as int? ?? 0,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'cover_path': coverPath,
      'pdf_path': pdfPath,
      'total_pages': totalPages,
      'file_size': fileSize,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Book toEntity({
    int currentPage = 0,
    double percentage = 0,
    DateTime? lastOpenedAt,
  }) {
    return Book(
      id: id,
      title: title,
      author: author,
      coverPath: coverPath,
      pdfPath: pdfPath,
      totalPages: totalPages,
      fileSize: fileSize,
      createdAt: DateTime.fromMillisecondsSinceEpoch(createdAt),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(updatedAt),
      currentPage: currentPage,
      percentage: percentage,
      lastOpenedAt: lastOpenedAt,
    );
  }

  factory BookModel.fromEntity(Book book) {
    return BookModel(
      id: book.id,
      title: book.title,
      author: book.author,
      coverPath: book.coverPath,
      pdfPath: book.pdfPath,
      totalPages: book.totalPages,
      fileSize: book.fileSize,
      createdAt: book.createdAt.millisecondsSinceEpoch,
      updatedAt: book.updatedAt.millisecondsSinceEpoch,
    );
  }
}
