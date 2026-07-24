import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../reading_goal/presentation/providers/reading_goal_providers.dart';
import '../providers/statistics_providers.dart';
import '../widgets/achievements_section.dart';
import '../widgets/activity_calendar.dart';
import '../widgets/day_detail_sheet.dart';
import '../widgets/goal_setup_sheet.dart';
import '../widgets/overview_cards.dart';
import '../widgets/period_selector.dart';
import '../widgets/reading_distribution_section.dart';
import '../widgets/reading_goal_card.dart';
import '../widgets/reading_habits_section.dart';
import '../widgets/reading_trend_chart.dart';
import '../widgets/top_books_section.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(selectedPeriodProvider);
    final dashboardAsync = ref.watch(statisticsDashboardProvider(period));
    final goalAsync = ref.watch(readingGoalProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistics'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          PeriodSelector(
            selected: period,
            onChanged: (p) => ref.read(selectedPeriodProvider.notifier).state = p,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: dashboardAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Terjadi kesalahan: $error')),
              data: (dashboard) {
                return RefreshIndicator(
                  onRefresh: () async => invalidateAllStatistics(ref),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    children: [
                      OverviewCards(dashboard: dashboard),
                      const SizedBox(height: 16),
                      ReadingTrendChart(period: period, points: dashboard.trend),
                      const SizedBox(height: 16),
                      ReadingGoalCard(
                        progress: dashboard.goalProgress,
                        onTapSetGoal: () => showGoalSetupSheet(
                          context,
                          current: goalAsync.valueOrNull,
                          onSave: (goal) {
                            ref.read(readingGoalProvider.notifier).setGoal(goal);
                            invalidateAllStatistics(ref);
                          },
                          onClear: () {
                            ref.read(readingGoalProvider.notifier).clearGoal();
                            invalidateAllStatistics(ref);
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle('Top Books'),
                      const SizedBox(height: 12),
                      TopBooksSection(books: dashboard.topBooks),
                      const SizedBox(height: 16),
                      ActivityCalendar(
                        days: dashboard.calendarDays,
                        onSelectDay: (day) => showDayDetailSheet(context, day),
                      ),
                      const SizedBox(height: 16),
                      ReadingHabitsSection(habits: dashboard.habits),
                      const SizedBox(height: 16),
                      ReadingDistributionSection(distribution: dashboard.distribution),
                      const SizedBox(height: 16),
                      AchievementsSection(achievements: dashboard.achievements),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}