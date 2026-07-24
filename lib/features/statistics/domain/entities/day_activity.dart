import 'package:equatable/equatable.dart';

/// Aktivitas baca dalam satu hari — satu kotak di Reading Activity
/// Calendar (heatmap ala GitHub contribution graph).
class DayActivity extends Equatable {
  final DateTime date;
  final int readTimeSeconds;
  final int pagesRead;
  final int sessionCount;

  const DayActivity({
    required this.date,
    required this.readTimeSeconds,
    required this.pagesRead,
    required this.sessionCount,
  });

  bool get hasActivity => sessionCount > 0;

  @override
  List<Object?> get props => [date, readTimeSeconds, pagesRead, sessionCount];
}