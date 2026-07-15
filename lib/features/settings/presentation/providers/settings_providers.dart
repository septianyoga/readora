import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../reader/domain/entities/reading_progress.dart';
import '../../domain/entities/app_settings.dart';

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() async {
    final repository = ref.watch(settingsRepositoryProvider);
    return repository.getSettings();
  }

  Future<void> _update(AppSettings Function(AppSettings current) transform) async {
    final current = state.valueOrNull ?? AppSettings.defaults;
    final updated = transform(current);
    // Optimistic update supaya UI (switch/slider) langsung responsif,
    // baru ditulis ke database di belakang layar.
    state = AsyncData(updated);
    await ref.read(settingsRepositoryProvider).updateSettings(updated);
  }

  Future<void> setDarkMode(bool value) {
    return _update((s) => s.copyWith(darkMode: value));
  }

  Future<void> setFontSize(double value) {
    return _update((s) => s.copyWith(fontSize: value));
  }

  Future<void> setDefaultReadingMode(ReadingMode mode) {
    return _update((s) => s.copyWith(defaultReadingMode: mode));
  }

  /// Menghapus seluruh riwayat baca (tabel `reading_progress`). Buku,
  /// bookmark, dan notes TIDAK ikut terhapus.
  Future<void> clearReadingHistory() async {
    await ref.read(readingProgressRepositoryProvider).clearAllHistory();
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);