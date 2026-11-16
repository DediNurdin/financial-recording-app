enum TxType {
  income('income', 'Pemasukan'),
  expense('expense', 'Pengeluaran');

  const TxType(this.value, this.label);

  final String value;
  final String label;

  static TxType fromValue(String value) =>
      TxType.values.firstWhere((e) => e.value == value);
}
