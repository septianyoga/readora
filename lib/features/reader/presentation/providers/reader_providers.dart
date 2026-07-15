import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../settings/presentation/providers/settings_providers.dart';
import '../../domain/entities/reading_progress.dart';

/// Reading mode (light/dark/sepia) aktif di reader untuk sesi baca saat
/// ini. Nilai awalnya diambil dari "Default reading mode" di Setting
/// screen (Phase 4); setelah itu user bisa override sementara lewat
/// toolbar reader tanpa mengubah default globalnya.
final readingModeProvider = StateProvider<ReadingMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.valueOrNull?.defaultReadingMode ?? ReadingMode.light;
});

/// Mengambil progress membaca terakhir untuk satu buku. Dipakai Book
/// Detail screen untuk menentukan apakah tombol "Continue Reading"
/// ditampilkan, dan halaman berapa reader harus mulai.
final bookProgressProvider =
    FutureProvider.family<ReadingProgress, String>((ref, bookId) async {
  final repository = ref.watch(readingProgressRepositoryProvider);
  return repository.getProgress(bookId);
});