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

  /// Mencatat satu sesi baca lengkap (dari buka reader sampai ditutup) ke
  /// tabel `reading_sessions`, sekaligus menambahkan durasinya ke akumulasi
  /// `total_read_time` di `reading_progress`. Dipanggil sekali saat user
  /// keluar dari reader screen.
  Future<void> logSession({
    required String bookId,
    required DateTime startedAt,
    required DateTime endedAt,
    required int startPage,
    required int endPage,
  });

  /// Menghapus seluruh riwayat baca semua buku (dipakai Setting screen).
  Future<void> clearAllHistory();
}