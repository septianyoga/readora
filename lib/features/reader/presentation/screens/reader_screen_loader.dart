import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../books/presentation/providers/book_providers.dart';
import 'pdf_reader_screen.dart';

/// Route `/reader` hanya menerima `bookId`, sedangkan [PdfReaderScreen]
/// butuh entity [Book] lengkap. Widget ini menjembatani keduanya: resolve
/// buku dulu lewat [bookByIdProvider], baru render reader sesungguhnya.
class ReaderScreenLoader extends ConsumerWidget {
  final String bookId;
  final int startPage;

  const ReaderScreenLoader({
    super.key,
    required this.bookId,
    required this.startPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookByIdProvider(bookId));

    return bookAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Gagal memuat buku: $error')),
      ),
      data: (book) {
        if (book == null) {
          return const Scaffold(
            body: Center(child: Text('Buku tidak ditemukan.')),
          );
        }
        return PdfReaderScreen(book: book, startPage: startPage);
      },
    );
  }
}
