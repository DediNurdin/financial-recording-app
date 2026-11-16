class TransferModel {
  const TransferModel({
    this.id,
    required this.fromWalletId,
    required this.toWalletId,
    required this.amount,
    required this.date,
    this.note = '',
    this.fromName,
    this.toName,
  });

  final int? id;
  final int fromWalletId;
  final int toWalletId;
  final int amount;
  final DateTime date;
  final String note;

  // joined from wallets
  final String? fromName;
  final String? toName;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'from_wallet_id': fromWalletId,
    'to_wallet_id': toWalletId,
    'amount': amount,
    'date': DateTime(date.year, date.month, date.day).millisecondsSinceEpoch,
    'note': note,
  };

  factory TransferModel.fromMap(Map<String, Object?> map) => TransferModel(
    id: map['id'] as int,
    fromWalletId: map['from_wallet_id'] as int,
    toWalletId: map['to_wallet_id'] as int,
    amount: (map['amount'] as num).toInt(),
    date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    note: (map['note'] as String?) ?? '',
    fromName: map['from_name'] as String?,
    toName: map['to_name'] as String?,
  );
}
