import '../../../reader/domain/entities/reading_progress.dart';
import '../../domain/entities/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl({SettingsLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? SettingsLocalDataSource();

  ReadingMode _parseReadingMode(String? value) {
    switch (value) {
      case 'dark':
        return ReadingMode.dark;
      case 'sepia':
        return ReadingMode.sepia;
      case 'light':
      default:
        return ReadingMode.light;
    }
  }

  @override
  Future<AppSettings> getSettings() async {
    final row = await _localDataSource.getRow();
    if (row == null) return AppSettings.defaults;

    return AppSettings(
      darkMode: (row['dark_mode'] as int? ?? 0) == 1,
      fontSize: (row['font_size'] as num?)?.toDouble() ?? 16,
      defaultReadingMode:
          _parseReadingMode(row['default_reading_mode'] as String?),
    );
  }

  @override
  Future<void> updateSettings(AppSettings settings) {
    return _localDataSource.save(
      darkMode: settings.darkMode,
      fontSize: settings.fontSize,
      defaultReadingMode: settings.defaultReadingMode.name,
    );
  }
}