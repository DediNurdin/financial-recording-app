import 'package:flutter/material.dart';

import '../data/models/transaction_model.dart';
import '../theme.dart';
import '../utils/formatters.dart';
import 'category_avatar.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.tx,
    this.onTap,
    this.showDate = false,
  });

  final TransactionModel tx;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final color = tx.isIncome ? kIncomeColor : kExpenseColor;
    final subtitle = [
      if (showDate) formatDate(tx.date),
      if (!showDate && tx.walletName != null) tx.walletName!,
      if (tx.note.isNotEmpty) tx.note,
    ].join(' · ');
    return ListTile(
      onTap: onTap,
      leading: CategoryAvatar(
        icon: tx.categoryIcon ?? 'other',
        color: tx.categoryColor ?? 0xFF757575,
      ),
      title: Text(tx.categoryName ?? '-'),
      subtitle: subtitle.isEmpty
          ? null
          : Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Text(
        '${tx.isIncome ? '+' : '-'} ${formatCurrency(tx.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
