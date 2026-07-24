import 'package:equatable/equatable.dart';

/// Satu achievement. [iconKey] sengaja berupa string (bukan `IconData`
/// langsung) supaya entity domain ini tidak perlu depend ke Flutter
/// framework — pemetaan ke icon aslinya dilakukan di presentation layer.
class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final String iconKey;
  final bool unlocked;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.unlocked,
  });

  @override
  List<Object?> get props => [id, title, description, iconKey, unlocked];
}