/// Filter periode di Statistics dashboard.
enum TimePeriod { today, week, month, year, allTime }

extension TimePeriodX on TimePeriod {
  String get label {
    switch (this) {
      case TimePeriod.today:
        return 'Today';
      case TimePeriod.week:
        return 'Week';
      case TimePeriod.month:
        return 'Month';
      case TimePeriod.year:
        return 'Year';
      case TimePeriod.allTime:
        return 'All Time';
    }
  }

  /// Rentang waktu [start, end) untuk periode ini, relatif terhadap [now].
  /// `end` bersifat eksklusif supaya gampang dipakai di query SQL
  /// (`started_at >= start AND started_at < end`).
  PeriodRange rangeFrom(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case TimePeriod.today:
        return PeriodRange(today, today.add(const Duration(days: 1)));
      case TimePeriod.week:
        // Senin sebagai awal minggu.
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return PeriodRange(
          startOfWeek,
          startOfWeek.add(const Duration(days: 7)),
        );
      case TimePeriod.month:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 1);
        return PeriodRange(start, end);
      case TimePeriod.year:
        return PeriodRange(DateTime(now.year, 1, 1), DateTime(now.year + 1, 1, 1));
      case TimePeriod.allTime:
        // Batas bawah cukup jauh ke belakang (aplikasi ini belum pernah
        // rilis sebelum tanggal ini), jadi cukup aman dipakai sebagai
        // "sejak awal".
        return PeriodRange(DateTime(2020), today.add(const Duration(days: 1)));
    }
  }
}

/// Sengaja bikin class sendiri dengan nama BERBEDA dari
/// `package:flutter/material.dart`'s `DateTimeRange` (meski secara teknis
/// aman selama tidak dipakai bersamaan di file yang sama, konflik nama
/// begini gampang bikin bingung) — dan supaya entity domain di layer ini
/// tidak perlu depend ke Flutter framework sama sekali.
class PeriodRange {
  final DateTime start;
  final DateTime end;

  const PeriodRange(this.start, this.end);

  int get startMillis => start.millisecondsSinceEpoch;
  int get endMillis => end.millisecondsSinceEpoch;

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);
}