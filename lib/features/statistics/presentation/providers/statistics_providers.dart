import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/reading_statistics.dart';

final statisticsProvider = FutureProvider<ReadingStatistics>((ref) async {
  final repository = ref.watch(statisticsRepositoryProvider);
  return repository.getStatistics();
});