import 'package:equatable/equatable.dart';

import '../../../reading_goal/domain/entities/reading_goal.dart';
import 'achievement.dart';
import 'book_activity.dart';
import 'day_activity.dart';
import 'reading_distribution.dart';
import 'reading_habits.dart';
import 'time_period.dart';
import 'trend_point.dart';

/// Bundel lengkap semua data yang dibutuhkan Statistics dashboard untuk
/// satu periode terpilih. Dihitung sekali oleh `StatisticsRepository`
/// supaya UI tidak perlu menggabungkan banyak provider terpisah.
class StatisticsDashboard extends Equatable {
  final TimePeriod period;

  /// Overview cards. `totalBooks` & `pagesRead` & `readTimeSeconds`
  /// mengikuti periode terpilih. `readingStreakDays` SENGAJA selalu
  /// menghitung streak berjalan (tidak ikut terpotong periode) — streak
  /// adalah konsep berkelanjutan, memfilternya ke "Today" misalnya akan
  /// selalu menghasilkan 0/1 yang tidak informatif.
  final int totalBooks;
  final int pagesRead;
  final int readTimeSeconds;
  final int readingStreakDays;

  final List<TrendPoint> trend;
  final ReadingGoalProgress? goalProgress;
  final List<BookActivity> topBooks;
  final List<DayActivity> calendarDays;
  final ReadingHabits habits;
  final ReadingDistribution distribution;

  /// Achievement SENGAJA selalu dihitung dari data sepanjang waktu
  /// (lifetime), bukan dari periode terpilih — achievement adalah
  /// pencapaian permanen, bukan sesuatu yang "dicabut" cuma karena
  /// sedang melihat filter "Today".
  final List<Achievement> achievements;

  const StatisticsDashboard({
    required this.period,
    required this.totalBooks,
    required this.pagesRead,
    required this.readTimeSeconds,
    required this.readingStreakDays,
    required this.trend,
    required this.goalProgress,
    required this.topBooks,
    required this.calendarDays,
    required this.habits,
    required this.distribution,
    required this.achievements,
  });

  static StatisticsDashboard empty(TimePeriod period) => StatisticsDashboard(
        period: period,
        totalBooks: 0,
        pagesRead: 0,
        readTimeSeconds: 0,
        readingStreakDays: 0,
        trend: const [],
        goalProgress: null,
        topBooks: const [],
        calendarDays: const [],
        habits: ReadingHabits.empty,
        distribution: ReadingDistribution.empty,
        achievements: const [],
      );

  @override
  List<Object?> get props => [
        period,
        totalBooks,
        pagesRead,
        readTimeSeconds,
        readingStreakDays,
        trend,
        goalProgress,
        topBooks,
        calendarDays,
        habits,
        distribution,
        achievements,
      ];
}