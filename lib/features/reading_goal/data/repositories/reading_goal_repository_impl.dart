import '../../domain/entities/reading_goal.dart';
import '../../domain/repositories/reading_goal_repository.dart';
import '../datasources/reading_goal_local_datasource.dart';

class ReadingGoalRepositoryImpl implements ReadingGoalRepository {
  final ReadingGoalLocalDataSource _localDataSource;

  ReadingGoalRepositoryImpl({ReadingGoalLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? ReadingGoalLocalDataSource();

  ReadingGoalType _parseType(String value) {
    switch (value) {
      case 'hoursPerMonth':
        return ReadingGoalType.hoursPerMonth;
      case 'booksPerYear':
        return ReadingGoalType.booksPerYear;
      case 'pagesPerMonth':
      default:
        return ReadingGoalType.pagesPerMonth;
    }
  }

  @override
  Future<ReadingGoal?> getGoal() async {
    final row = await _localDataSource.getRow();
    if (row == null) return null;
    return ReadingGoal(
      type: _parseType(row['goal_type'] as String),
      target: (row['target_value'] as num).toDouble(),
    );
  }

  @override
  Future<void> setGoal(ReadingGoal goal) {
    return _localDataSource.save(
      goalType: goal.type.name,
      targetValue: goal.target,
    );
  }

  @override
  Future<void> clearGoal() {
    return _localDataSource.delete();
  }
}