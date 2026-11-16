import 'package:flutter/material.dart';

import '../utils/formatters.dart';

class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.label = 'Jumlah',
    this.color,
    this.autofocus = false,
    this.allowZero = false,
    this.helperText,
  });

  final TextEditingController controller;
  final String label;
  final Color? color;
  final bool autofocus;
  final bool allowZero;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [ThousandsInputFormatter()],
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp ',
        helperText: helperText,
      ),
      validator: (v) =>
          !allowZero && parseAmount(v ?? '') <= 0 ? 'Masukkan jumlah' : null,
    );
  }
}

/// read-only field that opens a date picker
class DateField extends StatelessWidget {
  const DateField({super.key, required this.value, required this.onChanged});

  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Tanggal',
          prefixIcon: Icon(Icons.event),
        ),
        child: Text(formatDayHeader(value)),
      ),
    );
  }
}
