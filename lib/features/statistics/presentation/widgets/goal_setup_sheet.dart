import 'package:flutter/material.dart';

import '../../../reading_goal/domain/entities/reading_goal.dart';

Future<void> showGoalSetupSheet(
  BuildContext context, {
  required ReadingGoal? current,
  required ValueChanged<ReadingGoal> onSave,
  required VoidCallback onClear,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _GoalSetupSheet(
      current: current,
      onSave: onSave,
      onClear: onClear,
    ),
  );
}

class _GoalSetupSheet extends StatefulWidget {
  final ReadingGoal? current;
  final ValueChanged<ReadingGoal> onSave;
  final VoidCallback onClear;

  const _GoalSetupSheet({
    required this.current,
    required this.onSave,
    required this.onClear,
  });

  @override
  State<_GoalSetupSheet> createState() => _GoalSetupSheetState();
}

class _GoalSetupSheetState extends State<_GoalSetupSheet> {
  late ReadingGoalType _type = widget.current?.type ?? ReadingGoalType.pagesPerMonth;
  late final _controller = TextEditingController(
    text: widget.current?.target.toStringAsFixed(0) ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reading Goal',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Text('Tipe target', style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReadingGoalType.values.map((type) {
              return ChoiceChip(
                label: Text(type.label),
                selected: _type == type,
                onSelected: (_) => setState(() => _type = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Target (${_type.unit})',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              if (widget.current != null)
                TextButton(
                  onPressed: () {
                    widget.onClear();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Hapus target'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  final target = double.tryParse(_controller.text);
                  if (target == null || target <= 0) return;
                  widget.onSave(ReadingGoal(type: _type, target: target));
                  Navigator.of(context).pop();
                },
                child: const Text('Simpan'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}