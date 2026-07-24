import 'package:equatable/equatable.dart';

/// Satu titik data di Reading Trend chart (misal: satu hari, satu minggu,
/// atau satu bulan tergantung granularitas periode yang dipilih).
class TrendPoint extends Equatable {
  final String label;
  final int pagesRead;
  final int readTimeSeconds;

  const TrendPoint({
    required this.label,
    required this.pagesRead,
    required this.readTimeSeconds,
  });

  @override
  List<Object?> get props => [label, pagesRead, readTimeSeconds];
}