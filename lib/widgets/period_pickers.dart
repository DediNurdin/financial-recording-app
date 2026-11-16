import 'package:flutter/material.dart';

import '../utils/formatters.dart';

Future<DateTime?> showMonthPicker(
  BuildContext context, {
  required DateTime initial,
}) => showDialog<DateTime>(
  context: context,
  builder: (_) => _MonthPickerDialog(initial: initial),
);

Future<DateTime?> showYearPicker(
  BuildContext context, {
  required DateTime initial,
}) => showDialog<DateTime>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: const Text('Pilih Tahun'),
    content: SizedBox(
      width: 300,
      height: 320,
      child: YearPicker(
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        selectedDate: initial,
        onChanged: (d) => Navigator.pop(ctx, DateTime(d.year)),
      ),
    ),
  ),
);

class _MonthPickerDialog extends StatefulWidget {
  const _MonthPickerDialog({required this.initial});

  final DateTime initial;

  @override
  State<_MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<_MonthPickerDialog> {
  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    Widget monthButton(int month) {
      final selected =
          widget.initial.year == _year && widget.initial.month == month;
      final label = Text(formatShortMonth(DateTime(2000, month)));
      void pick() => Navigator.pop(context, DateTime(_year, month));
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: selected
              ? FilledButton(onPressed: pick, child: label)
              : OutlinedButton(onPressed: pick, child: label),
        ),
      );
    }

    return AlertDialog(
      title: Row(
        children: [
          IconButton(
            onPressed: () => setState(() => _year--),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(child: Text('$_year', textAlign: TextAlign.center)),
          IconButton(
            onPressed: () => setState(() => _year++),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var row = 0; row < 4; row++)
            Row(
              children: [for (var i = 1; i <= 3; i++) monthButton(row * 3 + i)],
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}

/// "< label >" navigator used on home and report screens
class PeriodNavigator extends StatelessWidget {
  const PeriodNavigator({
    super.key,
    required this.label,
    required this.onTap,
    this.onPrev,
    this.onNext,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onPrev != null)
          IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: TextButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.calendar_month_outlined, size: 20),
            label: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        if (onNext != null)
          IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}
