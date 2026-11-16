import 'package:flutter/material.dart';

import '../data/models/wallet_model.dart';

IconData walletIcon(WalletType type) => switch (type) {
  WalletType.cash => Icons.payments_outlined,
  WalletType.bank => Icons.account_balance,
  WalletType.ewallet => Icons.account_balance_wallet_outlined,
  WalletType.receivable => Icons.handshake_outlined,
  WalletType.other => Icons.wallet,
};

class WalletAvatar extends StatelessWidget {
  const WalletAvatar({super.key, required this.wallet, this.radius = 20});

  final WalletModel wallet;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = Color(wallet.color);
    return CircleAvatar(
      radius: radius,
      backgroundColor: c.withValues(alpha: 0.15),
      child: Icon(walletIcon(wallet.type), color: c, size: radius),
    );
  }
}
