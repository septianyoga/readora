import '../entities/statistics_dashboard.dart';
import '../entities/time_period.dart';

abstract class StatisticsRepository {
  /// Menghitung seluruh data dashboard (overview, trend, goal progress,
  /// top books, calendar, habits, distribution, achievements) untuk satu
  /// periode terpilih.
  Future<StatisticsDashboard> getDashboard(TimePeriod period);
}