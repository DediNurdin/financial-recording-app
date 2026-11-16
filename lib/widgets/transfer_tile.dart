import 'package:flutter/material.dart';

import '../data/models/transfer_model.dart';
import '../theme.dart';
import '../utils/formatters.dart';

/// transfer row seen from the perspective of [walletId]
class TransferTile extends StatelessWidget {
  const TransferTile({
    super.key,
    required this.transfer,
    required this.walletId,
    this.onTap,
  });

  final TransferModel transfer;
  final int walletId;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final incoming = transfer.toWalletId == walletId;
    final color = incoming ? kIncomeColor : kExpenseColor;
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: scheme.secondaryContainer,
        child: Icon(Icons.swap_horiz, color: scheme.onSecondaryContainer),
      ),
      title: Text(
        incoming
            ? 'Transfer dari ${transfer.fromName ?? '-'}'
            : 'Transfer ke ${transfer.toName ?? '-'}',
      ),
      subtitle: Text(
        [
          formatDate(transfer.date),
          if (transfer.note.isNotEmpty) transfer.note,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '${incoming ? '+' : '-'} ${formatCurrency(transfer.amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
