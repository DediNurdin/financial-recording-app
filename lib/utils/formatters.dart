import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);
final _number = NumberFormat.decimalPattern('id_ID');

String formatCurrency(num value) => _currency.format(value);
String formatNumber(num value) => _number.format(value);

String formatDate(DateTime d) => DateFormat('d MMM yyyy', 'id_ID').format(d);
String formatDayHeader(DateTime d) =>
    DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(d);
String formatMonthYear(DateTime d) =>
    DateFormat('MMMM yyyy', 'id_ID').format(d);
String formatShortMonth(DateTime d) => DateFormat('MMM', 'id_ID').format(d);

int parseAmount(String text) =>
    int.tryParse(text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

/// formats digits with thousand separators while typing
class ThousandsInputFormatter extends TextInputFormatter {
  static const maxDigits = 15;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return TextEditingValue.empty;
    if (digits.length > maxDigits) return oldValue;
    final text = _number.format(int.parse(digits));
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
