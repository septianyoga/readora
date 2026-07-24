import 'package:equatable/equatable.dart';

enum PreferredTimeOfDay { morning, afternoon, evening, night }

extension PreferredTimeOfDayX on PreferredTimeOfDay {
  String get label {
    switch (this) {
      case PreferredTimeOfDay.morning:
        return 'Morning';
      case PreferredTimeOfDay.afternoon:
        return 'Afternoon';
      case PreferredTimeOfDay.evening:
        return 'Evening';
      case PreferredTimeOfDay.night:
        return 'Night';
    }
  }

  /// Morning 05–11, Afternoon 12–16, Evening 17–20, Night 21–04.
  static PreferredTimeOfDay fromHour(int hour) {
    if (hour >= 5 && hour <= 11) return PreferredTimeOfDay.morning;
    if (hour >= 12 && hour <= 16) return PreferredTimeOfDay.afternoon;
    if (hour >= 17 && hour <= 20) return PreferredTimeOfDay.evening;
    return PreferredTimeOfDay.night;
  }
}

/// Ringkasan kebiasaan membaca user dalam periode yang dipilih.
class ReadingHabits extends Equatable {
  final Duration averageSession;
  final double averagePagesPerSession;
  final Duration averageDailyReadingTime;
  final PreferredTimeOfDay? preferredTime;
  final Duration longestSession;
  final DateTime? fastestDay;
  final double? fastestDayPagesPerHour;

  const ReadingHabits({
    required this.averageSession,
    required this.averagePagesPerSession,
    required this.averageDailyReadingTime,
    required this.preferredTime,
    required this.longestSession,
    required this.fastestDay,
    required this.fastestDayPagesPerHour,
  });

  static const empty = ReadingHabits(
    averageSession: Duration.zero,
    averagePagesPerSession: 0,
    averageDailyReadingTime: Duration.zero,
    preferredTime: null,
    longestSession: Duration.zero,
    fastestDay: null,
    fastestDayPagesPerHour: null,
  );

  @override
  List<Object?> get props => [
        averageSession,
        averagePagesPerSession,
        averageDailyReadingTime,
        preferredTime,
        longestSession,
        fastestDay,
        fastestDayPagesPerHour,
      ];
}