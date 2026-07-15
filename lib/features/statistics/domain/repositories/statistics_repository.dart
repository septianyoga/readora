import '../entities/reading_statistics.dart';

abstract class StatisticsRepository {
  Future<ReadingStatistics> getStatistics();
}