import '../entities/reading_goal.dart';

abstract class ReadingGoalRepository {
  /// Null berarti user belum menentukan target apa pun.
  Future<ReadingGoal?> getGoal();

  Future<void> setGoal(ReadingGoal goal);

  Future<void> clearGoal();
}