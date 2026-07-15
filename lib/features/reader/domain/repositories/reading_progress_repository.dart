import '../entities/reading_progress.dart';

abstract class ReadingProgressRepository {
  /// Mengambil progress membaca untuk satu buku. Mengembalikan progress
  /// kosong (halaman 0) jika buku belum pernah dibuka sama sekali.
  Future<ReadingProgress> getProgress(String bookId);

  /// Mengambil progress untuk banyak buku sekaligus, dipakai Library
  /// screen supaya tidak query satu-satu per buku (N+1 query).
  Future<Map<String, ReadingProgress>> getProgressForBooks(
    List<String> bookIds,
  );

  /// Update halaman saat ini + persentase, dipanggil setiap kali user
  /// berpindah halaman di reader (auto save).
  Future<void> updateCurrentPage({
    required String bookId,
    required int currentPage,
    required int totalPages,
  });

  /// Menambahkan durasi baca (detik) ke akumulasi total_read_time,
  /// dipanggil saat user keluar dari reader screen.
  Future<void> addReadingTime({
    required String bookId,
    required int seconds,
  });

  /// Menghapus seluruh riwayat baca semua buku (dipakai Setting screen).
  Future<void> clearAllHistory();
}