import 'tx_type.dart';

class TransactionModel {
  const TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.walletId,
    required this.date,
    this.note = '',
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.walletName,
  });

  final int? id;
  final TxType type;
  final int amount;
  final int categoryId;
  final int walletId;
  final DateTime date;
  final String note;

  // joined from categories / wallets
  final String? categoryName;
  final String? categoryIcon;
  final int? categoryColor;
  final String? walletName;

  bool get isIncome => type == TxType.income;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'type': type.value,
    'amount': amount,
    'category_id': categoryId,
    'wallet_id': walletId,
    'date': DateTime(date.year, date.month, date.day).millisecondsSinceEpoch,
    'note': note,
  };

  factory TransactionModel.fromMap(Map<String, Object?> map) =>
      TransactionModel(
        id: map['id'] as int,
        type: TxType.fromValue(map['type'] as String),
        amount: (map['amount'] as num).toInt(),
        categoryId: map['category_id'] as int,
        walletId: map['wallet_id'] as int,
        date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
        note: (map['note'] as String?) ?? '',
        categoryName: map['c_name'] as String?,
        categoryIcon: map['c_icon'] as String?,
        categoryColor: map['c_color'] as int?,
        walletName: map['w_name'] as String?,
      );
}
