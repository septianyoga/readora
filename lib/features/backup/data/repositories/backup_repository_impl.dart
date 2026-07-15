import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../../core/database/database_helper.dart';
import '../../domain/repositories/backup_repository.dart';

class BackupRepositoryImpl implements BackupRepository {
  final DatabaseHelper _dbHelper;

  BackupRepositoryImpl({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<File> _databaseFile() async {
    final docsDir = await getApplicationDocumentsDirectory();
    return File(p.join(docsDir.path, 'bookreader.db'));
  }

  @override
  Future<List<int>> createBackupBytes() async {
    // Tutup koneksi dulu supaya file tidak sedang dipakai/di-lock saat
    // dibaca mentah-mentah.
    await _dbHelper.close();

    final dbFile = await _databaseFile();
    if (!await dbFile.exists()) {
      throw Exception('Database belum dibuat, tidak ada yang bisa di-backup.');
    }
    final dbBytes = await dbFile.readAsBytes();

    final archive = Archive()
      ..addFile(ArchiveFile('database.sqlite', dbBytes.length, dbBytes));

    final zipBytes = ZipEncoder().encode(archive);

    // Buka lagi koneksi supaya app bisa lanjut dipakai seperti biasa.
    await _dbHelper.database;

    if (zipBytes == null) {
      throw Exception('Gagal membuat file backup.');
    }
    return zipBytes;
  }

  @override
  Future<void> restoreFromBytes(List<int> zipBytes) async {
    final archive = ZipDecoder().decodeBytes(zipBytes);

    ArchiveFile? dbEntry;
    for (final file in archive.files) {
      if (file.name == 'database.sqlite') {
        dbEntry = file;
        break;
      }
    }
    if (dbEntry == null) {
      throw Exception(
        'File backup tidak valid: database.sqlite tidak ditemukan di dalam zip.',
      );
    }

    await _dbHelper.close();

    final dbFile = await _databaseFile();
    await dbFile.writeAsBytes(dbEntry.content as List<int>, flush: true);

    // Buka ulang koneksi ke database yang baru saja dipulihkan.
    await _dbHelper.database;
  }
}