import 'package:equatable/equatable.dart';

import '../../../reader/domain/entities/reading_progress.dart' show ReadingMode;

/// Representasi pengaturan aplikasi (baris tunggal tabel `settings`).
class AppSettings extends Equatable {
  final bool darkMode;
  final double fontSize;
  final ReadingMode defaultReadingMode;

  const AppSettings({
    required this.darkMode,
    required this.fontSize,
    required this.defaultReadingMode,
  });

  static const defaults = AppSettings(
    darkMode: false,
    fontSize: 16,
    defaultReadingMode: ReadingMode.light,
  );

  AppSettings copyWith({
    bool? darkMode,
    double? fontSize,
    ReadingMode? defaultReadingMode,
  }) {
    return AppSettings(
      darkMode: darkMode ?? this.darkMode,
      fontSize: fontSize ?? this.fontSize,
      defaultReadingMode: defaultReadingMode ?? this.defaultReadingMode,
    );
  }

  @override
  List<Object?> get props => [darkMode, fontSize, defaultReadingMode];
}