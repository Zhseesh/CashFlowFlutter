import 'package:flutter/material.dart';

import '../../utils/format.dart';

/// Dialog pemilih bulan dan tahun.
Future<DateTime?> showMonthYearPicker(BuildContext context, DateTime initial) {
  return showDialog<DateTime>(
    context: context,
    builder: (_) => _MonthYearDialog(initial: initial),
  );
}

class _MonthYearDialog extends StatefulWidget {
  const _MonthYearDialog({required this.initial});
  final DateTime initial;

  @override
  State<_MonthYearDialog> createState() => _MonthYearDialogState();
}

class _MonthYearDialogState extends State<_MonthYearDialog> {
  late int _year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: _year > 2000 ? () => setState(() => _year--) : null,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Text('$_year'),
          IconButton(
            onPressed: _year < 2100 ? () => setState(() => _year++) : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
      content: SizedBox(
        width: 300,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(12, (i) {
            final selected =
                _year == widget.initial.year && i + 1 == widget.initial.month;
            return ChoiceChip(
              label: Text(Fmt.monthShort(DateTime(2000, i + 1))),
              selected: selected,
              onSelected: (_) =>
                  Navigator.of(context).pop(DateTime(_year, i + 1)),
            );
          }),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
      ],
    );
  }
}
