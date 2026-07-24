import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/reading_goal.dart';

class ReadingGoalNotifier extends AsyncNotifier<ReadingGoal?> {
  @override
  Future<ReadingGoal?> build() async {
    return ref.watch(readingGoalRepositoryProvider).getGoal();
  }

  Future<void> setGoal(ReadingGoal goal) async {
    state = AsyncData(goal);
    await ref.read(readingGoalRepositoryProvider).setGoal(goal);
  }

  Future<void> clearGoal() async {
    state = const AsyncData(null);
    await ref.read(readingGoalRepositoryProvider).clearGoal();
  }
}

final readingGoalProvider =
    AsyncNotifierProvider<ReadingGoalNotifier, ReadingGoal?>(
  ReadingGoalNotifier.new,
);