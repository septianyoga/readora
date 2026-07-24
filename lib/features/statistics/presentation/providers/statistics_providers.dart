import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/statistics_dashboard.dart';
import '../../domain/entities/time_period.dart';

/// Periode aktif yang dipilih lewat segmented filter di Statistics.
final selectedPeriodProvider = StateProvider<TimePeriod>((ref) => TimePeriod.week);

/// Dashboard lengkap untuk periode yang aktif. Diketik sebagai family
/// supaya Riverpod otomatis meng-cache hasil per periode — pindah-pindah
/// tab periode yang sudah pernah dibuka tidak perlu query ulang.
final statisticsDashboardProvider =
    FutureProvider.family<StatisticsDashboard, TimePeriod>((ref, period) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.getDashboard(period);
});

/// Shortcut untuk dashboard periode yang SEDANG aktif (dipakai layar utama).
final activeDashboardProvider = FutureProvider<StatisticsDashboard>((ref) async {
  final period = ref.watch(selectedPeriodProvider);
  return ref.watch(statisticsDashboardProvider(period).future);
});

/// Invalidate semua cache dashboard (dipanggil dari tombol refresh atau
/// setelah data reading berubah).
void invalidateAllStatistics(WidgetRef ref) {
  for (final period in TimePeriod.values) {
    ref.invalidate(statisticsDashboardProvider(period));
  }
}