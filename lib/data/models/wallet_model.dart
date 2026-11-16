enum WalletType {
  cash('cash', 'Tunai'),
  bank('bank', 'Rekening Bank'),
  ewallet('ewallet', 'E-Wallet'),
  receivable('receivable', 'Piutang'),
  other('other', 'Lainnya');

  const WalletType(this.value, this.label);

  final String value;
  final String label;

  static WalletType fromValue(String value) => WalletType.values.firstWhere(
    (e) => e.value == value,
    orElse: () => WalletType.other,
  );
}

class WalletModel {
  const WalletModel({
    this.id,
    required this.name,
    required this.type,
    required this.color,
    this.initialBalance = 0,
    int? balance,
  }) : balance = balance ?? initialBalance;

  final int? id;
  final String name;
  final WalletType type;
  final int color;
  final int initialBalance;

  /// computed: initial + income - expense +/- transfers
  final int balance;

  Map<String, Object?> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'type': type.value,
    'initial_balance': initialBalance,
    'color': color,
  };

  factory WalletModel.fromMap(Map<String, Object?> map) => WalletModel(
    id: map['id'] as int,
    name: map['name'] as String,
    type: WalletType.fromValue(map['type'] as String),
    color: map['color'] as int,
    initialBalance: (map['initial_balance'] as num).toInt(),
    balance: (map['balance'] as num?)?.toInt(),
  );
}
