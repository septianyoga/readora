abstract class BackupRepository {
  /// Membuat file zip backup (`database.sqlite` di dalamnya, yang sudah
  /// berisi seluruh metadata buku, bookmark, notes, dan settings karena
  /// semuanya satu file SQLite yang sama) dan mengembalikan bytes-nya
  /// untuk disimpan lewat file picker.
  Future<List<int>> createBackupBytes();

  /// Memulihkan seluruh database dari bytes file zip backup.
  /// Operasi ini MENIMPA seluruh data yang ada saat ini.
  Future<void> restoreFromBytes(List<int> zipBytes);
}