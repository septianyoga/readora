import 'package:equatable/equatable.dart';

/// Satu potongan di donut/bar chart Reading Distribution.
class DistributionSlice extends Equatable {
  final String label;
  final int valueSeconds;

  /// Proporsi 0..1 terhadap total (dihitung di repository, bukan di UI,
  /// supaya UI cukup pakai angka jadi tanpa perlu tahu totalnya).
  final double fraction;

  const DistributionSlice({
    required this.label,
    required this.valueSeconds,
    required this.fraction,
  });

  @override
  List<Object?> get props => [label, valueSeconds, fraction];
}

class ReadingDistribution extends Equatable {
  final List<DistributionSlice> byBook;
  final List<DistributionSlice> byMonth;

  const ReadingDistribution({required this.byBook, required this.byMonth});

  static const empty = ReadingDistribution(byBook: [], byMonth: []);

  @override
  List<Object?> get props => [byBook, byMonth];
}