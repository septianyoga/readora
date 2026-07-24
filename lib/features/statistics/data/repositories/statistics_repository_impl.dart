import 'package:intl/intl.dart';

import '../../../books/data/datasources/book_local_datasource.dart';
import '../../../books/data/models/book_model.dart';
import '../../../reader/data/datasources/reading_progress_local_datasource.dart';
import '../../../reader/data/datasources/reading_session_local_datasource.dart';
import '../../../reading_goal/domain/entities/reading_goal.dart';
import '../../../reading_goal/domain/repositories/reading_goal_repository.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/book_activity.dart';
import '../../domain/entities/day_activity.dart';
import '../../domain/entities/reading_distribution.dart';
import '../../domain/entities/reading_habits.dart';
import '../../domain/entities/statistics_dashboard.dart';
import '../../domain/entities/time_period.dart';
import '../../domain/entities/trend_point.dart';
import '../../domain/repositories/statistics_repository.dart';

/// Satu baris sesi baca yang sudah "ditipekan" (bukan Map mentah lagi),
/// dipakai internal di seluruh perhitungan repository ini.
class _Session {
  final String bookId;
  final DateTime startedAt;
  final int durationSeconds;
  final int pagesRead;

  _Session({
    required this.bookId,
    required this.startedAt,
    required this.durationSeconds,
    required this.pagesRead,
  });

  factory _Session.fromRow(Map<String, dynamic> row) {
    return _Session(
      bookId: row['book_id'] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch(row['started_at'] as int),
      durationSeconds: row['duration_seconds'] as int? ?? 0,
      pagesRead: row['pages_read'] as int? ?? 0,
    );
  }
}

class StatisticsRepositoryImpl implements StatisticsRepository {
  final BookLocalDataSource _bookDataSource;
  final ReadingProgressLocalDataSource _progressDataSource;
  final ReadingSessionLocalDataSource _sessionDataSource;
  final ReadingGoalRepository _goalRepository;

  StatisticsRepositoryImpl({
    BookLocalDataSource? bookDataSource,
    ReadingProgressLocalDataSource? progressDataSource,
    ReadingSessionLocalDataSource? sessionDataSource,
    required ReadingGoalRepository goalRepository,
  })  : _bookDataSource = bookDataSource ?? BookLocalDataSource(),
        _progressDataSource = progressDataSource ?? ReadingProgressLocalDataSource(),
        _sessionDataSource = sessionDataSource ?? ReadingSessionLocalDataSource(),
        _goalRepository = goalRepository;

  @override
  Future<StatisticsDashboard> getDashboard(TimePeriod period) async {
    final now = DateTime.now();
    final range = period.rangeFrom(now);

    final books = await _bookDataSource.getAllBooks();
    final progressRows = await _progressDataSource.getAllRows();
    final progressByBookId = {
      for (final row in progressRows) row['book_id'] as String: row,
    };

    final periodSessionRows = await _sessionDataSource.getSessionsBetween(
      from: range.startMillis,
      to: range.endMillis,
    );
    final periodSessions = periodSessionRows.map(_Session.fromRow).toList();

    final allSessionRows = await _sessionDataSource.getAllSessions();
    final allSessions = allSessionRows.map(_Session.fromRow).toList();

    // Calendar: pakai rentang periode yang sama, KECUALI "All Time" yang
    // dibatasi 371 hari terakhir (gaya GitHub) supaya grid heatmap tetap
    // masuk akal ukurannya alih-alih tumbuh tak terbatas.
    final today = DateTime(now.year, now.month, now.day);
    final calendarStart = period == TimePeriod.allTime
        ? today.subtract(const Duration(days: 370))
        : range.start;
    final calendarEnd = period == TimePeriod.allTime
        ? today.add(const Duration(days: 1))
        : range.end;
    final calendarSessions = period == TimePeriod.allTime
        ? allSessions.where((s) => !s.startedAt.isBefore(calendarStart)).toList()
        : periodSessions;

    final pagesRead = periodSessions.fold<int>(0, (sum, s) => sum + s.pagesRead);
    final readTimeSeconds =
        periodSessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    final totalBooks = period == TimePeriod.allTime
        ? books.length
        : periodSessions.map((s) => s.bookId).toSet().length;

    final goal = await _goalRepository.getGoal();

    return StatisticsDashboard(
      period: period,
      totalBooks: totalBooks,
      pagesRead: pagesRead,
      readTimeSeconds: readTimeSeconds,
      readingStreakDays: _computeStreak(allSessions, now),
      trend: _buildTrend(period, now, range, periodSessions),
      goalProgress: goal == null
          ? null
          : _buildGoalProgress(goal, now, allSessions, progressByBookId),
      topBooks: _buildTopBooks(periodSessions, books, progressByBookId),
      calendarDays: _buildCalendarDays(calendarStart, calendarEnd, calendarSessions),
      habits: _buildHabits(periodSessions),
      distribution: _buildDistribution(periodSessions, books),
      achievements: _buildAchievements(allSessions, progressByBookId, now),
    );
  }

