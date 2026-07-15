import 'package:equatable/equatable.dart';

/// Representasi satu catatan (note) pada layer domain.
class Note extends Equatable {
  final String id;
  final String bookId;
  final int pageNumber;
  final String content;
  final DateTime createdAt;

  const Note({
    required this.id,
    required this.bookId,
    required this.pageNumber,
    required this.content,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, bookId, pageNumber, content, createdAt];
}