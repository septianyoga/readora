import 'package:equatable/equatable.dart';

/// Representasi satu bookmark pada layer domain.
class Bookmark extends Equatable {
  final String id;
  final String bookId;
  final int pageNumber;
  final DateTime createdAt;

  const Bookmark({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, bookId, pageNumber, createdAt];
}