  // ---------------------------------------------------------------------
  // Reading streak — jumlah hari berturut-turut (mundur dari hari ini) ada
  // aktivitas baca. Kalau hari ini belum sempat baca tapi kemarin masih
  // ada, streak dianggap belum putus supaya tidak balik ke 0 di pagi hari.
  // ---------------------------------------------------------------------
  int _computeStreak(List<_Session> sessions, DateTime now) {
    final activeDates = <DateTime>{};
    for (final s in sessions) {
      activeDates.add(DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day));
    }
    if (activeDates.isEmpty) return 0;

    var cursor = DateTime(now.year, now.month, now.day);
    if (!activeDates.contains(cursor)) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!activeDates.contains(cursor)) return 0;
    }

    var streak = 0;
    while (activeDates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  // ---------------------------------------------------------------------
  // Reading Trend chart — granularitas berbeda tergantung periode:
  // Today -> blok 4 jam, Week -> harian, Month -> mingguan,
  // Year -> bulanan, All Time -> bulanan (12 bulan terakhir).
  // ---------------------------------------------------------------------
  List<TrendPoint> _buildTrend(
    TimePeriod period,
    DateTime now,
    PeriodRange range,
    List<_Session> sessions,
  ) {
    switch (period) {
      case TimePeriod.today:
        return _bucketByHourBlocks(sessions);
      case TimePeriod.week:
        return _bucketByDay(sessions, range.start, 7);
      case TimePeriod.month:
        return _bucketByWeekOfMonth(sessions, range.start, range.end);
      case TimePeriod.year:
        return _bucketByMonth(sessions, now.year);
      case TimePeriod.allTime:
        return _bucketByRollingMonths(sessions, now, 12);
    }
  }

  List<TrendPoint> _bucketByHourBlocks(List<_Session> sessions) {
    const blockHours = 4;
    const blockCount = 24 ~/ blockHours;
    final pages = List.filled(blockCount, 0);
    final seconds = List.filled(blockCount, 0);

    for (final s in sessions) {
      final block = (s.startedAt.hour ~/ blockHours).clamp(0, blockCount - 1);
      pages[block] += s.pagesRead;
      seconds[block] += s.durationSeconds;
    }

    return List.generate(blockCount, (i) {
      final hour = i * blockHours;
      final label = DateFormat('ha').format(DateTime(2000, 1, 1, hour)).toLowerCase();
      return TrendPoint(label: label, pagesRead: pages[i], readTimeSeconds: seconds[i]);
    });
  }

  List<TrendPoint> _bucketByDay(List<_Session> sessions, DateTime start, int days) {
    final pages = List.filled(days, 0);
    final seconds = List.filled(days, 0);

    for (final s in sessions) {
      final day = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      final index = day.difference(start).inDays;
      if (index < 0 || index >= days) continue;
      pages[index] += s.pagesRead;
      seconds[index] += s.durationSeconds;
    }

    return List.generate(days, (i) {
      final date = start.add(Duration(days: i));
      return TrendPoint(
        label: DateFormat.E().format(date),
        pagesRead: pages[i],
        readTimeSeconds: seconds[i],
      );
    });
  }

  List<TrendPoint> _bucketByWeekOfMonth(
    List<_Session> sessions,
    DateTime monthStart,
    DateTime monthEnd,
  ) {
    final weekCount = (monthEnd.difference(monthStart).inDays / 7).ceil();
    final pages = List.filled(weekCount, 0);
    final seconds = List.filled(weekCount, 0);

    for (final s in sessions) {
      final dayIndex = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day)
          .difference(monthStart)
          .inDays;
      if (dayIndex < 0) continue;
      final week = (dayIndex ~/ 7).clamp(0, weekCount - 1);
      pages[week] += s.pagesRead;
      seconds[week] += s.durationSeconds;
    }

    return List.generate(
      weekCount,
      (i) => TrendPoint(label: 'W${i + 1}', pagesRead: pages[i], readTimeSeconds: seconds[i]),
    );
  }

  List<TrendPoint> _bucketByMonth(List<_Session> sessions, int year) {
    final pages = List.filled(12, 0);
    final seconds = List.filled(12, 0);

    for (final s in sessions) {
      if (s.startedAt.year != year) continue;
      final month = s.startedAt.month - 1;
      pages[month] += s.pagesRead;
      seconds[month] += s.durationSeconds;
    }

    return List.generate(12, (i) {
      final label = DateFormat.MMM().format(DateTime(year, i + 1, 1));
      return TrendPoint(label: label, pagesRead: pages[i], readTimeSeconds: seconds[i]);
    });
  }

  List<TrendPoint> _bucketByRollingMonths(
    List<_Session> sessions,
    DateTime now,
    int monthCount,
  ) {
    // Bulan-bulan dari yang paling lama ke yang terbaru, berakhir di
    // bulan berjalan.
    final months = List.generate(monthCount, (i) {
      final offset = monthCount - 1 - i;
      return DateTime(now.year, now.month - offset, 1);
    });

    final pages = List.filled(monthCount, 0);
    final seconds = List.filled(monthCount, 0);

    for (final s in sessions) {
      final key = DateTime(s.startedAt.year, s.startedAt.month, 1);
      final index = months.indexWhere((m) => m.year == key.year && m.month == key.month);
      if (index == -1) continue;
      pages[index] += s.pagesRead;
      seconds[index] += s.durationSeconds;
    }

    return List.generate(monthCount, (i) {
      final label = DateFormat('MMM yy').format(months[i]);
      return TrendPoint(label: label, pagesRead: pages[i], readTimeSeconds: seconds[i]);
    });
  }

  // ---------------------------------------------------------------------
  // Reading Goal progress
  // ---------------------------------------------------------------------
  ReadingGoalProgress _buildGoalProgress(
    ReadingGoal goal,
    DateTime now,
    List<_Session> allSessions,
    Map<String, Map<String, dynamic>> progressByBookId,
  ) {
    switch (goal.type) {
      case ReadingGoalType.pagesPerMonth:
        final monthPages = allSessions
            .where((s) => s.startedAt.year == now.year && s.startedAt.month == now.month)
            .fold<int>(0, (sum, s) => sum + s.pagesRead);
        return ReadingGoalProgress(goal: goal, current: monthPages.toDouble());
      case ReadingGoalType.hoursPerMonth:
        final monthSeconds = allSessions
            .where((s) => s.startedAt.year == now.year && s.startedAt.month == now.month)
            .fold<int>(0, (sum, s) => sum + s.durationSeconds);
        return ReadingGoalProgress(goal: goal, current: monthSeconds / 3600);
      case ReadingGoalType.booksPerYear:
        final completedThisYear = progressByBookId.values.where((row) {
          final percentage = (row['percentage'] as num?)?.toDouble() ?? 0;
          final lastOpenedMillis = row['last_opened_at'] as int?;
          if (percentage < 100 || lastOpenedMillis == null) return false;
          final lastOpened = DateTime.fromMillisecondsSinceEpoch(lastOpenedMillis);
          return lastOpened.year == now.year;
        }).length;
        return ReadingGoalProgress(goal: goal, current: completedThisYear.toDouble());
    }
  }

  // ---------------------------------------------------------------------
  // Top Books — 3 buku dengan aktivitas (waktu baca) tertinggi di periode.
  // ---------------------------------------------------------------------
  List<BookActivity> _buildTopBooks(
    List<_Session> periodSessions,
    List<BookModel> books,
    Map<String, Map<String, dynamic>> progressByBookId,
  ) {
    final secondsByBook = <String, int>{};
    final pagesByBook = <String, int>{};
    for (final s in periodSessions) {
      secondsByBook[s.bookId] = (secondsByBook[s.bookId] ?? 0) + s.durationSeconds;
      pagesByBook[s.bookId] = (pagesByBook[s.bookId] ?? 0) + s.pagesRead;
    }

    final ranked = secondsByBook.keys.toList()
      ..sort((a, b) => secondsByBook[b]!.compareTo(secondsByBook[a]!));

    final booksById = {for (final b in books) b.id: b};

    final result = <BookActivity>[];
    for (final bookId in ranked.take(3)) {
      final book = booksById[bookId];
      if (book == null) continue;
      final percentage =
          (progressByBookId[bookId]?['percentage'] as num?)?.toDouble() ?? 0;
      result.add(BookActivity(
        bookId: bookId,
        title: book.title,
        coverPath: book.coverPath,
        readTimeSeconds: secondsByBook[bookId] ?? 0,
        pagesRead: pagesByBook[bookId] ?? 0,
        completionPercentage: percentage,
      ));
    }
    return result;
  }

  // ---------------------------------------------------------------------
  // Reading Activity Calendar (heatmap)
  // ---------------------------------------------------------------------
  List<DayActivity> _buildCalendarDays(
    DateTime start,
    DateTime end,
    List<_Session> sessions,
  ) {
    final dayCount = end.difference(start).inDays;
    final seconds = List.filled(dayCount, 0);
    final pages = List.filled(dayCount, 0);
    final counts = List.filled(dayCount, 0);

    for (final s in sessions) {
      final day = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      final index = day.difference(start).inDays;
      if (index < 0 || index >= dayCount) continue;
      seconds[index] += s.durationSeconds;
      pages[index] += s.pagesRead;
      counts[index] += 1;
    }

    return List.generate(dayCount, (i) {
      return DayActivity(
        date: start.add(Duration(days: i)),
        readTimeSeconds: seconds[i],
        pagesRead: pages[i],
        sessionCount: counts[i],
      );
    });
  }

  // ---------------------------------------------------------------------
  // Reading Habits
  // ---------------------------------------------------------------------
  ReadingHabits _buildHabits(List<_Session> sessions) {
    if (sessions.isEmpty) return ReadingHabits.empty;

    final totalSeconds = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    final totalPages = sessions.fold<int>(0, (sum, s) => sum + s.pagesRead);
    final longest =
        sessions.fold<int>(0, (m, s) => s.durationSeconds > m ? s.durationSeconds : m);

    final activeDays = sessions
        .map((s) => DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day))
        .toSet();

    // Preferred time of day: bucket total durasi per waktu, ambil terbesar.
    final durationByBucket = <PreferredTimeOfDay, int>{};
    for (final s in sessions) {
      final bucket = PreferredTimeOfDayX.fromHour(s.startedAt.hour);
      durationByBucket[bucket] = (durationByBucket[bucket] ?? 0) + s.durationSeconds;
    }
    PreferredTimeOfDay? preferred;
    var maxBucketSeconds = 0;
    durationByBucket.forEach((bucket, secs) {
      if (secs > maxBucketSeconds) {
        maxBucketSeconds = secs;
        preferred = bucket;
      }
    });

    // Fastest reading day: hari dengan kecepatan baca (halaman/jam)
    // tertinggi, di antara hari dengan minimal 1 menit waktu baca supaya
    // tidak bias oleh sesi super pendek.
    final secondsPerDay = <DateTime, int>{};
    final pagesPerDay = <DateTime, int>{};
    for (final s in sessions) {
      final day = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
      secondsPerDay[day] = (secondsPerDay[day] ?? 0) + s.durationSeconds;
      pagesPerDay[day] = (pagesPerDay[day] ?? 0) + s.pagesRead;
    }
    DateTime? fastestDay;
    double? fastestRate;
    secondsPerDay.forEach((day, secs) {
      if (secs < 60) return;
      final rate = (pagesPerDay[day] ?? 0) / (secs / 3600);
      if (fastestRate == null || rate > fastestRate!) {
        fastestRate = rate;
        fastestDay = day;
      }
    });

    return ReadingHabits(
      averageSession: Duration(seconds: totalSeconds ~/ sessions.length),
      averagePagesPerSession: totalPages / sessions.length,
      averageDailyReadingTime:
          Duration(seconds: totalSeconds ~/ (activeDays.isEmpty ? 1 : activeDays.length)),
      preferredTime: preferred,
      longestSession: Duration(seconds: longest),
      fastestDay: fastestDay,
      fastestDayPagesPerHour: fastestRate,
    );
  }

  // ---------------------------------------------------------------------
  // Reading Distribution
  // ---------------------------------------------------------------------
  ReadingDistribution _buildDistribution(List<_Session> sessions, List<BookModel> books) {
    if (sessions.isEmpty) return ReadingDistribution.empty;

    final booksById = {for (final b in books) b.id: b};

    final secondsByBook = <String, int>{};
    for (final s in sessions) {
      secondsByBook[s.bookId] = (secondsByBook[s.bookId] ?? 0) + s.durationSeconds;
    }
    final totalSeconds = secondsByBook.values.fold<int>(0, (a, b) => a + b);

    final byBookRanked = secondsByBook.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final byBook = <DistributionSlice>[];
    var othersSeconds = 0;
    for (var i = 0; i < byBookRanked.length; i++) {
      final entry = byBookRanked[i];
      if (i < 5) {
        final title = booksById[entry.key]?.title ?? 'Unknown';
        byBook.add(DistributionSlice(
          label: title,
          valueSeconds: entry.value,
          fraction: totalSeconds > 0 ? entry.value / totalSeconds : 0,
        ));
      } else {
        othersSeconds += entry.value;
      }
    }
    if (othersSeconds > 0) {
      byBook.add(DistributionSlice(
        label: 'Others',
        valueSeconds: othersSeconds,
        fraction: totalSeconds > 0 ? othersSeconds / totalSeconds : 0,
      ));
    }

    final secondsByMonth = <String, int>{};
    for (final s in sessions) {
      final key = DateFormat('MMM yy').format(s.startedAt);
      secondsByMonth[key] = (secondsByMonth[key] ?? 0) + s.durationSeconds;
    }
    final byMonth = secondsByMonth.entries
        .map((e) => DistributionSlice(
              label: e.key,
              valueSeconds: e.value,
              fraction: totalSeconds > 0 ? e.value / totalSeconds : 0,
            ))
        .toList();

    return ReadingDistribution(byBook: byBook, byMonth: byMonth);
  }

  // ---------------------------------------------------------------------
  // Achievements — SELALU dihitung dari data lifetime (allSessions),
  // tidak terpengaruh filter periode.
  //
  // Catatan jujur: "7-Day Streak" & "30-Day Streak" di sini memeriksa
  // STREAK YANG SEDANG BERJALAN saat ini, bukan rekor terpanjang
  // sepanjang waktu — aplikasi ini belum menyimpan angka "best streak
  // ever" secara terpisah. Kalau streak lama sempat 10 hari lalu putus,
  // achievement itu akan "terkunci lagi" sampai user mencapainya lagi.
  // ---------------------------------------------------------------------
  List<Achievement> _buildAchievements(
    List<_Session> allSessions,
    Map<String, Map<String, dynamic>> progressByBookId,
    DateTime now,
  ) {
    final totalPages = allSessions.fold<int>(0, (sum, s) => sum + s.pagesRead);
    final completedBooks = progressByBookId.values
        .where((row) => ((row['percentage'] as num?)?.toDouble() ?? 0) >= 100)
        .length;
    final currentStreak = _computeStreak(allSessions, now);
    final weekendSessions =
        allSessions.where((s) => s.startedAt.weekday >= DateTime.saturday).length;
    final nightSessions = allSessions
        .where((s) => PreferredTimeOfDayX.fromHour(s.startedAt.hour) == PreferredTimeOfDay.night)
        .length;
    final earlyBirdSessions = allSessions.where((s) => s.startedAt.hour < 7).length;
    final hasAnyProgress =
        progressByBookId.values.any((row) => ((row['current_page'] as int?) ?? 0) > 0);

    Achievement build(String id, String title, String desc, String icon, bool unlocked) =>
        Achievement(id: id, title: title, description: desc, iconKey: icon, unlocked: unlocked);

    return [
      build('first_book', 'First Book', 'Buka halaman pertama buku pertamamu',
          'menu_book', hasAnyProgress),
      build('streak_7', '7-Day Streak', 'Baca 7 hari berturut-turut', 'local_fire_department',
          currentStreak >= 7),
      build('streak_30', '30-Day Streak', 'Baca 30 hari berturut-turut', 'whatshot',
          currentStreak >= 30),
      build('pages_1000', '1000 Pages Read', 'Baca 1000 halaman total', 'auto_stories',
          totalPages >= 1000),
      build('books_10', '10 Books Completed', 'Selesaikan 10 buku', 'library_books',
          completedBooks >= 10),
      build('weekend_reader', 'Weekend Reader', 'Baca di akhir pekan minimal 3 kali',
          'weekend', weekendSessions >= 3),
      build('night_owl', 'Night Owl', 'Baca larut malam (21.00–04.00) minimal 3 kali',
          'nightlight_round', nightSessions >= 3),
      build('early_bird', 'Early Bird', 'Baca pagi-pagi sekali (sebelum jam 7) minimal 3 kali',
          'wb_twilight', earlyBirdSessions >= 3),
    ];
  }
}