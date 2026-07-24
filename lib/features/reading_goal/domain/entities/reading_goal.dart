import 'package:equatable/equatable.dart';

enum ReadingGoalType { pagesPerMonth, hoursPerMonth, booksPerYear }

extension ReadingGoalTypeX on ReadingGoalType {
  String get label {
    switch (this) {
      case ReadingGoalType.pagesPerMonth:
        return 'Pages per month';
      case ReadingGoalType.hoursPerMonth:
        return 'Reading hours per month';
      case ReadingGoalType.booksPerYear:
        return 'Books per year';
    }
  }

  String get unit {
    switch (this) {
      case ReadingGoalType.pagesPerMonth:
        return 'pages';
      case ReadingGoalType.hoursPerMonth:
        return 'hours';
      case ReadingGoalType.booksPerYear:
        return 'books';
    }
  }
}

/// Target baca yang user tentukan sendiri di Reading Goal card.
class ReadingGoal extends Equatable {
  final ReadingGoalType type;
  final double target;

  const ReadingGoal({required this.type, required this.target});

  @override
  List<Object?> get props => [type, target];
}

/// [ReadingGoal] + progress user saat ini terhadap target itu, dihitung
/// dari data periode yang relevan (bulan berjalan untuk goal per-bulan,
/// tahun berjalan untuk goal per-tahun).
class ReadingGoalProgress extends Equatable {
  final ReadingGoal goal;
  final double current;

  const ReadingGoalProgress({required this.goal, required this.current});

  double get fraction =>
      goal.target > 0 ? (current / goal.target).clamp(0, 1) : 0;

  double get percentage => fraction * 100;

  bool get isCompleted => current >= goal.target && goal.target > 0;

  @override
  List<Object?> get props => [goal, current];
}