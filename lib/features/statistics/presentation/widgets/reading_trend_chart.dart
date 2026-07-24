import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/time_period.dart';
import '../../domain/entities/trend_point.dart';

/// Toggle metrik yang ditampilkan chart: menit baca atau halaman.
enum TrendMetric { readTime, pagesRead }

class ReadingTrendChart extends StatefulWidget {
  final TimePeriod period;
  final List<TrendPoint> points;

  const ReadingTrendChart({
    super.key,
    required this.period,
    required this.points,
  });

  @override
  State<ReadingTrendChart> createState() => _ReadingTrendChartState();
}

class _ReadingTrendChartState extends State<ReadingTrendChart> {
  TrendMetric _metric = TrendMetric.readTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActivity = widget.points.any(
      (p) => p.readTimeSeconds > 0 || p.pagesRead > 0,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Reading Trend',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _MetricToggle(
                selected: _metric,
                onChanged: (m) => setState(() => _metric = m),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: hasActivity
                ? _AnimatedLineChart(
                    key: ValueKey('${widget.period}-$_metric'),
                    points: widget.points,
                    metric: _metric,
                  )
                : Center(
                    child: Text(
                      'Belum ada aktivitas baca di periode ini',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MetricToggle extends StatelessWidget {
  final TrendMetric selected;
  final ValueChanged<TrendMetric> onChanged;

  const _MetricToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SegmentedButton<TrendMetric>(
      segments: const [
        ButtonSegment(value: TrendMetric.readTime, label: Text('Time')),
        ButtonSegment(value: TrendMetric.pagesRead, label: Text('Pages')),
      ],
      selected: {selected},
      showSelectedIcon: false,
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(theme.textTheme.labelSmall),
      ),
    );
  }
}

class _AnimatedLineChart extends StatelessWidget {
  final List<TrendPoint> points;
  final TrendMetric metric;

  const _AnimatedLineChart({super.key, required this.points, required this.metric});

  double _valueOf(TrendPoint p) {
    return metric == TrendMetric.readTime
        ? (p.readTimeSeconds / 60) // menit
        : p.pagesRead.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values = points.map(_valueOf).toList();
    final maxY = values.fold<double>(0, (m, v) => v > m ? v : m);
    final safeMaxY = maxY <= 0 ? 1.0 : maxY * 1.25;

    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), values[i]),
    ];

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final animatedSpots = [
          for (final s in spots) FlSpot(s.x, s.y * t),
        ];
        return LineChart(
          LineChartData(
            minY: 0,
            maxY: safeMaxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: safeMaxY / 3,
              getDrawingHorizontalLine: (_) => FlLine(
                color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: (points.length / 6).clamp(1, points.length).toDouble(),
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (index < 0 || index >= points.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        points[index].label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => theme.colorScheme.inverseSurface,
                getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
                  final point = points[s.x.round()];
                  final text = metric == TrendMetric.readTime
                      ? '${point.readTimeSeconds ~/ 60}m'
                      : '${point.pagesRead}p';
                  return LineTooltipItem(
                    '${point.label}\n$text',
                    TextStyle(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: animatedSpots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: theme.colorScheme.primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: points.length <= 12,
                  getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                    radius: 3,
                    color: theme.colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: theme.colorScheme.surfaceContainerLow,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.22),
                      theme.colorScheme.primary.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
          duration: Duration.zero,
        );
      },
    );
  }
}